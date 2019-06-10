function [ dataFiltered ] = singlePoleAnalogFilt(data, Fs, Fc)
%[ dataFiltered ] = singlePoleAnalogFilt(data, Fs, Fc)
%   This function approximates a single pole RC filter
%   Inputs:
%       data:   Data to be filtered. Channels have to be rows.
%       Fs  :   Sampling frequency of data.
%       Fc  :   -3dB point of the filter.

%% Create Transfer Function
L = length(data);
RC = 1/( Fc * 2 * pi );
freq = Fs*(-(L/2)+1:(L/2))/L;
rcTransferFX = 1./( 1 + ( 1j*2*pi*freq*RC ) );   % matlab likes 1j
rcTransferFX = fftshift(rcTransferFX);

%% Prepare Data, Apply Filter
dataFFT = fft(data,L,2);    % specifies fft() of each row
dataFilter = dataFFT .* rcTransferFX;
dataFiltered = real( ifft( dataFilter, L, 2) );
end

