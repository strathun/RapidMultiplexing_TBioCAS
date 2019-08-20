function [SNRKelly, waveformNoiseSD] = snrKelly(waveforms)
%UNTITLED Summary of this function goes here
%   This function calculates SNR for threshold crossing events,
%   Per RC Kelly (2007) J Neurosci 27:261
%   Inputs:
%       waveforms : Array with all putative spike waveforms
%       
%   Outputs:
%       SNRKelly : SNR calculations for waveforms

%SNR calculation 
waveformMean = mean(waveforms);
waveformNoise = waveforms - waveformMean;
waveformNoiseSD = std2(waveformNoise);
SNRKelly = ( max(waveformMean) - min(waveformMean) ) / ( 2 * waveformNoiseSD );
    
end

