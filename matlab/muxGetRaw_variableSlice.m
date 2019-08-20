function [ Vordered, time, channelSampleRate, channelNums, channelSliceNums ] = muxGetRaw_variableSlice( matFileName, muxClockRate, numChannels, muxChannelOrder, varargin )
%muxGetRaw - This function loads and demultiplexes raw Mux data
%   [ Vordered, channelSampleRate ] = muxGetRaw_variableSlice( matFileName, muxClockRate, numChannels, varargin )
%   This special case function handles variable slice allocations for the
%   mux where each channel will be sampled at different frequencies... Have
%   fun!
%   Inputs:
%       matFileName :     Name of file. Include .mat extension
%       muxClockRate:     Total sampling frequency (not per channel) of Mux.
%       numChannels :     Number of channels that were multiplexed in this
%                         recording.
%       muxChannelOrder:  Required for special case to ensure interleaving
%                         happens correctly.
%       downSampleOffset: Optional parameter that specifices shift for
%                         downsampling.
%       timeWindow      : Optional paramater that specifies time window to
%                         analyze and cuts input data accordingly, BEFORE
%                         demultiplexing. Must be an array in the form 
%                         [startTime stopTime]. NOTE: This should not be 
%                         used if channel matching is important as it 
%                         likely inserts an offset.
%       downSampleTrigger: Optional paramater that can be used to turn on
%                          or off downsampling. 0: off; 1: on. Default is
%                          on (1).
%       averageSampleTrigger: Optional paramater used to turn on or off
%                             downsampling by averaging every n points
%                             instead of just discarding them. 
%                             [0: off; 1: on. Default is off (0]
%% Default Values (Inputs)
downSampleTriggerDefault = 1;
averageSampleTriggerDefault = 0;
downSampleOffsetDefault = 0;
timeWindowDefault = [0 0];


%% Parse inputs
pInput = inputParser;
pInput.addRequired( 'matFileName', ...
    @(x) ( ischar(x) && exist( x, 'file' ) ) );
pInput.addRequired( 'muxClockRate', ...
    @(x) ( isscalar(x) && isnumeric(x) && ( x > 0 ) ) );
pInput.addRequired( 'numChannels', ...
    @(x) ( isscalar(x) && isnumeric(x) && ( x > 0 ) ) );
pInput.addRequired( 'muxChannelOrder', ...
    @(x) ( isvector(x) && isnumeric(x) ) );
pInput.addParameter( 'downSampleOffset', downSampleOffsetDefault, ...
    @(x) ( isscalar(x) && isnumeric(x) && ( x >= 0 ) ) ); 
pInput.addParameter( 'timeWindow', timeWindowDefault, ...
    @(x) ( isvector(x) && isnumeric(x) ) ); 
pInput.addParameter( 'downSampleTrigger', downSampleTriggerDefault, ...
    @(x) ( isvector(x) && isnumeric(x) ) );
pInput.addParameter( 'averageSampleTrigger', averageSampleTriggerDefault, ...
    @(x) ( isvector(x) && isnumeric(x) ) );
try
    pInput.parse( matFileName, muxClockRate, numChannels, muxChannelOrder, varargin{:} );
catch mExp
    error( 'muxGetRaw_variableSlice:invalidInputParameter', ...
        'Error: %s', mExp.message );
end
downSampleOffset = pInput.Results.downSampleOffset;
timeWindow = pInput.Results.timeWindow;
downSampleTrigger = pInput.Results.downSampleTrigger;
averageSampleTrigger = pInput.Results.averageSampleTrigger;
clear pInput

%% Load Data
V =  load(matFileName); 
V1 = struct2cell(V);
V = V1{1};
V = double(V)*2.2;      % 2.2 is gain factor supplied by Mohit. Changed from 1.8 (6/6/2019)
V = V.';

%% Sort Channels
% First have to make sure every channel has exactly the right number of
% datapoints.
V = V(5:end); %offset of 4; %V(6:end);   % Mux has a 5 data point offset from the listed channel number
timeStart = timeWindow(1);
timeStop = timeWindow(2);
% % Just for debugging purposes
% figure
% plot(V/2.2)
% xlim([1 100])
if timeStop > 0
    V = V( ceil( timeStart * muxClockRate ): ceil( timeStop * muxClockRate ) ); 
end
hangover =  mod(length(V),numChannels);
if hangover ~= 0
    V = V(1:( end - hangover ));
end
for i = 1:numChannels
    Vordered(i,:) = V(i:numChannels:end,:);
end
% for i = 1:numChannels
%     Vordered(i,:) = V(i+5:numChannels:end-15,:);
% end

%% Interleave Data & Set Magic Numbers
% First determine the number of slices allocated to each channel
[ channelSliceNums_temp, channelNums_temp ] = ...
    hist(muxChannelOrder, unique(muxChannelOrder));

% Rearrange in correct order
muxChannelOrder_condensed = unique(muxChannelOrder, 'stable');
for ii = 1:length(channelNums_temp)
    tempIndex = find(channelNums_temp == muxChannelOrder_condensed(ii));
    channelNums(ii) = channelNums_temp(tempIndex);
    channelSliceNums(ii) = channelSliceNums_temp(tempIndex);
end
% Then build a new interleaved array with these numbers
startRow = 1;
for ii = 1:(length(channelNums))
    stopRow = (startRow + channelSliceNums(ii)) - 1;
    inputMatrix = Vordered( startRow : stopRow, : );
    [ VorderedCell{ii} ] = smart_interleave2( inputMatrix );
    startRow = stopRow + 1;
end
% % Just for debugging
% for ii = 1:4
%     figure
%     plot(VorderedCell{ii})
%     xlim([0 120])
% end
%% Downsample Data
% Multiplexing factors of 20 get downsampled to 30 kHz, factors of 16 get
% downsampled to 37.5 kHz. 
Vordered_old = Vordered;
Vordered = [];
for ii = 1:length(channelNums)
    avgPoints = channelSliceNums(ii);
    Vtemp = VorderedCell{ii};
    Vordered(ii,:) = arrayfun(@(i) ...
                                   mean(Vtemp(1,i:i+avgPoints-1)),...
                                   1:avgPoints:length(Vtemp)- ...
                                   avgPoints+1)'; % the averaged vector
end
% channelSampleRate = 30e3;
channelSampleRate = 600e3/numChannels;

% % Won't quite be using this format for this application
% if mod(20, numChannels) == 0
%     singleChannelSampleRate = 30e3;
%     channelMax = 20;
% elseif mod(16, numChannels) == 0
%     singleChannelSampleRate = 37.5e3;
%     channelMax = 16;
% end
% % Pure Downsampling...
% if downSampleTrigger == 1
%     n = (muxClockRate/singleChannelSampleRate) / numChannels ;
%     
%     if n>1
%         Vorderedf = downsample(Vordered.',n,downSampleOffset);
%         Vordered = Vorderedf.';
%     end
%     channelSampleRate = muxClockRate / numChannels / n ;
% %...Or Averaging Data Points...  
% elseif averageSampleTrigger == 1
%     avgPoints = channelMax / numChannels ; %Num points to average
%     for ii = 1:numChannels
%         Vorderedf(ii,:) = arrayfun(@(i) ...
%                                    mean(Vordered(ii,i:i+avgPoints-1)),...
%                                    1:avgPoints:length(Vordered(ii,:))- ...
%                                    avgPoints+1)'; % the averaged vector
%     end
%     Vordered = Vorderedf;
%     channelSampleRate = muxClockRate/ numChannels / avgPoints; 
% %...Or Nothing  
% else
%     channelSampleRate = muxClockRate / numChannels ;
% end

%%% Delete this commented section after up on github
% if downSampleTrigger == 1
%     if mod(20,numChannels) == 0
%         n = (muxClockRate/30e3) / numChannels ; % Assumes 30kHz per channel
%         if n>1
%             Vorderedf = downsample(Vordered.',n,downSampleOffset);
%             Vordered = Vorderedf.';
%         end
%         channelSampleRate = muxClockRate / numChannels / n ;
%     elseif mod(16,numChannels) == 0
%             n = (muxClockRate/37.5e3) / numChannels ; % Assumes 37.5kHz per channel
%         if n>1
%             Vorderedf = downsample(Vordered.',n,downSampleOffset);
%             Vordered = Vorderedf.';
%         end
%         channelSampleRate = muxClockRate / numChannels / n ;
%     end
% else
%     channelSampleRate = muxClockRate / numChannels ;
% end

%% Time Output
time = (1:1:length(Vordered))/channelSampleRate;
end

