function [dataStructure, numChannelsMux, muxChannelOrder] = multiMuxCombine(dataStructure, inputFileNames, muxThreshColor)
% Makes it easier to process mux data from multiple files. Essentially just
% copied and pasted and made to work in a for loop from previous scripts in
% analysis_matlab.

hpCornerFreq   =  750;
lpCornerFreq   = 4000;
[~, totalChannels]  =   size(dataStructure); % Offset for data structure from Ripple data
totalRuns = length(inputFileNames);

for ruNum = 1:totalRuns
    %% Load/Prepare Mux Data
    muxFileName = inputFileNames{ ruNum };
    [muxChannelOrder] = muxChannelGrabber(muxFileName); % Gets channels from filename
    [muxChannelOrder] = channelMatcher( muxChannelOrder, 'Mux', 'Ripple'); % Converts to Ripple index
    numChannelsMux = length(muxChannelOrder);
    [ Vordered, timeMux, FsMux ] = ...
        muxGetRaw( muxFileName, 600e3, numChannelsMux, 'downSampleOffset',0, ...
                   'downSampleTrigger', 0, 'averageSampleTrigger', 1);
    VMux = meanSubtraction(Vordered);   % Remove DC offsets
    % VMux = comAvgRef(Vordered);
    % VMux = Vordered;

    %% Apply Filter
    % First we run a first order low pass filter at 5 kHz to approximate the
    % bandwidth of the Ripple. Then apply spike filter as above.
    [ VMux ] = singlePoleAnalogFilt(VMux, FsMux, 4.9e3);
    [ dataFiltMux ] = filterFunc(VMux, FsMux, 3, ...
                   'highPassCorner', hpCornerFreq, ...
                   'lowPassCorner', lpCornerFreq);
           
%% Build Data Structure          
    for ii = ( totalChannels + 1 ):( totalChannels + numChannelsMux )
        muxIndex = (ii - ( totalChannels ) );
        dataStructure(ii).rawData = VMux( muxIndex, : );
        dataStructure(ii).filteredData = dataFiltMux( muxIndex, : );
        dataStructure(ii).Fs = FsMux;
        dataStructure(ii).instrument = 'Mux';
        dataStructure(ii).electrode = muxChannelOrder( muxIndex );
        dataStructure(ii).time = timeMux;
        dataStructure(ii).threshColor = muxThreshColor; %[0.8867 0.1055 0.2578]; % light red %[ 0.9805 0.7891 0.2070 ]; % light gold; %; % light blue [0 153 255]./256;%[0.5843 0.8157 0.9882];
        dataStructure(ii).figIndex = 2;
        dataStructure(ii).muxChannelOrder = muxChannelOrder;
    end

totalChannels = totalChannels + numChannelsMux;
end
end

