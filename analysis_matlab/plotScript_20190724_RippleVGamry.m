%% Plot combined noise data from Ripple, Gamry. 
% For TDT19
% All measurements made 20190724 under isoflurane (~level 2) anesthesia
% NOTE: channel numbers will be different for each instrument because of 
% differences in indexing
% 

clearvars 

% Sets relative filepaths from this script
currentFile = mfilename( 'fullpath' );
cd(fileparts(currentFile));
addpath(genpath('../matlab'));
addpath(genpath('../rawData'));

%% Prepares Ripple Data
[ NSxFileArray, NSxbasicHeader, NSxchannelHeader, NSxTimeStamps ] = ...
    NSxGetMemMapFile( 'SD190719A_Day05_Iso_20190724_1042.ns5' );
rawdata = NSxFileArray.Data.NSxData;
V = double( rawdata );
% Cerebus uses .25 uV per bit. Data comes in as bits. Here we're leaving
% units as uV
V = ( V  )/4;

%% Prepares Impedance Predicted Noise Spectrum
[fImp, Zreal, Zim, Phase] = ...
    extractImpedanceDataGlobal('..\rawData\Gamry\2019-07-24_TDT19_Day05');
kT=300*1.38e-23;
Z = sqrt(Zreal.^2);

for ii = 1:16
    chRipple = ii;
    chTye = channelMatcher( ii, 'Ripple', 'Tye'); % Instruments indexed differently

% Preps Ripple data with instrument noise subtracted
load('instrumentNoisePower_HS2')
[pxx1,f] = psdWalker(V(chRipple,:)./1e6,64,30e3,groundPower(:,chRipple));   % output: nV/rtHz 

% Impedance predicted noise (nV)
noiseImpArray = sqrt(4*kT*Z(:,1,chTye))*1e9;

%% Plot
figure(ii)
loglog(f,pxx1,'LineWidth',1.4)
hold on
loglog(fImp(:,1,chTye),noiseImpArray,'--','LineWidth',2)
xlim([10 15e3])
% ylim([1 1e3])
grid on

legend('Ripple','Impedance')
end
