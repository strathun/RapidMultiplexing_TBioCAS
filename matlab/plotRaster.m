function plotRaster( figureHandle, spikeTimes, varargin)
%plotRaster - This function generates a raster plot on user specified
%   plotRaster( figureHandle, spikeTimes, varargin)
%   Detailed explanation goes here
%   Inputs:
%       figureHandle:   Handle of figure to add raster to. 
%       spikeTimes  :   1 x n array containing spike times (seconds).
%       lineCenter  :   Optional paramater that specifies y axis location 
%                       for center of raster lines.
%       lineHeight  :   Optional paramater that specifies height of raster
%                       lines.
%       
%% Default Values (Inputs)
lineCenterDefault = -80;
lineHeightDefault =  10;

%% Parse inputs
pInput = inputParser;
pInput.addRequired( 'figureHandle', ...
    @(x) ( ishandle(x) ) );
pInput.addRequired( 'spikeTimes', ...
    @(x) ( isvector(x) &&  ( size(x,1) == 1 ) ) ); 
pInput.addParameter( 'lineCenter', lineCenterDefault, ...
    @(x) ( isscalar(x) && isnumeric(x) ) );
pInput.addParameter( 'lineHeight', lineHeightDefault, ...
    @(x) ( isscalar(x) && isnumeric(x) && ( x > 0 ) ) ); 
try
    pInput.parse( figureHandle, spikeTimes, varargin{:} );
catch mExp
    error( 'plotRaster:invalidInputParameter', ...
        'Error: %s', mExp.message );
end
lineCenter = pInput.Results.lineCenter;
lineHeight = pInput.Results.lineHeight;
clear pInput

%% Generate Arrays for Plotting
spikeEvents = spikeTimes;
tickSizeArray = ones(1,length(spikeEvents)) * lineCenter + ...
    ( 0.5 * lineHeight );
tickSizeArray(2,:) = tickSizeArray(1,:) -  lineHeight ;
spikeEvents(2,:) = spikeEvents(1,:) + eps;
plot(spikeEvents, tickSizeArray)

%% Plot Raster
figure(figureHandle)
plot( spikeEvents, tickSizeArray, 'k' );
end

