%% Experiment: RippleVsMuxAp
% Updated script for comparing action potentials between instruments

close all 
clearvars 

% Sets relative filepaths from this script
currentFile = mfilename( 'fullpath' );
cd(fileparts(currentFile));
addpath(genpath('../matlab'));
addpath(genpath('../rawData'));
addpath(genpath('../output'));
parts = strsplit(currentFile, {'\', '\'});
outputDir = ['../output/' parts{end}];
[~, ~] = mkdir(outputDir);

%% 
% Good looking mux channels
% 2019_7_22_13_49_31_4_2097152_5_2_1_6_smpls_raw
% 2019_7_22_13_41_33_8_2097152_3_4_5_2_1_6_0_7_smpls_raw
% 2019_7_22_13_33_39_10_2097152_3_4_5_2_1_6_0_7_15_8_smpls_raw
% 2019_7_22_13_29_25_16_2097152_3_4_5_2_1_6_0_7_15_8_9_14_13_10_11_12_smpls_raw
% 
%%%

muxFileName    = '2019_7_30_10_50_46_10_2097152_3_4_5_2_1_6_0_7_15_8_smpls_raw.mat';
rippleFileName = 'SD190719A_Ketamine_Day03_20190722_1251.ns5';
hpCornerFreq   =  750;
lpCornerFreq   = 4000;

% Ripple Data. Ripple uses .25 uV per bit. Data comes in as bits. Here
% we're leaving units as uV [mini function candidate]
[ NSxFileArray, NSxbasicHeader, NSxchannelHeader, NSxTimeStamps ] = ...
    NSxGetMemMapFile( rippleFileName );
rawdata = NSxFileArray.Data.NSxData;
V = double( rawdata );
timeRipple = double( NSxTimeStamps ) / 30000;
VRipple = ( V  )/4;

% Mux Data
[muxChannelOrder] = muxChannelGrabber(muxFileName); % Gets channels from filename
[muxChannelOrder] = channelMatcher( muxChannelOrder, 'Mux', 'Ripple'); % Converts to Ripple index
numChannelsMux = length(muxChannelOrder);
[ Vordered, timeMux, FsMux ] = ...
    muxGetRaw( muxFileName, 600e3, numChannelsMux, 'downSampleOffset',0, ...
               'downSampleTrigger', 0, 'averageSampleTrigger', 1);
VMux = meanSubtraction(Vordered);   % Remove DC offsets
% VMux = comAvgRef(Vordered);
% VMux = Vordered;

%% Filter Data
% Data from both instruments is stored in a single data structure to allow
% a single for loop to take care of all the spike sorting below. 
% Ripple. 
[ dataFiltRipple ] = filterFunc(VRipple, 30e3, 3, ...
               'highPassCorner', hpCornerFreq, ...
               'lowPassCorner', lpCornerFreq);
[numChannelsRip, ~] = size(dataFiltRipple);
for ii = 1:numChannelsRip
    dataStructure(ii).rawData = VRipple(ii,:);
    dataStructure(ii).filteredData = dataFiltRipple(ii,:);
    dataStructure(ii).Fs = 30e3;
    dataStructure(ii).instrument = 'Ripple';
    dataStructure(ii).electrode = ii;
    dataStructure(ii).time = timeRipple;
    dataStructure(ii).threshColor = [.5 .5 .5];
    dataStructure(ii).figIndex = 1;
end

% Mux
% First we run a first order low pass filter at 5 kHz to approximate the
% bandwidth of the Ripple. Then apply spike filter as above.
% [ VMux ] = singlePoleAnalogFilt(VMux, FsMux, 4.9e3);
[ dataFiltMux ] = filterFunc(VMux, FsMux, 3, ...
               'highPassCorner', hpCornerFreq, ...
               'lowPassCorner', lpCornerFreq);
for ii = ( numChannelsRip + 1 ):( numChannelsRip + numChannelsMux )
    muxIndex = (ii - ( numChannelsRip ) );
    dataStructure(ii).rawData = VMux( muxIndex, : );
    dataStructure(ii).filteredData = dataFiltMux( muxIndex, : );
    dataStructure(ii).Fs = FsMux;
    dataStructure(ii).instrument = 'Mux';
    dataStructure(ii).electrode = muxChannelOrder( muxIndex );
    dataStructure(ii).time = timeMux;
    dataStructure(ii).threshColor = [.5 .5 .5];
    dataStructure(ii).figIndex = 2;
end


%% Spike Sorting
% First detect, then grab threshold crossing events.
rejectMod =  1.7;
ARP       = .001;
threshold = -3.5;
[~, totalChannels] = size(dataStructure);
for ii = 1:totalChannels
 [ dataStructure(ii).waveforms, ...
   dataStructure(ii).timeWave, ...
   dataStructure(ii).waveformSorted,...
   spikeEventsNew , ...
   dataStructure(ii).Vrms] = ...
     spikeSortBlock( dataStructure(ii).filteredData, ...
                     dataStructure(ii).Fs, ...
                     threshold, ...
                     rejectMod, ...
                     ARP );                   
    dataStructure(ii).meanWave = mean(dataStructure(ii).waveformSorted);
    dataStructure(ii).spikeTimes = dataStructure(ii).time(spikeEventsNew);
end

% Generate list used to close figures without Ripple and Mux data
figsToClose = 1:1:16;
figsToClose = [figsToClose 101:1:116];
figsToClose = [figsToClose 201:1:216];
figsToClose = [figsToClose 301:1:316];

% Plot APs
for ii = 1:totalChannels
    figNum = dataStructure(ii).electrode;
    figure(figNum)
    subplot(1,2,dataStructure(ii).figIndex)
    
    try
        plot(dataStructure(ii).timeWave*1e3, dataStructure(ii).waveformSorted, ...
            'Color', dataStructure(ii).threshColor, ...
            'LineWidth', 1.2)
        hold on
        plot(dataStructure(ii).timeWave*1e3, dataStructure(ii).meanWave, 'LineWidth', 3.5)
    catch
        warning('No action potentials detected for E%d', dataStructure(ii).electrode)
    end
    ylim([ -40 40])
    title(dataStructure(ii).instrument)
    ylabel('Amplitude (uV)')
    xlabel('Time (ms)')
    if strcmp(dataStructure(ii).instrument, 'Mux')
        % Remove from list of figures to close if Mux data is present
        figsToClose = figsToClose(find(figsToClose~=figNum));
    end
end

% Plot Raw
for ii = 1:totalChannels
    figNum = dataStructure(ii).electrode + 100;
    figure(figNum)
    subplot(2,1,dataStructure(ii).figIndex)
    plot(dataStructure(ii).time, dataStructure(ii).rawData)
    title(dataStructure(ii).instrument)
    xlim([0 3.5])
    ylim([-1e3 1e3])
    ylabel('Amplitude (uV)')
    xlabel('Time (s)')
    if strcmp(dataStructure(ii).instrument, 'Mux')
        % Remove from list of figures to close if Mux data is present
        figsToClose = figsToClose(find(figsToClose~=figNum));
    end
end

% Plot Spike Filtered
for ii = 1:totalChannels
    figNum = dataStructure(ii).electrode + 200;
    figure(figNum)
    subplot(2,1,dataStructure(ii).figIndex)
    plot(dataStructure(ii).time, dataStructure(ii).filteredData)
    hold on
    plotRaster( gcf, dataStructure(ii).spikeTimes, ...
                'lineCenter', -50, 'lineHeight', 10)
    str = sprintf('%s; Vrms: %d uV', dataStructure(ii).instrument, ...
        dataStructure(ii).Vrms);
    title(str)
    xlim([0 3.5])
    ylim([-60 40])
    ylabel('Amplitude (uV)')
    xlabel('Time (s)')
    if strcmp(dataStructure(ii).instrument, 'Mux')
        % Remove from list of figures to close if Mux data is present
        figsToClose = figsToClose(find(figsToClose~=figNum));
    end
end

% Plot ISI data
for ii = 1:totalChannels
    figNum = dataStructure(ii).electrode + 300;
    figure(figNum)
    subplot(2,1,dataStructure(ii).figIndex)
    try
        spikeEventsDif = diff(dataStructure(ii).spikeTimes*(1e3));
        edges = 0:1:200;
        histogram(spikeEventsDif,edges)
        xlim([0 100])
        xlabel('Inter-Spike Interval (ms)')
        ylabel('Number of Counts')
    catch
        warning('No action potentials detected for E%d', dataStructure(ii).electrode)
    end
    if strcmp(dataStructure(ii).instrument, 'Mux')
        % Remove from list of figures to close if Mux data is present
        figsToClose = figsToClose(find(figsToClose~=figNum));
    end
end

% Close excess figures
for ii = 1:length(figsToClose)
    figure(figsToClose(ii))
    close
end