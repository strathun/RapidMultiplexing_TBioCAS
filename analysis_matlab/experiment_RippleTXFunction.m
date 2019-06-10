%% Creating Ripple Transfer Function
% Sinusoids of increasing frequency were recorded using the Ripple system.
% Reduction in amplitude of sinusoids was used to calculate the true corner
% frequency as well as other filter characteristics (order, shape, etc.)
% These will eventually be used to create a filter in matlab that mimics
% these properties, to be used on multiplexing data.

close all
clearvars 

% Sets relative filepaths from this script
currentFile = mfilename( 'fullpath' );
cd(fileparts(currentFile));
addpath(genpath('../matlab'));
addpath(genpath('../rawData'));

% Grabs all filenames from the sinusoid measurements
listFiles = dir('../rawData/Ripple/RippleCornerFreq');
fnames = {listFiles.name}';
fnames = fnames(3:end);

%%
% Cycling through all the individual recordings and calculating pk-pk
% voltage and then finding frequency by running a quick fft and finding the
% max value. 
% Ripple Data. Ripple uses .25 uV per bit. Data comes in as bits. Here
% we're leaving units as uV
for ii = 1:length(fnames)
    fileNameNS5 = fnames{ii};
    [ NSxFileArray, NSxbasicHeader, NSxchannelHeader, NSxTimeStamps ] = ...
        NSxGetMemMapFile( fileNameNS5 );
    rawdata = NSxFileArray.Data.NSxData;
    V = double( rawdata );
    timeRipple = double( NSxTimeStamps ) / 30000;
    VRipple = ( V  )/4;
    
% Calculate pkpk voltage
    Vmin = min(VRipple);
    Vmax = max(VRipple);
    Vpkpk(ii) = Vmax - Vmin;
    
% Calculate True Signal Frequency using Matlab's native fft over 
% entire signal
    L = length(VRipple);
    Y = fft(VRipple);
    Fs = 30e3;

    P2 = abs(Y/L);
    P1 = P2(1:L/2+1);
    P1(2:end-1) = 2*P1(2:end-1);
    f = Fs*(0:(L/2))/L;
    
% Automating search for frequency of the signal
    maxFreqAmp = max(P1);
    maxFreqIndex = find(P1==maxFreqAmp);
    transferFreq(ii) = f(maxFreqIndex);
end

%%
% First, we need to convert everything to nice dB to look professional (and
% so we can do proper calculations. To test the order of the filter, we
% need to calculate the slope. A first order filter will have a slope of
% -20dB/decade or -6dB/octave. Octave refers to a doubling of frequency.
% Because we only tested up to 15kHz, and it is best to not use points to
% close to the corner frequency, we will look at the slope from 15 kHz to
% 7.5 kHz. The magnitude at 15 kHz was found to be -10.3 dB and -5.9 dB at
% 7.5 kHz, which gives a decrease of -4.4 dB/octave. This is slightly less
% than the expected -6 dB/octave of a single pole low pass filter, however,
% as can be seen from the plotted transfer function there is a dip in the
% magnitude that seems to be some sort of error. Additionally, these
% results were not obtained in perfect conditions, so there is some error
% to be expected. Also, 7.5 kHz is still pretty close to the 4.9 kHz corner
% so even this location is not ideal for calculating the slope. 

% Calculate slope
dbGain = mag2db(Vpkpk./Vpkpk(1));
db15 = dbGain(end);
db7p5 = dbGain(34);    % Corresponds to 7.5 in transferFreq
dbSlope = db15 - db7p5; 

% Calculated -3dB point 
[ d, db3 ] = min( abs( dbGain-(-3) ) );
dB3Freq = transferFreq(db3);

semilogx(transferFreq,dbGain,'LineWidth',2)
str = sprintf('Ripple Transfer Function; -3dB: %.0f Hz; Slope: %.2f/octave',...
     dB3Freq, dbSlope);
title(str)
xlabel('Frequency (Hz)')
ylabel('Magnitude (dB)')


%% Approximating Filter in Matlab
% Next, we wanted to try and match the analog filter of the Ripple with a
% digital filter in Matlab. 
lpFilt = designfilt('lowpassiir','FilterOrder',1, ...
'HalfPowerFrequency',4.9e3,'SampleRate',30e3);
fvtool(lpFilt)

%%
% The above is not quite right... We want something that has a consistend
% -6 dB/octave rolloff, whereas this one drops off rapidly to -60 dB by 15
% kHz. Below is an imroved design that uses a first order butterworth
% filter to approximate the analog filter:

[ zb,pb,kb ] = butter( 1,2*pi*4.9e3,'s');
[bb,ab] = zp2tf(zb,pb,kb);
[hb,wb] = freqs(bb,ab,4096);
semilogx(wb/(2*pi),mag2db(abs(hb)),'LineWidth', 2)

%%
% To actually implement this filter, I'm pretty certain you would just use
% the bb, and ab from above or follow a method similar to what I've done
% previously:

[b, a] = butter(1,2*pi*4.9e3,'s');
%%
% Then use filtfilt(b,a, data2BFiltered). If you uncomment the lines below,
% you'll see that this produces the same filter as above. Note that the
% above filter is not normalized (./Fs/2). This is because this is meant to
% mimic an analog, not a digital filter.

% [hb,wb] = freqs(b,a,4096);
% semilogx(wb/(2*pi),mag2db(abs(hb)),'LineWidth', 2)

%%
% Let's double check everything using thermal noise

kT=300*1.38e-23;
sigArray = ones(1,30e3*4);
sigArray = sigArray*sqrt(4*kT*60e3);

    L = length(sigArray);
    Y = fft(sigArray);
    Fs = 30e3;

    P2 = abs(Y/L);
    P1 = P2(1:L/2+1);
    P1(2:end-1) = 2*P1(2:end-1);
    f = Fs*(0:(L/2))/L;
    
semilogx(f,P1)

% % [b, a] = butter(1,2*pi*4.9e3,'s');
% [b, a] = butter(1,4.9e3/30e3/2);
dataFilt = filter( bb, ab, sigArray);

    L = length(dataFilt);
    Y = fft(dataFilt);
    Fs = 30e3;

    P2 = abs(Y/L);
    P1 = P2(1:L/2+1);
    P1(2:end-1) = 2*P1(2:end-1);
    f = Fs*(0:(L/2))/L;
    figure
   semilogx(f,P1)

%% 
% For some reason, can't actually implement anything. Thinking about how to
% actually calculate b and a coefficients. See article saved to pocket. 
