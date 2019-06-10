function [ dataFilt ] = filterFunc(data, Fs, filterOrder, varargin)
%filterFunc Variety of data filters
%   [ dataFilt ] = filterFunc(data, Fs, filterOrder, varargin)
%   Function to easily apply some of the more commonly used filters in our
%   analysis.
%   Inputs:
%       data            :  Data to be filtered. If multiple channels, 
%                          channels should be arranged in rows.
%       Fs              :  Sampling frequency for each channel
%       filterOrder     :  Select number of poles in the filter
%       lowPassCorner   : Optional. Must be scalar
%       highPassCorner  : Optional. Must be scalar
%       bandstopFreq    : Optional. Must be scalar
%       zeroPhaseFilter : Optional. 0 for causal filter, 1 (default) for ZP

%% Default Values (Inputs)
lowPassCornerDefault   = -1;
highPassCornerDefault  = -1;
bandstopFreqDefault    = -1;
zeroPhaseFilterDefault =  1;

%% Parse inputs
pInput = inputParser;
pInput.addRequired( 'data', ...
    @(x) ( ismatrix(x) ) );
pInput.addRequired( 'Fs', ...
    @(x) ( isscalar(x) && isnumeric(x) && ( x > 0 ) ) ); 
pInput.addRequired( 'filterOrder', ...
    @(x) ( isscalar(x) && isnumeric(x) && ( x > 0 ) ) ); 
pInput.addParameter( 'lowPassCorner', lowPassCornerDefault, ...
    @(x) ( isscalar(x) && isnumeric(x) && ( x >= 0 ) ) ); 
pInput.addParameter( 'highPassCorner', highPassCornerDefault, ...
    @(x) ( isscalar(x) && isnumeric(x) && ( x >= 0 ) ) ); 
pInput.addParameter( 'bandstopFreq', bandstopFreqDefault, ...
    @(x) ( isscalar(x) && isnumeric(x) && ( x >= 0 ) ) ); 
pInput.addParameter( 'zeroPhaseFilter', zeroPhaseFilterDefault, ...
    @(x) ( isscalar(x) && isnumeric(x) && ( x >= 0 ) ) ); 
try
    pInput.parse( data, Fs, filterOrder, varargin{:} );
catch mExp
    error( 'muxGetRaw:invalidInputParameter', ...
        'Error: %s', mExp.message );
end
lowPassCorner = pInput.Results.lowPassCorner;
highPassCorner = pInput.Results.highPassCorner;
bandstopFreq   = pInput.Results.bandstopFreq;
zeroPhaseFilter = pInput.Results.zeroPhaseFilter;
clear pInput

%% Apply Filter
dataFilt = data;
if highPassCorner > 0 
    [ B, A ] = butter( filterOrder, highPassCorner / ( Fs/2 ), 'high');
    [rowData, colData] = size(dataFilt);
    if colData > rowData
        dataFilt = dataFilt.';    %filter takes column as channels, not rows
    end
    dataFilt = filtfilt( B, A, dataFilt);
end
if lowPassCorner > 0
    %Butterworth filter _ low pass
    [ B, A ] = butter( filterOrder, lowPassCorner / ( Fs/2 ));
    [rowData, colData] = size(dataFilt);
    if colData > rowData
        dataFilt = dataFilt.';    %filter takes column as channels, not rows
    end
    dataFilt = filtfilt( B, A, dataFilt);
end
if bandstopFreq > 0
    %Butterworth filter _ bandstop
    d = designfilt('bandstopiir','FilterOrder',20,'HalfPowerFrequency1',...
               (bandstopFreq - .04*bandstopFreq),'HalfPowerFrequency2',...
               (bandstopFreq + .04*bandstopFreq), 'DesignMethod', 'butter',...
               'SampleRate', Fs);
    [rowData, colData] = size(dataFilt);
    if colData > rowData
        dataFilt = dataFilt.';    %filter takes column as channels, not rows
    end
    dataFilt = filtfilt(d, dataFilt);   
end

dataFilt = dataFilt.';
end