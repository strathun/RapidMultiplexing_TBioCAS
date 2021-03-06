% Plot combined noise data from Ripple, Agilent, Gamry and Mux. For TDT17 
% InVitro measurements taken 20190506. NOTE: channel numbers will be
% different for each instrument because of differences in indexing
% 
% Agilent data generated by running combineLowHighData.m and saving frec
% and prec arrays (contain frequency and noise spectrum (in V) for each
% electrode).

clearvars 

co = [
    0.6350 0.0780 0.1840;
    0.3010 0.7450 0.9330;
    0.9290 0.6940 0.1250;
         0 0.4470 0.7410;
    0.8500 0.3250 0.0980;
    0.4940 0.1840 0.5560;
    0.4660 0.6740 0.1880;
    ];
set(groot,'defaultAxesColorOrder',co);

% Sets relative filepaths from this script
currentFile = mfilename( 'fullpath' );
cd(fileparts(currentFile));
addpath(genpath('../matlab'));
addpath(genpath('../rawData'));

chRipple = 15;
chTye    = 01; % channel for Tye's boards and Gamry

% Loads Agilent data
load('../rawData/Agilent/2019-05-06_TDT17_PreSurge.mat')

%% Prepares Ripple Data
[ NSxFileArray, NSxbasicHeader, NSxchannelHeader, NSxTimeStamps ] = ...
    NSxGetMemMapFile( '20190506_TDT17_PreSurge.ns5' );

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
    extractImpedanceDataGlobal('..\rawData\Gamry\2019-05-06_TDT17_PreSurge');
kT=300*1.38e-23;
Z = sqrt(Zreal.^2);
noiseImpArray = sqrt(4*kT*Z(:,1,8))*1e9;

%% Plot
figure(1)
loglog(frec(chTye,:),prec(chTye,:)*1e9,'LineWidth',1.4) % Agilent
hold on
loglog(f,pxx1,'LineWidth',1.4)
loglog(fImp(:,1,8),noiseImpArray,'--','LineWidth',2)
xlim([10 10^5])
ylim([1 1e3])
grid on

legend('Agilent','Ripple','Impedance')

set(groot,'defaultAxesColorOrder','remove')