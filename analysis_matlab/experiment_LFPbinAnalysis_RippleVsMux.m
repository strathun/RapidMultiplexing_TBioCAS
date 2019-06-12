%% Experiment: LFP Power Comparisons
% This is a first pass at a more computational approach to comparing the
% LFP between Ripple and the Mux. The pipeline will be as follows:
%%
% [Mux only] - Demultiplex signal with no averaging and no subsampling.
% [Both instruments] - Decimate signals down to either 2 (M factor 1, 2, 4,
% 20) or 2.5 (M factor 8 and 16) kSamples. My understanding is that this
% will help remove some of the higher frequency aliased noise, and
% hopefully make the fft values more comparable. If not, I will consider
% normalizing over the total power for each recording to compare relative
% frequency contributions for each system. 
%%
% Improvements to make: subtract out instrument power!

% Initialize and set relative filepaths FROM THIS script
close all 
clearvars 
currentFile = mfilename( 'fullpath' );
[ outputDir ] = initializeScript( currentFile );

muxFileName    = '2019_5_29_12_38_2_8_2097152_15_8_7_0_2_5_1_6_smpls_raw.mat';
rippleFileName = 'SD190509A_Ketamine_Day20_20190529_1248.ns5';
hpCornerFreq   =   1;
lpCornerFreq   = 300;

% Ripple Data.
[ VRipple, timeRipple ] = rippleGetRaw( rippleFileName );

% Mux Data
[muxChannelOrder] = muxChannelGrabber(muxFileName); % Gets channels from filename
[muxChannelOrder] = channelMatcher( muxChannelOrder, 'Mux', 'Ripple'); % Converts to Ripple index
numChannelsMux = length(muxChannelOrder);
[ Vordered, timeMux, FsMux ] = ...
    muxGetRaw( muxFileName, 600e3, numChannelsMux, 'downSampleOffset',0, ...
               'downSampleTrigger', 0, 'averageSampleTrigger', 0);
VMux = meanSubtraction(Vordered);   % Remove DC offsets
% VMux = comAvgRef(Vordered);
% VMux = Vordered;

%% Decimating samples from 30 or 37.5 down to 2 or 2.5 kHz
decimationFactor = 15;
for ii = 1:16
    VRipple_Dec(ii,:) = decimate( VRipple(ii,:), decimationFactor );
end
for ii = 1:numChannelsMux
    VMux_Dec(ii,:) = decimate( VMux(ii,:), decimationFactor );
end

%% Filter Data
% Data from both instruments is stored in a single data structure 
% Ripple
FsRipple = 30e3 / decimationFactor;
[ dataFiltRipple ] = filterFunc(VRipple_Dec, FsRipple, 3, ...
               'highPassCorner', hpCornerFreq, ...
               'lowPassCorner', lpCornerFreq);
[numChannelsRip, ~] = size(dataFiltRipple);
for ii = 1:numChannelsRip
    dataStructure(ii).rawData = VRipple(ii,:);
    dataStructure(ii).decData = VRipple_Dec(ii,:);
    dataStructure(ii).filteredData = dataFiltRipple(ii,:);
    dataStructure(ii).Fs = FsRipple;
    dataStructure(ii).instrument = 'Ripple';
    dataStructure(ii).electrode = ii;
    dataStructure(ii).time = timeRipple;
end

% Mux
FsMux = FsMux / decimationFactor;
[ dataFiltMux ] = filterFunc(VMux_Dec, FsMux, 3, ...
               'highPassCorner', hpCornerFreq, ...
               'lowPassCorner', lpCornerFreq);
for ii = ( numChannelsRip + 1 ):( numChannelsRip + numChannelsMux )
    muxIndex = (ii - ( numChannelsRip ) );
    dataStructure(ii).rawData = VMux( muxIndex, : );
    dataStructure(ii).decData = VMux_Dec( muxIndex, : );
    dataStructure(ii).filteredData = dataFiltMux( muxIndex, : );
    dataStructure(ii).Fs = FsMux;
    dataStructure(ii).instrument = 'Mux';
    dataStructure(ii).electrode = muxChannelOrder( muxIndex );
    dataStructure(ii).time = timeMux;
end

%% FFT 
[ ~, totalNumChannels ] = size(dataStructure);
for ii = 1:totalNumChannels
    L = length(dataStructure(ii).decData);
    Y = fft(dataStructure(ii).decData);
    P2 = abs(Y/L);
    P1 = P2(1:floor(L/2)+1);
    P1(2:end-1) = 2*P1(2:end-1);
    f = ( dataStructure(ii).Fs )*(0:(L/2))/L;
    dataStructure(ii).fft = P1;
    dataStructure(ii).fftFreq = f;
end

%% Plotting
for ii = 1:totalNumChannels
    figure( dataStructure(ii).electrode )
    loglog( dataStructure(ii).fftFreq, dataStructure(ii).fft )
    hold on
    ylabel( 'Amplitude?' )
    xlabel( 'Frequency (Hz)' )
    titleStr = sprintf('Electrode_%d', ...
                  dataStructure(ii).electrode );
    title(titleStr, 'Interpreter', 'none')
    legend('Ripple', 'Mux')
end

%% Histogram of fft data. 