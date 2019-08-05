%% Experiment: RippleVsMuxAp
% Combines detected waveforms from multiple multiplexing runs to approach
% 30s of mux data. Raw and spike filtered data are plotted from each run as
% a gut check to the user to make sure none of the channels look
% particularly bad.
% This is for the second round of mux/Ripple measurements at 10x

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

muxFileNames    = {'2019_7_24_13_24_41_10_2097152_3_4_5_2_1_6_0_7_15_8_smpls_raw.mat';
                   '2019_7_24_13_24_56_10_2097152_3_4_5_2_1_6_0_7_15_8_smpls_raw.mat';
                   '2019_7_24_13_25_1_10_2097152_3_4_5_2_1_6_0_7_15_8_smpls_raw.mat';
                   '2019_7_24_13_27_14_10_2097152_3_4_5_2_1_6_0_7_15_8_smpls_raw.mat';
                   '2019_7_24_13_27_29_10_2097152_3_4_5_2_1_6_0_7_15_8_smpls_raw.mat';
                   '2019_7_24_13_27_34_10_2097152_3_4_5_2_1_6_0_7_15_8_smpls_raw.mat';
                   '2019_7_24_13_27_54_10_2097152_3_4_5_2_1_6_0_7_15_8_smpls_raw.mat';
                   '2019_7_24_13_29_5_10_2097152_3_4_5_2_1_6_0_7_15_8_smpls_raw.mat';
                   '2019_7_24_13_29_0_10_2097152_3_4_5_2_1_6_0_7_15_8_smpls_raw.mat';
                   '2019_7_24_13_28_25_10_2097152_3_4_5_2_1_6_0_7_15_8_smpls_raw.mat';
                   '2019_7_24_13_28_35_10_2097152_3_4_5_2_1_6_0_7_15_8_smpls_raw.mat';}; 
rippleFileName = 'SD190719A_Day05_Ketamine_20190724_1313.ns5';
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
    dataStructure(ii).threshColor = [.5 .5 .5]; %[0.8867 0.1055 0.2578];
    dataStructure(ii).meanColor = 'k'; %[0.6350 0.0780 0.1840];
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

 [dataStructure(ii).waveforms, dataStructure(ii).timeWave, ...
  dataStructure(ii).waveformSorted, spikeEventsNew] = ...
     spikeSortBlock( ...
                    dataStructure(ii).filteredData, ...
                    dataStructure(ii).Fs, ...
                    threshold, ...
                    rejectMod, ...
                    ARP );                   
    dataStructure(ii).meanWave = mean(dataStructure(ii).waveformSorted);
    dataStructure(ii).spikeTimes = dataStructure(ii).time(spikeEventsNew);
end

%%
% Generate list used to close figures without Ripple and Mux data
figsToClose = 1:1:16;

% Plot APs
for ii = 1:totalChannels
    figNum = dataStructure(ii).electrode;
    figure(figNum)
    try
        [numTraces, ~] = size(dataStructure(ii).waveformSorted);
        for jj = 1:numTraces    % Have to do it this gross way to do transparency
            plot1 = plot(dataStructure(ii).timeWave*1e3, dataStructure(ii).waveformSorted(jj,:), ...
                'Color', dataStructure(ii).threshColor, ...
                'LineWidth', 1.2);
            plot1.Color(4) = 0.1;   % Sets transparency
            hold on
        end
    catch
        warning('No action potentials detected for E%d', dataStructure(ii).electrode)
    end
        if strcmp(dataStructure(ii).instrument, 'Ripple')
            % Second plot for array cartoon
            figure(figNum + 100)
            plot(dataStructure(ii).timeWave*1e3, dataStructure(ii).meanWave, ...
                'LineWidth', 3.5, 'Color', dataStructure(ii).meanColor)
            hold on
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

% Plot mean AP (Ripple)
numSTDs = 1;
for ii = 1:numChannelsMux
    figNum = dataStructure(ii).electrode;
    figure(figNum)
    
    [ meanTrace, highTrace, lowTrace ] = genSTDTraces( ...
            dataStructure(ii).waveformSorted, numSTDs);
        plot(dataStructure(totalChannels).timeWave*1e3, ...
             meanTrace, 'color', 'k', 'LineWidth', 3.5)
        hold on
%         plot( dataStructure(totalChannels).timeWave*1e3, highTrace, 'k--', 'LineWidth', 2.5)
%         plot( dataStructure(totalChannels).timeWave*1e3, lowTrace, 'k--', 'LineWidth', 2.5)
    ylim([ -30 30])
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

% Plot cumulative meanwaves
for ii = 1:length(muxChannelOrder)
    traceColor = [1 0 0]; %[0.6350 0.0780 0.1840]; %[0 0.4470 0.7410]; % Better blue than 'blue'
    figNum = muxChannelOrder(ii);
    figure(figNum)
    [ meanTrace, highTrace, lowTrace ] = genSTDTraces( ...
        muxAPCellArray{figNum}, numSTDs);
    plot(dataStructure(totalChannels).timeWave*1e3, ...
         meanTrace, 'color', traceColor, 'LineWidth', 3.5)
    figure(100 + figNum)
    % Second plot for array cartoon
    plot(dataStructure(totalChannels).timeWave*1e3, ...
         meanTrace, 'color', traceColor, 'LineWidth', 3.5)
     hold on
     ylim([ -30 30])
     set(gcf, 'Position',  [50, 100, 200, 300])
%     plot( dataStructure(totalChannels).timeWave*1e3, highTrace, '--', 'color', traceColor, 'LineWidth', 2.5)
%     plot( dataStructure(totalChannels).timeWave*1e3, lowTrace, '--', 'color', traceColor, 'LineWidth', 2.5)
end

% Close excess figures
for ii = 1:length(figsToClose)
    figure(figsToClose(ii))
    close
end

%%
% Still not perfect. Maybe some sort of fill will look better?