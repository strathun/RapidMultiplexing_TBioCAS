%% copy of results_RippleVsMux_actionPotentials.m 
% Used to test whether differences in ISI are result of signals being
% burried or differences in brain states
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

%% Color Pallette
rippleMeanColor = 'k';
rippleThreshColor = [.5 .5 .5];
muxMeanColor = [0 131 232]./256;%[0 144 255]./256;% tropical rain forest%[0 127 232]./256; % azure % [4 138 129]./256;
muxThreshColor = [46 164 255]./256; %[72 169 163]./256;



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
% E03
% muxFileNames    = {'2019_7_24_12_31_53_1_2097152_5_smpls_raw.mat';
%                    '2019_7_24_12_32_37_1_2097152_5_smpls_raw.mat';
%                    '2019_7_24_12_32_42_1_2097152_5_smpls_raw.mat';
%                    '2019_7_24_12_32_47_1_2097152_5_smpls_raw.mat';
%                    '2019_7_24_12_32_52_1_2097152_5_smpls_raw.mat';
%                    '2019_7_24_12_32_56_1_2097152_5_smpls_raw.mat';
%                    '2019_7_24_12_33_1_1_2097152_5_smpls_raw.mat';
%                    '2019_7_24_12_33_6_1_2097152_5_smpls_raw.mat';
%                    '2019_7_24_12_33_10_1_2097152_5_smpls_raw.mat';}; 

muxFileNames    = {'2019_7_24_12_39_2_4_2097152_5_2_1_6_smpls_raw.mat';
                   '2019_7_24_12_39_7_4_2097152_5_2_1_6_smpls_raw.mat';
                   '2019_7_24_12_39_12_4_2097152_5_2_1_6_smpls_raw.mat';
                   '2019_7_24_12_39_17_4_2097152_5_2_1_6_smpls_raw.mat';
                   '2019_7_24_12_38_33_4_2097152_5_2_1_6_smpls_raw.mat';
                   '2019_7_24_12_38_38_4_2097152_5_2_1_6_smpls_raw.mat';
                   '2019_7_24_12_38_43_4_2097152_5_2_1_6_smpls_raw.mat';
                   '2019_7_24_12_38_48_4_2097152_5_2_1_6_smpls_raw.mat';
                   '2019_7_24_12_38_53_4_2097152_5_2_1_6_smpls_raw.mat';}; 

% Started with 11 recordings;
% Removed:
% '2019_7_24_13_25_1_10_2097152_3_4_5_2_1_6_0_7_15_8_smpls_raw.mat'
% '2019_7_24_13_24_41_10_2097152_3_4_5_2_1_6_0_7_15_8_smpls_raw.mat'
% '2019_7_24_13_28_35_10_2097152_3_4_5_2_1_6_0_7_15_8_smpls_raw.mat;
% Added :
% 2019_7_24_13_28_30_10_2097152_3_4_5_2_1_6_0_7_15_8_smpls_raw.mat
               
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
    dataStructure(ii).threshColor = rippleThreshColor; %[0.8867 0.1055 0.2578];
    dataStructure(ii).meanColor = rippleMeanColor; %[0.6350 0.0780 0.1840];
    dataStructure(ii).figIndex = 1;
end

% Prepare Mux Data
[dataStructure, numChannelsMux, muxChannelOrder] = multiMuxCombine(dataStructure, muxFileNames, muxThreshColor);

%% Spike Sorting
% First detect, then grab threshold crossing events.
rejectMod =  1.8;   % 1.7
ARP       = .001;
threshold = -2.8;   % -3.5
[~, totalChannels] = size(dataStructure);
jjj = 1; % Counter for mux ISI Array
dataStructureMuxISI(16).ISI = []; % Initialize structure for appending
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
    dataStructure(ii).ISI = diff(dataStructure(ii).spikeTimes*(1e3));
    % Perform SNR calcs for Ripple data. Mux calcs are below
    if ii <= numChannelsRip
        dataStructure(ii).SNRKelly = snrKelly(dataStructure(ii).waveformSorted);
        dataStructure(ii).pkpkAmp = max( dataStructure(ii).meanWave ) - ...
            min( dataStructure(ii).meanWave );
    else
        dataStructureMuxISI(dataStructure(ii).electrode).ISI = ...
            [dataStructureMuxISI(dataStructure(ii).electrode).ISI ...
            diff(dataStructure(ii).spikeTimes*(1e3))];
    end
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
                '--', 'Color', dataStructure(ii).threshColor, ...
                'LineWidth', 0.5 );
            plot1.Color(4) = 1.0;   % Sets transparency
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
             meanTrace, 'color', rippleMeanColor, 'LineWidth', 3.5)
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
%     traceColor = [1 0 0]; % Pure Red; [0.9290, 0.6940, 0.1250]; % Matlab gold %[0.6350 0.0780 0.1840]; %[0 0.4470 0.7410]; % Better blue than 'blue'
    figNum = muxChannelOrder(ii);
    figure(figNum)
    [ meanTrace, highTrace, lowTrace ] = genSTDTraces( ...
        muxAPCellArray{figNum}, numSTDs);
    plot(dataStructure(totalChannels).timeWave*1e3, ...
         meanTrace, 'color', muxMeanColor, 'LineWidth', 3.5)
    figure(100 + figNum)
    % Second plot for array cartoon
    plot(dataStructure(totalChannels).timeWave*1e3, ...
         meanTrace, 'color', muxMeanColor, 'LineWidth', 3.5)
     hold on
     ylim([ -30 30])
     set(gcf, 'Position',  [50, 100, 200, 300])
%     plot( dataStructure(totalChannels).timeWave*1e3, highTrace, '--', 'color', traceColor, 'LineWidth', 2.5)
%     plot( dataStructure(totalChannels).timeWave*1e3, lowTrace, '--', 'color', traceColor, 'LineWidth', 2.5)

% Calculate SNR and pkpk value for mux
  [SNRKellyMux(figNum)] = snrKelly(muxAPCellArray{figNum});
  pkpkAmpMux(figNum) = max(meanTrace) - min(meanTrace);
end

% Close excess figures
for ii = 1:length(figsToClose)
    figure(figsToClose(ii))
    close
end

%% ISI
% Plot ISI data for RIpple
for ii = 1:16
    figNum = dataStructure(ii).electrode + 300;
    figure(figNum)
    try
        edges = 0:2:200;
        histogram(dataStructure(ii).ISI,edges,...
            'FaceColor', rippleThreshColor, ...
            'FaceAlpha', .5 ,'EdgeColor','none',...
            'Normalization', 'probability')
        hold on
        xlim([0 100])
        xlabel('Inter-Spike Interval (ms)')
        ylabel('Probability')
    catch
        warning('No action potentials detected for E%d', dataStructure(ii).electrode)
    end
end

% Plot ISI data for Mux on top of RIpple
for ii = 1:16
    figure(ii+300)
    try
        edges = 0:2:200;
        histogram(dataStructureMuxISI(ii).ISI,edges,...
            'FaceColor', muxThreshColor, ...
            'FaceAlpha', .5,'EdgeColor','none',...
            'Normalization', 'probability')
        xlim([0 100])
        xlabel('Inter-Spike Interval (ms)')
        ylabel('Probability')
    catch
        warning('No action potentials detected for E%d', dataStructure(ii).electrode)
    end
end

%%
% Still not perfect. Maybe some sort of fill will look better?