function [waveforms, timeWave, waveformSorted, spikeEventsNew, Vrms] = spikeSortBlock( spikeFilteredData, Fs, threshold, rejectMod, ARP )
%[waveforms, timeWave, waveformSorted, spikeEventsNew] = spikeSortBlock( spikeFilteredData, Fs, threshold, rejectMod, ARP )
%   Consolidates code chunk that was repeated in a lot of scripts for spike
%   sorting. 
%   Inputs:
%       spikeFilteredData: Time domain data arranged with each row as a
%                          channel.
%       Fs       :  Sampling frequency for channel.
%       threshold:  multiplier to determine threshold for putative action 
%                   potentials. [ threshold x Vrms ] = threshold for
%                   detection.
%       rejectMod:  reject waveforms that are > rejectMod X mean waveform
%                   shape at any point.
%       ARP      :  absolute refractory period. Removes waveforms that
%                   occur less than this number (s) since previous
%                   waveform.
%
%   Outputs:
%       waveforms :     ALL detected threshold crossings
%       timeWave  :     time array for plotting waveforms (x-axis)
%       waveformSorted: detected threshold crossings with "bad" events
%                       removed
%       spikeEventsNew: indices for spiking events
%%%

%% Detect Threshold Crossings
[spikesIndex, ~, Vrms] = ...
    spike_detection( spikeFilteredData, ...
                     threshold, 1, 1);  % 2nd number after threshold [ 0 = track threshold crossing; 1 = AP max
                 
%% Grab Threshold Crossing Events From Data
[waveforms, timeWave, spikesIndex] = ...
    waveformGrabber(spikeFilteredData, ...
                    spikesIndex, 1.6, Fs); % Must be more than two spike events

%% Removes "bad" Spikes
[waveformSorted, spikeEventsNew] = ...
    templateMatcher(waveforms, ...
                    rejectMod,...
                    spikesIndex, ...
                    ARP, ...
                    Fs); 
        
end

