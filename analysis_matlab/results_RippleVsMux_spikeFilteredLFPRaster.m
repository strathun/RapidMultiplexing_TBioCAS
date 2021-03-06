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
% used in all runs before 20190815 at about 5 pm
%{'2019_7_24_13_24_41_10_2097152_3_4_5_2_1_6_0_7_15_8_smpls_raw.mat'

% New ones to try
%                     '2019_7_24_13_24_56_10_2097152_3_4_5_2_1_6_0_7_15_8_smpls_raw.mat';
%                    '2019_7_24_13_27_14_10_2097152_3_4_5_2_1_6_0_7_15_8_smpls_raw.mat';
%                    '2019_7_24_13_27_29_10_2097152_3_4_5_2_1_6_0_7_15_8_smpls_raw.mat';
%                    '2019_7_24_13_27_34_10_2097152_3_4_5_2_1_6_0_7_15_8_smpls_raw.mat';
%                    '2019_7_24_13_27_54_10_2097152_3_4_5_2_1_6_0_7_15_8_smpls_raw.mat';
%                    '2019_7_24_13_29_5_10_2097152_3_4_5_2_1_6_0_7_15_8_smpls_raw.mat';
%                    '2019_7_24_13_29_0_10_2097152_3_4_5_2_1_6_0_7_15_8_smpls_raw.mat'; last one tested                 
%                    '2019_7_24_13_28_25_10_2097152_3_4_5_2_1_6_0_7_15_8_smpls_raw.mat';
%                    '2019_7_24_13_28_30_10_2097152_3_4_5_2_1_6_0_7_15_8_smpls_raw.mat';};

muxFileNames    = {'2019_7_24_13_28_30_10_2097152_3_4_5_2_1_6_0_7_15_8_smpls_raw.mat'};
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
    dataStructure(ii).threshColor = [.5 .5 .5];
    dataStructure(ii).figIndex = 1;
end

muxThreshColor = [1 1 1]; % Not actually used here, my multiMux function is just not so robust
% Prepare Mux Data
[dataStructure, numChannelsMux, muxChannelOrder] = ...
    multiMuxCombine(dataStructure, muxFileNames, muxThreshColor);


%% Remove unused Ripple Channels
delStart = numChannelsMux + 1;
dataStructure(11:16) = [];

%% Spike Sorting
% First detect, then grab threshold crossing events.
rejectMod =  1.7;%1.7;
ARP       = .001;
threshold =  -3.5; %-7.5;%-2.8;   % -3.5
voltORrms = 1; % select rms (1) for Ripple
[~, totalChannels] = size(dataStructure);
jjj = 1; % Counter for mux ISI Array
dataStructureMuxISI(16).ISI = []; % Initialize structure for appending
for ii = 1:totalChannels
    % If mux, grab the threshold value of the same Ripple channel and set
    % threshold to a voltage value. Eventually fix all of this to do input
    % parsing
    if strcmp(dataStructure(ii).instrument, 'Mux')
        threshold = dataStructure( dataStructure(ii).electrode ).thresholdVal ;
        voltORrms = 0;
        templateWaveform = dataStructure( dataStructure(ii).electrode ).meanWave;
    else
        templateWaveform = [];
    end
 
 [dataStructure(ii).waveforms, dataStructure(ii).timeWave, ...
  dataStructure(ii).waveformSorted, spikeEventsNew, ~, dataStructure(ii).thresholdVal] = ...
     spikeSortBlock( ...
                    dataStructure(ii).filteredData, ...
                    dataStructure(ii).Fs, ...
                    threshold, ...
                    rejectMod, ...
                    ARP, voltORrms, templateWaveform );                   
    dataStructure(ii).meanWave = mean(dataStructure(ii).waveformSorted);
    dataStructure(ii).spikeTimes = dataStructure(ii).time(spikeEventsNew);
end

% Plot Raw
figSpaceArray = zeros(1,2);
for ii = 1:totalChannels
    figNum = dataStructure(ii).electrode;
    figure(dataStructure(ii).figIndex)
    if strcmp(dataStructure(ii).instrument, 'Mux')
        plot(dataStructure(ii).time, dataStructure(ii).rawData + ...
           1000*(dataStructure(ii).electrode - 1), 'k');  
    else
    plot(dataStructure(ii).time, dataStructure(ii).rawData + ...
         1000*(figSpaceArray( dataStructure(ii).figIndex )), 'k');

    end
    hold on
    title(dataStructure(ii).instrument)
    xlim([0 3.5])
    ylabel('Amplitude (uV)')
    xlabel('Time (s)')
    figSpaceArray( dataStructure(ii).figIndex ) = ...
        figSpaceArray( dataStructure(ii).figIndex ) + 1; % counter for spacing
end
figure(1)
xlim([3.5 7]); % Matches mux better

% Plot Spike Filtered
figSpaceArray = zeros(1,2);
for ii = 1:totalChannels
    figNum = dataStructure(ii).electrode;
    figure(dataStructure(ii).figIndex + 2)

    if strcmp(dataStructure(ii).instrument, 'Mux')
        plot(dataStructure(ii).time, dataStructure(ii).filteredData + ...
             40*(dataStructure(ii).electrode - 1), 'k')
        hold on
        plotRaster( gcf, dataStructure(ii).spikeTimes, ...
                'lineCenter', (40*(dataStructure(ii).electrode - 1)) - 20, 'lineHeight', 4)
    else
        plot(dataStructure(ii).time, dataStructure(ii).filteredData + ...
             40*(figSpaceArray( dataStructure(ii).figIndex )), 'k')
        hold on
        plotRaster( gcf, dataStructure(ii).spikeTimes, ...
                'lineCenter', (40*(figSpaceArray( dataStructure(ii).figIndex ))) - 20, 'lineHeight', 4)
    end

    title(dataStructure(ii).instrument)
    xlim([0 3.5])
    ylim([-50 400])
    ylabel('Amplitude (uV)')
    xlabel('Time (s)')
    
    figSpaceArray( dataStructure(ii).figIndex ) = ...
        figSpaceArray( dataStructure(ii).figIndex ) + 1; % counter for spacing
end
figure(3)
xlim([3.5 7]); % Matches mux better


%% 
% Each figure is converted to painters format: 
% -> File -> Export Setup -> Rendering -> Check box next to painter's
% format
