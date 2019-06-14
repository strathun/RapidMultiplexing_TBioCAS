%% PlotScript: Plotting sinusoid inputs to mux
% This will be used to get a general idea of how a KNOWN signal looks in
% the mux and how this changes at different multiplexing factors,
% as well as calculate some specifics like gain factor.

close all 
clearvars 

% Sets relative filepaths from this script
currentFile = mfilename( 'fullpath' );
cd(fileparts(currentFile));
addpath(genpath('../matlab'));
addpath(genpath('../rawData'));
addpath(genpath('../output'));
parts = strsplit(currentFile, {'\', '\'});
outputDir = ['../output/' parts{end}];
[~, ~] = mkdir(outputDir);

%%%
% 2019_6_9_12_5_29_2_4194304_2_3_smpls_raw
% 2019_6_9_12_16_12_2_4194304_2_3_smpls_raw
%%%
muxFileName    = '2019_6_9_12_16_12_2_4194304_2_3_smpls_raw.mat';

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

for ii = 1:numChannelsMux
    figure(1)
    plot( timeMux, VMux(ii,:) )
    hold on
    titleStr = sprintf('Ch_%d_File_%s', ii, ...
                      muxFileName);
    title(titleStr, 'Interpreter', 'none')
    xlabel('Time (s)')
    ylabel('Amplitude (uV)')
    xlim( [0 .01] )
end
%%
% So, generally, it looks like the channels are being demultiplexed
% correctly, and that the signals are close to the amplitudes specified in
% the file names. Unfortunately, we can't be certain right now since I
% don't have access to the true input signal. Will check with Mohit to see
% if he checked on the oscilloscope