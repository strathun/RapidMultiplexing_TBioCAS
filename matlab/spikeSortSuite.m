function [waveform_sorted_cell, timeWave] = spikeSortSuite(dataFiltered, threshold, sampleFrequency, varargin)
%UNTITLED4 Summary of this function goes here
%   This runs most of the spike sorting functions from a single function.
%   See individual functions for specifics.
%   Inputs:
%       dataFiltered        : Spike filtered data to be analyzed. Rows
%                             must be channels
%       threshold           : Amplitude threshold for detection of 'action
%                             potential'. [threshold * rms(signal)]
%       sampleFrequency     : Sampling frequency of instrument (per
%                             channel)
%       absRefractoryPeriod : Optional parameter. Specifies the amount of
%                             time (s) required between threshold crossing 
%                             events to be accepted.
%                             [Default : .001]
%       rejectMod           : Optional parameter. Reject waveforms that are
%                             greater than or less than rejectMod * mean
%                             waveform.
%   Outputs:
%       waveform_sorted_cell : Cell array containing all the accepted
%                              threhsold crossing events for each of the 
%                              channels
%       timeWave             : Time for waveforms.

%% Default Values (Inputs)
absRefractoryPeriodDefault = .001;
rejectModDefault = 1.7;

%% Parse inputs
pInput = inputParser;
pInput.addRequired( 'dataFiltered', ...
    @(x) ( isnumeric(x) ) );
pInput.addRequired( 'threshold', ...
    @(x) ( isscalar(x) && isnumeric(x) ) );
pInput.addRequired( 'sampleFrequency', ...
    @(x) ( isscalar(x) && isnumeric(x) ) );
pInput.addParameter( 'absRefractoryPeriod', absRefractoryPeriodDefault, ...
    @(x) ( isscalar(x) && isnumeric(x) && ( x >= 0 ) ) ); 
pInput.addParameter( 'rejectMod', rejectModDefault, ...
    @(x) ( isscalar(x) && isnumeric(x) && ( x >= 0 ) ) ); 

try
    pInput.parse( dataFiltered, threshold, sampleFrequency, varargin{:} );
catch mExp
    error( 'spikeSortSuite:invalidInputParameter', ...
        'Error: %s', mExp.message );
end
absRefractoryPeriod = pInput.Results.absRefractoryPeriod;
rejectMod = pInput.Results.rejectMod;
clear pInput

%% Spike Sorting
% Most of below has been copied from legacy code. May need curating.
[numChannels, ~ ] = size( dataFiltered );

for ii = 1:numChannels
    [spikesIndex, threshVal] = spike_detection(dataFiltered(ii,:),threshold,1,0);
    [waveforms_all{ii}, timeWave, spikesIndex] = ...
        waveformGrabber(dataFiltered(ii,:), spikesIndex, 1.6, sampleFrequency); % Must be more than two spike events

    [events, ~] = size(waveforms_all{ii}) ; 
    waveform = waveforms_all{ii} ;
    [waveform_sorted, spikeEventsNew] = templateMatcher(waveform, rejectMod, ...
                                 spikesIndex, absRefractoryPeriod, sampleFrequency); %removes "bad" spikes
    [eventsMod, ~] = size(waveform_sorted) ; 
    [~, threshCount(ii+1)] = size(spikeEventsNew); %+1 to add zero at beginning for below...
    waveform_sorted_cell{ii} = waveform_sorted ;
end

end

