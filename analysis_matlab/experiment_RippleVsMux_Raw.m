%% Experiment: Ripple V Mux Raw
% Here, as a first step, I'm just trying to see if I can get good agreement
% between Ripple raw data and mux 

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

%%%
% 2019_5_29_12_33_20_1_2097152_15_smpls_raw
% 2019_5_29_12_36_8_4_2097152_15_8_7_0_smpls_raw
% 2019_5_29_12_38_2_8_2097152_15_8_7_0_2_5_1_6_smpls_raw
% SD190509A_Ketamine_Day20_20190529_1217
% SD190509A_Ketamine_Day20_20190529_1248

muxFileName    = '2019_5_29_12_38_2_8_2097152_15_8_7_0_2_5_1_6_smpls_raw.mat';
rippleFileName = 'SD190509A_Ketamine_Day20_20190529_1248.ns5';
hpCornerFreq   =  1;
lpCornerFreq   = 300;

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
               'downSampleTrigger', 0, 'averageSampleTrigger', 0);
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
    dataStructure(ii).pkpk = peak2peak( dataStructure(ii).filteredData );
    dataStructure(ii).stdDev = std( dataStructure(ii).filteredData );
end

% Mux
% First we run a first order low pass filter at 5 kHz to approximate the
% bandwidth of the Ripple. Then apply spike filter as above.
% [ dataFiltMux ] = filterFunc(VMux, FsMux, 1, ...
%                'lowPassCorner', 4e3);
[ VMux ] = singlePoleAnalogFilt(VMux, FsMux, 4.9e3);
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
    dataStructure(ii).pkpk = peak2peak( dataStructure(ii).filteredData );
    dataStructure(ii).stdDev = std( dataStructure(ii).filteredData );
end

%% Plotting data
[~, totalChannels] = size(dataStructure);
yOffset = 0;
for ii = 1:totalChannels 
    figure(ii)
%     plot(dataStructure(ii).time, dataStructure(ii).rawData);
%     hold on
    plot(dataStructure(ii).time, dataStructure(ii).filteredData);
    titleStr = sprintf('Electrode_%d_Instrument_%s_PkPk_%.0f_3xStdDev_%.0f', ...
                      dataStructure(ii).electrode, ...
                      dataStructure(ii).instrument, ...
                      dataStructure(ii).pkpk, ...
                      3 * dataStructure(ii).stdDev);
    title(titleStr, 'Interpreter', 'none')
    hold on
    xlabel('Time (s)')
    ylabel('Amplitude (uV)')
end

%%
% After adjusting the gain factor for the mux from 1.8 to 2.2 and making
% sure to compare files that are as close in time as possible, there looks
% to be pretty close agreement between the raw/LFP time waveforms generated
% from both the Ripple and Mux. Good sign, but I'm guessing that the
% problems we had with matching action potential waveforms will now be even
% worse...