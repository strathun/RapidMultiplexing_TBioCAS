%% Towards understanding frequency domain filters
% First we need to understand the double-sided spectrum of matlab's fft().
% If you give it some signal that was sampled at 30 Hz, the double sided
% spectrum will be from -15 Hz -> 0 -> 15 Hz. Let's use a simple signals
% with two sinusoids at 2 and 10 Hz...
% INCOMPLETE

clearvars
close all
Fs = 200; % 30 Hz
t = (0:(1/Fs):1);
F1 =  3;  % 2 Hz
F2 =   20;  % 10 Hz
signal_1 = .5*sin(2*pi*F1*t);
signal_2 = sin(2*pi*F2*t);
signal_total = signal_1 + signal_2;


subplot(2,1,1)
plot(t,signal_1)
hold on
plot(t,signal_2)

subplot(2,1,2)
plot(t,signal_total)

%%
% Now that we have our signals. Lets see the double-sided spectrum 

L = length(signal_total);
signal_fft2 = fft(signal_total);
freq = Fs*(0:(L-1))/L;

figure
plot(freq, signal_fft2)

Y = fft(signal_total);
P2 = abs(Y/L);
P1 = P2(1:L/2+1);
P1(2:end-1) = 2*P1(2:end-1);
freq = Fs*(0:(L/2))/L;

figure
plot(freq,P1)