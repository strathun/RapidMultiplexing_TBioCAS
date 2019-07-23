%% plotScript: Ripple Action potentials
% Quick script to plot threshold crossings from Ripple recordings

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
    ylim([-30 30])
    xlabel('Time (ms)')
    ylabel('Amplitude (uV)')
end
