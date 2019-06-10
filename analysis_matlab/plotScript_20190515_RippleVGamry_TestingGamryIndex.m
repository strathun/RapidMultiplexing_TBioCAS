%% Plot combined noise data from Ripple, Gamry from 20190515
% For TDT17 
% InVitro measurements taken 20190515. NOTE: channel numbers will be
% different for each instrument because of differences in indexing
% 

clearvars 

% Sets relative filepaths from this script
currentFile = mfilename( 'fullpath' );
cd(fileparts(currentFile));
addpath(genpath('../matlab'));
addpath(genpath('../rawData'));

chRipple = 13;
chTye    = 02; % channel for Tye's boards and Gamry
chTye2   = 10; % Possibly what I think is actually correct for Gamry

%% Prepares Ripple Data
[ NSxFileArray, NSxbasicHeader, NSxchannelHeader, NSxTimeStamps ] = ...
    NSxGetMemMapFile( 'SD190509A_Iso_3_20190515.ns5' );

rawdata = NSxFileArray.Data.NSxData;
V = double( rawdata );

% Cerebus uses .25 uV per bit. Data comes in as bits. Here we're leaving
% units as uV
V = ( V  )/4;

% Preps Ripple data with instrument noise subtracted
load('instrumentNoisePower_HS2')
[pxx1,f] = psdWalker(V(chRipple,:)./1e6,64,30e3,groundPower(:,chRipple));   % output: nV/rtHz 


%% Prepares Impedance Predicted Noise Spectrum
[fImp, Zreal, Zim, Phase] = ...
    extractImpedanceDataGlobal('..\rawData\Gamry\2019-05-15_TDT17_Day06');
kT=300*1.38e-23;
Z = sqrt(Zreal.^2);
noiseImpArray = sqrt(4*kT*Z(:,1,chTye))*1e9;

[fImp, Zreal, Zim, Phase] = ...
    extractImpedanceDataGlobal('..\rawData\Gamry\2019-05-15_TDT17_Day06');
kT=300*1.38e-23;
Z = sqrt(Zreal.^2);
noiseImpArray2 = sqrt(4*kT*Z(:,1,chTye2))*1e9;
%% Plot
figure(1)
loglog(f,pxx1,'LineWidth',1.4)
hold on
loglog(fImp(:,1,chTye),noiseImpArray,'--','LineWidth',2)
loglog(fImp(:,1,chTye),noiseImpArray2,'--','LineWidth',2)
xlim([10 10^5])
ylim([1 1e3])
grid on

legend('Ripple','Impedance','Impedance2')
