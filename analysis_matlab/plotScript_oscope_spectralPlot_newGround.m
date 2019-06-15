%% Plotscript: Noise with Tye's Circuits
% Testing to see if the spectrum from time domain measurements made with
% Tye's circuits (newest High speed; one we're using for full spectrum
% measurements now) using the oscilloscope match up with what we expect.
% This is a trouble shooting step since Mohit's mux do not seem to match
% up, and we wanted to use something with a wider bandwidth than the
% Ripple. Measurements of TDT18 ~72 hours in PBS 1x

% Initialize and set relative filepaths FROM THIS script
close all 
clearvars 
currentFile = mfilename( 'fullpath' );
cd(fileparts(currentFile));
addpath(genpath('../matlab'));
[ outputDir ] = initializeScript( currentFile );

% Loading o-scope measurements and spectral data of the instrument noise
% measurements. Instrument noise is in nV/rt(Hz)
%%%
% 20190614_TDT18_EUnknown_00.mat
% 20190614_TDT18_EUnknown_01.mat
%
load( '20190614_TDT18_EUnknown_01.mat' )    % Data is in Volts
Fs = 1e6;                                   % Sampling Frequency of O-Scope
[pxx1, fwelch] = psdWalker( V, 64, Fs );
% data comes out of psdWalker as nV/rt(Hz). Convert to V
measuredNoiseSpectrum = pxx1/1e9; 
load( '20190614_TDT18_EUnknown_groundMeasurement.mat' )    % Data is in Volts
Fs = 1e6;                                   % Sampling Frequency of O-Scope
[pxx1, fwelch] = psdWalker( V, 64, Fs );
% data comes out of psdWalker as nV/rt(Hz). Convert to V
groundNoiseSpectrum = pxx1/1e9; 
deEmbeddedSpectrum = sqrt( measuredNoiseSpectrum.^2 - groundNoiseSpectrum.^2 );

% Interpolating tranfer function of high speed headstage to frequncy range
% of the spectrum of the o scope measurements
load( 'highSpeedHeadStage_transferFunction.mat' )
highGain = interp1(x,y,fwelch);
lastGainIndex = find(isnan(highGain),1); %Actually first non gain index
if ~isempty(lastGainIndex)
    highGain(lastGainIndex:end) = highGain(lastGainIndex-1);
end
deEmbeddedSpectrum = deEmbeddedSpectrum./highGain;

% Impedance Measurements
[fImp, Zreal, Zim, Phase] = ...
    extractImpedanceDataGlobal('..\rawData\Gamry\2019-06-13_TDT18_InVitro');
kT=300*1.38e-23;
Z = sqrt(Zreal.^2);
noiseImpArray = sqrt(4*kT*Z(:,1,01))*1e9;
fImp = fImp(:,1,01);

figure(1)
loglog(fImp,noiseImpArray,'--','LineWidth',2)
hold on
loglog(fwelch, deEmbeddedSpectrum*1e9)

%%
% Plot looks much better now with the newer ground measurement.
% Make sure we're using the correct electrode impedance measurement