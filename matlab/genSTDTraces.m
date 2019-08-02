function [ meanTrace, highTrace, lowTrace ] = genSTDTraces( inputArray, numSTDs)
%[ meanTrace, highTrace, lowTrace ] = genSTDTraces( inputArray, numSTDs)
%   This function takes some data, generates the mean and then two traces,
%   +/- [user specified] standard deviations from the mean.
%   Inputs:
%       inputArray: must be array with rows as individual traces
%       numSTDs   : number of standard deviations for the high and low
%                   traces


meanTrace = mean( inputArray ); 
stdDEV    = std( inputArray );
highTrace = meanTrace + ( stdDEV * numSTDs );
lowTrace = meanTrace - ( stdDEV * numSTDs );
end

