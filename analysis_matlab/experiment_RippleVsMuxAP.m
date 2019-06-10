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
% Good looking channels
% 2019_5_29_12_5_41_2_2097152_15_8_smpls_raw.mat
% 2019_5_29_12_2_59_4_2097152_15_8_7_0_smpls_raw
%%%

muxFileName    = '2019_5_29_12_5_41_2_2097152_15_8_smpls_raw.mat';
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
    dataStructure(ii).threshColor = [.5 .5 .5];
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
    dataStructure(ii).threshColor = [.4 .4 .5];
end


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

for ii = 1:totalChannels
    figure(dataStructure(ii).electrode)
    plot(dataStructure(ii).timeWave*1e3, dataStructure(ii).waveformSorted, ...
        'Color', dataStructure(ii).threshColor, ...
        'LineWidth', 1.2)
    hold on
    plot(dataStructure(ii).timeWave*1e3, dataStructure(ii).meanWave, 'LineWidth', 3.5)
end

%%
% This is actually looking promising!

%%
% I'm wondering if there is some relationship between the larger action
% potential waveforms we see in the Mux (much larger bandwidth and the 
% increasing amplitude and narrowing that's seen with the spike filter low
% pass corner is extended. Since this effect is still seen with averaging,
% which supposedly reduces some of the aliased noise, this modification of
% the waveform must be coming from something else...

%%
% Next experiment: Get spike times and compare waveforms in raw data. Now
% that we see at least superficial agreement between Mux and Ripple
% waveforms!