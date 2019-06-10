%% Ripple Mux Comparator
% This script can be used to quickly see how the threshold crossing events
% from the same electrodes compare between the Ripple system and the Mux.
% It also houses many of the new functions that have been made to simplify
% the cerebusLoader and loadMohit scripts. 

%%
% Should we use commong average referencing here? Let's start without it.

clearvars 

muxFileName    = '2019_5_17_11_22_49_8_2097152_3_4_5_2_1_6_7_0_smpls_raw.mat';
rippleFileName = 'SD190509A_Ketamine_20190517_2.ns5';
hpCornerFreq   =  750;
lpCornerFreq   = 4500;

% Sets relative filepaths from this script
currentFile = mfilename( 'fullpath' );
cd(fileparts(currentFile));
addpath(genpath('../matlab'));
addpath(genpath('../rawData'));

% Ripple Data. Ripple uses .25 uV per bit. Data comes in as bits. Here
% we're leaving units as uV [mini function candidate]
[ NSxFileArray, NSxbasicHeader, NSxchannelHeader, NSxTimeStamps ] = ...
    NSxGetMemMapFile( rippleFileName );
rawdata = NSxFileArray.Data.NSxData;
V = double( rawdata );
VRipple = ( V  )/4;

% Mux Data
[muxChannelOrder] = muxChannelGrabber(muxFileName); % Gets channels from filename
[muxChannelOrder] = channelMatcher( muxChannelOrder, 'Mux', 'Ripple'); % Converts to Ripple index
numChannelsMux = length(muxChannelOrder);
[ Vordered, time, FsMux ] = ...
    muxGetRaw( muxFileName, 600e3, numChannelsMux, 'downSampleOffset',0 );
VMux = meanSubtraction(Vordered);   % Remove DC offsets

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
end

% Mux
% First we run a first order low pass filter at 5 kHz to approximate the
% bandwidth of the Ripple. Then apply spike filter as above.
[ dataFiltMux ] = filterFunc(VMux, FsMux, 1, ...
               'lowPassCorner', 4e3);
[ dataFiltMux ] = filterFunc(dataFiltMux, FsMux, 3, ...
               'highPassCorner', hpCornerFreq, ...
               'lowPassCorner', lpCornerFreq);
for ii = ( numChannelsRip + 1 ):( numChannelsRip + numChannelsMux )
    muxIndex = (ii - ( numChannelsRip ) );
    dataStructure(ii).filteredData = dataFiltMux( muxIndex, : );
    dataStructure(ii).Fs = FsMux;
    dataStructure(ii).instrument = 'Mux';
    dataStructure(ii).electrode = muxChannelOrder( muxIndex );
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
end

for ii = 1:totalChannels
    figure(dataStructure(ii).electrode)
    plot(dataStructure(ii).timeWave*1e3, dataStructure(ii).waveformSorted, ...
        'Color',[.5 .5 .5], ...
        'LineWidth', 1.2)
    hold on
    plot(dataStructure(ii).timeWave*1e3, dataStructure(ii).meanWave, 'LineWidth', 3.5)
end

