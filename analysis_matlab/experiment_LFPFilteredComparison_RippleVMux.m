%% Comparing spike filtered time domain data (Ripple V Mux)
% Here, we're looking to see if we can find Mux data that has the
% burst-suppression patterns we see very clearly in the Ripple. Two
% questions to start with are:
%       Are these patterns present in the mux recordings, but they are just
%       obsured by noise?
%       Is it possible that as the anesthesia level changes with time,
%       (Ripple recordings were taken first when the animal would likely be
%       more heavily anesthetized) that these patterns were no longer
%       present during Mux recordings?
close all
clearvars 

% Sets relative filepaths from this script
currentFile = mfilename( 'fullpath' );
cd(fileparts(currentFile));
addpath(genpath('../matlab'));
addpath(genpath('../rawData'));

%%%% Good Mux Files
% 2019_5_17_11_28_37_20_2097152_3_4_5_2_1_6_0_7_15_8_9_14_13_10_11_12_3_4_5_2_smpls_raw.mat
% 2019_5_17_11_57_11_16_2097152_3_4_5_2_1_6_0_7_15_8_9_14_13_10_11_12_smpls_raw
% 2019_5_17_11_23_16_8_2097152_3_4_5_2_1_6_7_0_smpls_raw
%%%%%
muxFileName    = '2019_5_17_11_29_41_20_2097152_3_4_5_2_1_6_0_7_15_8_9_14_13_10_11_12_3_4_5_2_smpls_raw.mat';
rippleFileName = 'SD190509A_Ketamine_20190517_2.ns5';
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
    muxGetRaw( muxFileName, 600e3, numChannelsMux, 'downSampleOffset',0 );
% VMux = meanSubtraction(Vordered);   % Remove DC offsets
% VMux = comAvgRef(Vordered);
VMux = Vordered;

%% Filter Data
% Data from both instruments is stored in a single data structure to allow
% a single for loop to take care of all the spike sorting below. 
% Ripple. 
[ dataFiltRipple ] = filterFunc(VRipple, 30e3, 3, ...
               'highPassCorner', hpCornerFreq, ...
               'lowPassCorner', lpCornerFreq);
[numChannelsRip, ~] = size(dataFiltRipple);
for ii = 1:numChannelsRip
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
[ dataFiltMux ] = singlePoleAnalogFilt(VMux, FsMux, 4.9e3);
[ dataFiltMux ] = filterFunc(dataFiltMux, FsMux, 3, ...
               'highPassCorner', hpCornerFreq, ...
               'lowPassCorner', lpCornerFreq);
for ii = ( numChannelsRip + 1 ):( numChannelsRip + numChannelsMux )
    muxIndex = (ii - ( numChannelsRip ) );
    dataStructure(ii).filteredData = dataFiltMux( muxIndex, : );
    dataStructure(ii).Fs = FsMux;
    dataStructure(ii).instrument = 'Mux';
    dataStructure(ii).electrode = muxChannelOrder( muxIndex );
    dataStructure(ii).time = timeMux;
end

%% Plotting data
[~, totalChannels] = size(dataStructure);
dataStructure = flip(dataStructure,2);
traceCount = zeros(1,totalChannels);    % Count traces on plot for offsetting
yOffset = 0;
for ii = 1:20
    traceCount(dataStructure(ii).electrode) = ...
        traceCount(dataStructure(ii).electrode) + 1;
    if traceCount(dataStructure(ii).electrode) > 1
        yOffset = yOffset + 30*(traceCount(dataStructure(ii).electrode));
    end
    figure(dataStructure(ii).electrode)
    s = plot(dataStructure(ii).time, dataStructure(ii).filteredData + yOffset);
    hold on
    yOffset = 0;
    xlim([0 3.5])
end
figure;for ii = 1:20; plot(timeMux,dataStructure(ii).filteredData+(ii*100)); hold on
end