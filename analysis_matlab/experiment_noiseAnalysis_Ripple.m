%% Experiment: Noise Analysis; Ripple
% This is more of a trial experiment to get everything in a single pipeline
% that will hopefully be adapted to the mux. All data was recorded on
% 20190724 under isoflurane. 
% Calculate all relevant noise sources. 
% Use/adapt walkerTIN for these measurements.

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
rippleFileName = 'SD190719A_Day05_Ketamine_20190724_1217.ns5';
gamryFileName  = '..\rawData\Gamry\2019-07-24_TDT19_Day05';
fLim           = [1 15e3];  % Range for TIN calculation

%% Loading/Preparing Data
% First, we need to calculate all of the expected total integrated noise 
% (TIN). This includes circuit noise (grounded measurements) and impedance
% predicted noise. 

% Circuit TIN
load('instrumentNoisePower_HS2')

% Prepares Impedance Predicted Noise Spectrum
% Grab the data
[fImp, Zreal, Zim, Phase] = extractImpedanceDataGlobal(gamryFileName);
kT=300*1.38e-23;
Z = sqrt(Zreal.^2);

% Recorded Signal
hpCornerFreq   =  750;
lpCornerFreq   = 4000;
% Ripple Data. Ripple uses .25 uV per bit. Data comes in as bits. Here
% we're leaving units as uV [mini function candidate]
[ NSxFileArray, NSxbasicHeader, NSxchannelHeader, NSxTimeStamps ] = ...
    NSxGetMemMapFile( rippleFileName );
rawdata = NSxFileArray.Data.NSxData;
V = double( rawdata );
timeRipple = double( NSxTimeStamps ) / 30000;
VRipple = ( V )/4;

%% Channel Calculations
% What should we be using for PSD calculations?
for ii = 1:16
    chRipple = ii;
    chTye = channelMatcher( ii, 'Ripple', 'Tye'); % Instruments indexed differently

    % Measured TIN
    [pxx1,f] = psdWalker(VRipple(chRipple,:)./1e6,64,30e3);   % output: nV/rtHz 

    % Impedance predicted noise (nV)
    noiseImpArray = sqrt(4*kT*Z(:,1,chTye))*1e9;
    
    % TIN Calculations
    % UPDATE: make sure everything goes into this function correctly. Also
    % add a percent error calculation at each frequency to be plotted.
    [cumMeasCircuit] = walkerTIN(freq, spectrum, fLim);
    [cumMeasImp] = walkerTIN(freq, spectrum, fLim);
    [cumMeasMeasured] = walkerTIN(freq, spectrum, fLim);
    
    % Plot
    figure(ii)
    loglog(f,pxx1,'LineWidth',1.4)
    hold on
    loglog(fImp(:,1,chTye),noiseImpArray,'--','LineWidth',2)
    grid on
    legend('Ripple','Impedance')
end
