%% Experiment: RippleVsMuxAp
% Combines detected waveforms from multiple multiplexing runs to approach
% 30s of mux data. Raw and spike filtered data are plotted from each run as
% a gut check to the user to make sure none of the channels look
% particularly bad.
% This is for the second round of mux/Ripple measurements at 8x

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
% Good looking mux channels_7/22
% 2019_7_22_13_49_31_4_2097152_5_2_1_6_smpls_raw
% 2019_7_22_13_41_33_8_2097152_3_4_5_2_1_6_0_7_smpls_raw
% 2019_7_22_13_33_39_10_2097152_3_4_5_2_1_6_0_7_15_8_smpls_raw
% 2019_7_22_13_29_25_16_2097152_3_4_5_2_1_6_0_7_15_8_9_14_13_10_11_12_smpls_raw
% 
% Good looking mux channels_7/24
% 
% 
% Ripple
% SD190719A_Ketamine_Day03_20190722_1251
% SD190719A_Day05_Ketamine_20190724_1217
%%%

muxFileNames    = {'2019_7_24_12_39_12_4_2097152_5_2_1_6_smpls_raw.mat'};
rippleFileName = 'SD190719A_Day05_Ketamine_20190724_1217.ns5';
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

% Prepare Mux Data
[dataStructure, numChannelsMux, muxChannelOrder] = multiMuxCombine(dataStructure, muxFileNames);

%% Spike Sorting
% First detect, then grab threshold crossing events.
rejectMod =  1.7;
ARP       = .001;
threshold = -3.5;
[~, totalChannels] = size(dataStructure);
for ii = 1:totalChannels
    [spikesIndex, ~] = ...
        spike_detection(dataStructure(ii).filteredData,threshold,1,0);
    [dataStructure(ii).waveforms, dataStructure(ii).timeWave, spikesIndex] = ...
        waveformGrabber(dataStructure(ii).filteredData, ...
        spikesIndex, 1.6, dataStructure(ii).Fs); % Must be more than two spike events
    
%removes "bad" spikes
    [dataStructure(ii).waveformSorted, spikeEventsNew] = ...
        templateMatcher(dataStructure(ii).waveforms, ...
                        rejectMod,...
                        spikesIndex, ...
                        ARP, ...
                        dataStructure(ii).Fs); 
    dataStructure(ii).meanWave = mean(dataStructure(ii).waveformSorted);
    dataStructure(ii).spikeTimes = dataStructure(ii).time(spikeEventsNew);
end

% Generate list used to close figures without Ripple and Mux data
figsToClose = 1:1:16;
figsToClose = [figsToClose 101:1:116];
figsToClose = [figsToClose 201:1:216];

% Plot APs
for ii = 1:totalChannels
    figNum = dataStructure(ii).electrode;
    figure(figNum)
    subplot(1,2,dataStructure(ii).figIndex)
    plot(dataStructure(ii).timeWave*1e3, dataStructure(ii).waveformSorted, ...
        'Color', dataStructure(ii).threshColor, ...
        'LineWidth', 1.2)
    hold on
    if strcmp(dataStructure(ii).instrument, 'Mux')
        % Remove from list of figures to close if Mux data is present
        figsToClose = figsToClose(find(figsToClose~=figNum));
    end
    if strcmp(dataStructure(ii).instrument, 'Ripple')
        plot(dataStructure(ii).timeWave*1e3, dataStructure(ii).meanWave, 'LineWidth', 3.5)
    end
    ylim([ -40 40])
    title(dataStructure(ii).instrument)
    ylabel('Amplitude (uV)')
    xlabel('Time (ms)')

end

% Gross mess to combine all of the waveforms for matching mux channels from
% different runs so that we can take the mean
muxAPCellArray = cell(1, 16);
for ii = 1:totalChannels
    if strcmp(dataStructure(ii).instrument, 'Mux')
        muxAPCellArray{dataStructure(ii).electrode} = ...
            [muxAPCellArray{dataStructure(ii).electrode}; dataStructure(ii).waveformSorted];
    end
end

% Delete empty cells [Should be safe to delete, removing this line makes
% this script work with channel orders that are more diverse
% muxAPCellArray = muxAPCellArray(~cellfun(@isempty, muxAPCellArray));

% Plot cumulative meanwaves
for ii = 1:length(muxChannelOrder)
    figNum = muxChannelOrder(ii);
    figure(figNum)
    subplot(1,2,2)
    plot(dataStructure(totalChannels).timeWave*1e3, ...
         mean(muxAPCellArray{figNum}), 'LineWidth', 3.5)
end

% Plot Raw
for ii = 1:totalChannels
    figNum = dataStructure(ii).electrode + 100;
    figure(figNum)
    subplot(2,1,dataStructure(ii).figIndex)
    plot(dataStructure(ii).time, dataStructure(ii).rawData)
    hold on
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
figNumArray = zeros(1,16);
for ii = 1:totalChannels
    figNum = dataStructure(ii).electrode + 200;
    figure(figNum)
    subplot(2,1,dataStructure(ii).figIndex)
    figNumArray(figNum - 200) = figNumArray(figNum - 200) + 1; % Counter for spacing plots;
    if dataStructure(ii).figIndex == 2
        % Use this to find the best spike filtered data recording, then use
        % single recording version of this script to get good comparison
        plot(dataStructure(ii).time, dataStructure(ii).filteredData + ...
             40*(figNumArray(figNum - 200) - 2))
        ylim([-40 40])
    elseif dataStructure(ii).figIndex == 1
        plot(dataStructure(ii).time, dataStructure(ii).filteredData)
        ylim([-40 40])
    end
    hold on
    title(dataStructure(ii).instrument)
    xlim([0 3.5])
    
    ylabel('Amplitude (uV)')
    xlabel('Time (s)')
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