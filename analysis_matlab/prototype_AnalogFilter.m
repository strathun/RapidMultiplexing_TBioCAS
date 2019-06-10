%% Toward design of analog filter
% The basic idea here is to transform the signal into the frequency domain
% (take fft), multiply by the transfer function for an RC fitler, and then
% transform back into time domain (take ifft). 

%% 
% Start from this sample code from answer on mathworks:

L = 100;   % length of signal in time domain
data = randn(1,L);   % simulated data
DATA = fft(data);   % FFT of data
%     %     %     %     %     %     %     %     %     %     %
% Construct Filter
hf_gain = 0;   % can be set independently
atten_factor = 0.1;
LTF = [ hf_gain ...
linspace(atten_factor, 1, 30)  ...
ones(1,39)  ...
linspace(1, atten_factor, 30)  ];
% Plot filter
clf;
subplot(3,1,1);
plot(LTF, '-b.');
ylim([0  1.2]);
ylabel('Filter');
%     %     %     %     %     %     %     %     %     %     %
% Combine data and filter in frequency domain
LTF = fftshift(LTF);   % shift to match FFT output of data
COMBINED =  DATA .* LTF;   % multiply signal by filter
combined = ifft(COMBINED);   % convert to time domain
%     %     %     %     %     %     %     %     %     %     %
% Plot original and output signals
subplot(3,1,2);
hold on;
box on;
plot(data, '-bs');
plot(real(combined), '--r.');
ylabel('Time  Signals');
legend('original data', 'filtered signal');
% Plot difference between original and output signals
subplot(3,1,3);
plot(data - real(combined), '-g*');
ylabel('Difference');
ylim([-1 1]);

%% Building My Own Version
% Starting with the transfer function. First we need to determine the
% frequency divisions. From the typical method for applying fft(), freq =
% Fs*(0:(L/2))/L. This is just for half of the spectrum though... This may
% have to be modified in a bit. If this is the case, just Fs*(0:L)/L.
% Anyway, after we have this, we need to pass it through our transfer
% function which just comes from solving for Vout of an RC circuit.
%%%
% UPDATE: So after some experimenting and reading, it turns out the correct
% method for the frequency division is to use freq = Fs*(-(L/2)+1:(L/2))/L.
% This is because the initial double sided fft is centered at (1/2)*Fs (see
% below for better description), so when we use this 'freq' to generate the
% transfer function and then fftshift(), we are lining up the correct
% frequency regions (0-15kHz). 

%%
% We can rearrange the equation for the corner frequency to solve for 'RC':

clearvars 

L = 30e3;             % length of signal in time domain
data = randn(1,L);    % simulated data

Fc = 4.9e3;
RC = 1/(Fc*2*pi);
Fs = 30e3;
freq = Fs*(-(L/2)+1:(L/2))/L;   % This is just one method to make this work with fftshift later. 
rcTransferFX = 1./( 1 + ( 1j*2*pi*freq*RC ) );   % matlab likes 1j, idk why

figure
plot(freq,rcTransferFX)
title('Original TransferFX')
xlabel('Frequency (Hz)')
%%
% OK! Looks like we're on the right track here. I'm just not positive what
% our y axis is, but the shape looks rightish. mag2db work?

figure
semilogx(freq,mag2db(rcTransferFX))
xlabel('Frequency (Hz)')
ylabel('Magnitude (dB)')
%%
% Nice! OK, so now we're ready to try and apply it to our signal. Let's
% start off just using the method from the sample code above. This code
% uses fftshift() to deal with the double sided spectrum. We shift the
% right half of the transfer function over to the left, because above, we
% generated the transfer function from -15 kHz to 0 to 15 kHz. Moving this
% to the right will ensure that the function deals properly with the double
% sided fft which goes from 0 to 15 kHz to -15 kHz to 0. Then, later we
% just chop out the second half of the double sided fft. 

dataFFT = fft(data);
rcTransferFX = fftshift(rcTransferFX);
dataFilter = dataFFT .* rcTransferFX;
dataFiltered = (ifft(dataFilter));

figure
plot(freq, rcTransferFX)
title('Shifted TX FX')
xlabel('Frequncy')
figure
plot(data)
hold on
plot(real(dataFiltered))

%%
% Definitely looks like something got filtered. Now lets compare the fft of
% the original data to the new data.

Fs = 30e3;
Y = fft(data);
Yfilt = fft(dataFiltered);

P2 = abs(Y/L);
P1 = P2(1:L/2+1);
P1(2:end-1) = 2*P1(2:end-1);

P2filt = abs(Yfilt/L);
P1filt = P2filt(1:L/2+1);
P1filt(2:end-1) = 2*P1filt(2:end-1);

f = Fs*(0:(L/2))/L;

figure
semilogx(f, P1)
hold on
semilogx(f, P1filt)

%%
% Cool! It looks like it works.
