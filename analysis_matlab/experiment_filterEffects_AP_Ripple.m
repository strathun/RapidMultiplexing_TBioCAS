%% Investigating Effects of Filter bandwidth on Ripple
% Primary goal is to understand filter effects on action potential shape
% for the Ripple. My previous experiments here have shown that it
% significantly affects the shape of the Mux action potentials, but I'm
% curious if the effects are as dramatic with the Ripple system that has a
% much more narrow bandwidth.

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

%% Load Experimental Data

rippleFileName = 'SD190509A_Day20_Ketamine_20190529_1144.ns5';
Fs = 30e3;

% Ripple Data. Ripple uses .25 uV per bit. Data comes in as bits. Here
% we're leaving units as uV [mini function candidate]
[ NSxFileArray, NSxbasicHeader, NSxchannelHeader, NSxTimeStamps ] = ...
    NSxGetMemMapFile( rippleFileName );
rawdata = NSxFileArray.Data.NSxData;
V = double( rawdata );
timeRipple = double( NSxTimeStamps ) / 30000;
VRipple = ( V  )/4;

%% Filtering Data
% Here, we are plotting the mean detected waveform for 6 different low pass
% frequencies: 2, 3, 4, 5, 6, 7 kHz. All filters have a high pass corner of
% 750 Hz. 
for jj = 1:6
    lowPassCornerArray = [
        2000;
        3000;
        4000;
        5000;
        6000;
        7000];
    lowPassCornerArray = flip(lowPassCornerArray);  % Plot looks nicer
    [ dataFilt ] = filterFunc( VRipple, 30e3, 3, ...
                   'highPassCorner', 750, ...
                   'lowPassCorner', lowPassCornerArray(jj) ); 
    figure(1)
    plot(timeRipple, dataFilt(1,:));
    hold on

%% Spike Sorting
% First detect, then grab the spike waveforms
    threshold = -3.5;
    rejectMod =    2;
    ARP       = .001;
    [numChannels, ~] = size( dataFilt );
    for ii = 1:numChannels
        [spikesIndex, threshVal] = spike_detection(dataFilt(ii,:),threshold,1,0);
        [waveforms{ii}, timeWave, spikesIndex] = ...
            waveformGrabber(dataFilt(ii,:), spikesIndex, 1.6, Fs); % Must be more than two spike events

        [events, ~] = size(waveforms{ii}) ; 
        waveform = waveforms{ii} ;
        [waveform, spikeEventsNew] = templateMatcher(waveform, rejectMod, ...
                                     spikesIndex, ARP, Fs); %removes "bad" spikes
        [eventsMod, ~] = size(waveform) ; 
        [~, threshCount(ii+1)] = size(spikeEventsNew); %+1 to add zero at beginning for below...
        spikeEventsRaster{ii} = spikeEventsNew;

%%
% Here, we are plotting the mean waveform from each channel (each plot is a
% different channel), at each of the low pass frequencies (each traces is a
% different frequency. 
        figure(ii+numChannels)
        meanWave = mean(waveform) ;
        plot(timeWave*1e3, meanWave, 'LineWidth', 3.5)
        hold on
        xlabel('Time (ms)');
        ylabel('Voltage (uV)');
    end
end

for ii = 1:numChannels
    figure(ii+numChannels)
    legend('7', '6', '5', '4', '3', '2')
    title('Low Pass Corner Frequency (kHz)')
end

%%
% The lowpass corner does appear to have an effect for the Ripple as well.
% However, it does not seem to be as significant until it is at least less
% than the 4.9 kHz corner of the Ripple system. 