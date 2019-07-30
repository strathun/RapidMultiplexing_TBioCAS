function [cumMeas] = walkerTIN(freq, spectrum, fLim)
% [cumMeas] = walkerTIN(freq, spectrum, fLim)
% Performs TIN calculation across specified frequency. Results are in uV.
% This shouuld be useful to integrate with some scripts, but more than
% anything it is to help me remember how to do this properly...
%   Input:
%       freq: frequency traces for spectrums
%       spectrum: noise spectrum. Units should be V/rt(Hz)
%       fLim: 1x2 array -> [startFrequency stopFrequency]
%
%   Outputs:
%       cumMeas: array containing all TIN calculations for each row. Units
%       are uV

% Find indices closest to start and stop frequencies
[ ~, startFreq ] = min( abs( freq(1,:)-fLim(1) ) );
[ ~, stopFreq ]  = min( abs( freq(1,:)-fLim(2) ) );

[numCalcs, ~] = size(spectrum);
for ii = 1:numCalcs
    try
        tempCum = max((cumtrapz(freq(ii,startFreq:stopFreq),spectrum(ii,startFreq:stopFreq).^2)));    % converts spectrum back to power for TIN
        cumMeas(ii) = sqrt(tempCum)*1e6;    % converts to uV
    catch
        warning('Indices out of range for row %d', ii);
        cumMeas(ii) = NaN;
    end
end

end

