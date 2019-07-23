%% Plot combined noise data from Ripple, Gamry. 
% For TDT19
% All measurements made 20190722 under ketamine anesthesia
% NOTE: channel numbers will be different for each instrument because of 
% differences in indexing
% 

clearvars 

% Sets relative filepaths from this script
currentFile = mfilename( 'fullpath' );
cd(fileparts(currentFile));
addpath(genpath('../matlab'));
addpath(genpath('../rawData'));

chRipple = 04;
chTye    = 15; % channel for Tye's boards and Gamry

%% Prepares Ripple Data
[ NSxFileArray, NSxbasicHeader, NSxchannelHeader, NSxTimeStamps ] = ...
    NSxGetMemMapFile( 'SD190719A_Ketamine_Day03_20190722_1251.ns5' );

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
    extractImpedanceDataGlobal('..\rawData\Gamry\2019-07-22_TDT19_Day03');
kT=300*1.38e-23;
Z = sqrt(Zreal.^2);
noiseImpArray = sqrt(4*kT*Z(:,1,chTye))*1e9;

%% Plot
figure(1)
loglog(f,pxx1,'LineWidth',1.4)
hold on
loglog(fImp(:,1,chTye),noiseImpArray,'--','LineWidth',2)
% xlim([10 10^5])
ylim([1 1e3])
grid on

legend('Ripple','Impedance')
