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
% Moving forward: Make a new experiment that filters signal in different
% bins, then compare the time domain signals. Add things like std deviation
% and pk-pk, similar to the other raw experiment. 

% Initialize and set relative filepaths FROM THIS script
close all 
clearvars 
currentFile = mfilename( 'fullpath' );
cd(fileparts(currentFile));
addpath(genpath('../matlab'));
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
decimationFactorRipple = 15;
decimationFactorMux = floor(FsMux / 2e3);
for ii = 1:16
    VRipple_Dec(ii,:) = decimate( VRipple(ii,:), decimationFactorRipple );
end
for ii = 1:numChannelsMux
    VMux_Dec(ii,:) = decimate( VMux(ii,:), decimationFactorMux );
end

%% Filter Data
% Data from both instruments is stored in a single data structure 
% Ripple
FsRipple = 30e3 / decimationFactorRipple;
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
FsMux = FsMux / decimationFactorMux;
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

%% Bar Graph of FFT
% Bins will be Delta, Theta, Alpha, Beta, Gamma, 100-300?. First we have to
% find the correct indices in the frequency vector and then sum over those
% ranges in the power vector.
binEdges = [ .4 4 8 12 20 100 300 ];
binLabels = categorical({'.4 - 4', '4 - 8', '8 - 12', '13 - 20',... 
                         '20 - 100', '100 - 300'});
for ii = 1:totalNumChannels
    dataStructure(ii).binEdgesIndex = [];
    for jj = 1:length( binEdges )
        searchVal = binEdges( jj );
        [ d, ix ] = min( abs( dataStructure(ii).fftFreq - searchVal ) );    % Finds closest value
        dataStructure(ii).binEdgesIndex = [ dataStructure(ii).binEdgesIndex ix];
        % Add the next index position for the starting edge of the
        % following bin if not the first or last values. Think about it.
        if jj > 1 && jj < length( binEdges )
            dataStructure(ii).binEdgesIndex = [ dataStructure(ii).binEdgesIndex (ix + 1)];
        end
    end
    dataStructure(ii).binEdgesIndex = sort( dataStructure(ii).binEdgesIndex );
    startSumIndex = 1;  % Ugly variable to make the summing below work correctly
    for kk = 1:( length( dataStructure(ii).binEdgesIndex ) ) / 2
        startIndex = dataStructure(ii).binEdgesIndex( startSumIndex );
        stopIndex = dataStructure(ii).binEdgesIndex( startSumIndex + 1 );
        tempCumSum = cumtrapz( dataStructure(ii).fftFreq( startIndex: ...
                               stopIndex), ...
                         dataStructure(ii).fft( startIndex:stopIndex ) );
        dataStructure(ii).binPower( kk ) = tempCumSum(end);
        startSumIndex = startSumIndex + 2;
    end
    totalCumSum = cumtrapz( dataStructure(ii).fftFreq, ...
                         dataStructure(ii).fft );
    dataStructure(ii).totalPower = totalCumSum(end);
    figure( 100 + dataStructure(ii).electrode )
    % Plotting normalized power
    b = bar( binLabels, ( dataStructure(ii).binPower )./ dataStructure(ii).totalPower );
    hold on
    b.FaceAlpha = 0.2;
    legend( 'Ripple', 'Mux' )
end

%% Plotting
for ii = 1:totalNumChannels
    figure( dataStructure(ii).electrode )
    loglog( dataStructure(ii).fftFreq, dataStructure(ii).fft )
    hold on
    ylabel( 'Power (uV^2/Hz)' )
    xlabel( 'Frequency (Hz)' )
    titleStr = sprintf('Electrode_%d', ...
                  dataStructure(ii).electrode );
    title(titleStr, 'Interpreter', 'none')
    legend('Ripple', 'Mux')
end