%% Comparing FFT to PWelch Method
% This experiment is meant to try and gain some insight into the
% differences between fft and sqrt(pwelch) method of spectral analysis.

clearvars 

% Sets relative filepaths from this script
currentFile = mfilename( 'fullpath' );
cd(fileparts(currentFile));
addpath(genpath('../matlab'));
addpath(genpath('../rawData'));

%% Loading time domain data

% Ripple Data
[ NSxFileArray, NSxbasicHeader, NSxchannelHeader, NSxTimeStamps ] = ...
    NSxGetMemMapFile( '20190506_TDT17_PreSurge_2.ns5' );
rawdata = NSxFileArray.Data.NSxData;
V = double( rawdata );
% Cerebus uses .25 uV per bit. Data comes in as bits. Here we're leaving
% units as uV
V = ( V  )/4;

load('instrumentNoisePower_HS2')

% Selecting random channel
Vexperiment = V(2,:);
groundPower = groundPower(:,2);

%% Custom PWelch method

[pxx1,fwelch] = psdWalker(Vexperiment./1e6,64,30e3,groundPower);   % output: nV/rtHz 
%% Using Matlab's native fft over entire signal

L = length(Vexperiment);
Y = fft(Vexperiment);
Fs = 30e3;

P2 = abs(Y/L);
P1 = P2(1:L/2+1);
P1(2:end-1) = 2*P1(2:end-1);
f = Fs*(0:(L/2))/L;

% Converts to nV/rtHz
P1 = P1*1e3;

%% Plot Data
figure(1)
loglog(f,P1)
hold on
loglog(fwelch,pxx1)

%%
% To get a better picture, lets try breaking up the original time domain data
% into 64 different sections and then taking the fft of each section and
% then the average of these 64 ffts. 

%% Preparing Time domain data

Vexperiment = Vexperiment(1:900480)*1e3;    % resize to make divisible by 64, convert to nV
windowL = length(Vexperiment)/64;
VfftDiv = reshape(Vexperiment,[windowL 64]);
VfftDiv = VfftDiv.';
L = length(VfftDiv);

Y = fft(VfftDiv,[],2); % 2 specifies fft for each row

P2 = abs(Y./L);
P1 = P2(:,1:L/2+1);
P1(2:end-1) = 2*P1(2:end-1);

f = Fs*(0:(L/2))/L;
P1avg = mean(P1,1);

figure(1)
loglog(f,P1avg)

%% Impedance Predicted Spectrum
% Adding this for some form of reference because it's relatively simple.
% Not necessarily because it tells me which of these methods is the "most
% correct". This will use ch 08 from the Gamry recordings which is indexed
% as ch 2 in the Ripple.

[fImp, Zreal, Zim, Phase] = ...
    extractImpedanceDataGlobal('..\rawData\Gamry\2019-05-06_TDT17_PreSurge');
kT=300*1.38e-23;
Z = sqrt(Zreal.^2);
noiseImpArray = sqrt(4*kT*Z(:,1,08))*1e9;
fImp = fImp(:,1,08);

figure(1)
loglog(fImp,noiseImpArray,'--','LineWidth',2)
    
legend('PWelch (64avgs)', 'fft', 'fft (64 avgs)', 'Impedance predicted noise')