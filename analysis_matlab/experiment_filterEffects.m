%% Investigating Effects of Filter bandwidth
% Primary goal is to understand filter effects on action potential shape.
% Secondary goal is to determine how we should be filtering our data.

clearvars 

% Sets relative filepaths from this script
currentFile = mfilename( 'fullpath' );
cd(fileparts(currentFile));
addpath(genpath('../matlab'));
addpath(genpath('../rawData'));
numChannels = 16;

%% Load Experimental Data
% Will be looking at data recorded under isoflurane with a multiplexing
% factor of 4.
[ Vordered, time, Fs ] = ...
    muxGetRaw( '2019_5_15_12_12_0_4_2097152_13_14_9_5_smpls_raw.mat', ...
    600e3, numChannels, 'downSampleOffset',0 );
VorderedMF4 = meanSubtraction(Vordered);

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
    [ dataFilt ] = filterFunc(VorderedMF4, 30e3, 3, ...
                   'highPassCorner', 750, 'lowPassCorner', lowPassCornerArray(jj)); 
    figure(1)
    plot(time, dataFilt(1,:));
    hold on

%% Spike Sorting
% First detect, then grab the spike waveforms
    threshold = -3.5;
    rejectMod =    2;
    ARP       = .001;

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
    legend('2', '3', '4', '5', '6', '7')
    title('Low Pass Corner Frequency (kHz)')
end

%%
% It's pretty clear that the low pass corner has a signficant effect on
% waveform shape. The lower the corner, or smaller the bandwidth, the wider
% trough and the smaller the amplitude. 