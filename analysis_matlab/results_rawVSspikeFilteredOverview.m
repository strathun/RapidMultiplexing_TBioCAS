%% Results: LFP Spike Filtered Comparison, Overview
% NOTE: Right now, the "raw" mux data that is being plotted is the
% pseudo-analog filtered data. It seems to make it look less noisy and more
% comparable to the Ripple data. Consider presenting it this way in the
% paper and discussing this of course. 

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
% M20
% 2019_5_29_11_53_53_20_2097152_3_4_5_2_1_6_0_7_15_8_9_14_13_10_11_12_3_4_5_2_smpls_raw
% 2019_5_29_12_23_12_20_2097152_3_4_5_2_1_6_0_7_15_8_9_14_13_10_11_12_3_4_5_2_smpls_raw
% SD190509A_Day20_Ketamine_20190529_1144
%%% Recordings from 05/17
%%%2019_5_17_11_57_11_16_2097152_3_4_5_2_1_6_0_7_15_8_9_14_13_10_11_12_smpls_raw
%%%2019_5_17_11_40_7_16_2097152_3_4_5_2_1_6_0_7_15_8_9_14_13_10_11_12_smpls_raw
%%%
muxFileName    = '2019_5_29_12_2_59_4_2097152_15_8_7_0_smpls_raw.mat';
rippleFileName = 'SD190509A_Day20_Ketamine_20190529_1144.ns5';
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
end

%% Plotting data
[~, totalChannels] = size(dataStructure);
yOffset = 0;
for ii = 1:totalChannels
    % Orders channels from 1 - 16. Repeated channels (Mux) will be 
    % plotted on one another
    if strcmp( dataStructure(ii).instrument, 'Ripple' ) 
        figID = 1;
        yOffset = 30 * ( ( dataStructure( ii ).electrode ) - 1); 
    else
        figID = 3;
        yOffset = 60 * ( ( dataStructure( ii ).electrode ) - 1); 
    end
    
    figure(figID)
    plot(dataStructure(ii).time, dataStructure(ii).rawData + yOffset*5);
    hold on
    xlim([0 3.5])
    figure(figID + 1)
    plot(dataStructure(ii).time, dataStructure(ii).filteredData + yOffset);
    hold on
    xlim([0 3.5])
end

