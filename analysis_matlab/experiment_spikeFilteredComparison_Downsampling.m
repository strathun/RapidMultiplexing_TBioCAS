%% Effects of Downsampling
% Quick test to see how downsampling affects noise envelope of spike
% filtered data. So obviously, this is only really going to affect the
% channels with a multiplexing factor less than 16 and 20 since neither of
% these are down sampled (16: 37.5 kSamples and 20: 30 kSamples/channel).
% So here we're going to look at 1, 2, 4 and 8 factors. The code below was
% used to generate all the figures in the discussion that follows. NOTE:
% Electrode number is on Ripple indexing.

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

%%
% All the recordings used to generate these files are listed below:

% 2019_5_29_12_33_20_1_2097152_15_smpls_raw
% 2019_5_29_12_5_41_2_2097152_15_8_smpls_raw.mat
% 2019_5_29_12_36_8_4_2097152_15_8_7_0_smpls_raw
%   Possibly some bursting on first (15) channel
% 2019_5_29_12_0_53_8_2097152_15_8_7_0_2_5_1_6_smpls_raw
%   Maybe decent
% 2019_5_29_11_59_19_16_2097152_3_4_5_2_1_6_0_7_15_8_9_14_13_10_11_12_smpls_raw
%   Electrode 15 has very clear bursting activity in this recording

muxFileName    = '2019_5_29_12_0_53_8_2097152_15_8_7_0_2_5_1_6_smpls_raw.mat';
hpCornerFreq   =  750;
lpCornerFreq   = 4000;

% Mux Data
[muxChannelOrder] = muxChannelGrabber(muxFileName); % Gets channels from filename
[muxChannelOrder] = channelMatcher( muxChannelOrder, 'Mux', 'Ripple'); % Converts to Ripple index
numChannelsMux = length(muxChannelOrder);
%%
% We need to create two separate data sets, one with downsampling and the
% other without. 
[ Vordered, timeMux, FsMux ] = ...
    muxGetRaw( muxFileName, 600e3, numChannelsMux, 'downSampleOffset',0, ...
               'downSampleTrigger', 0);
[ Vordered_DS, timeMux_DS, FsMux_DS ] = ...
    muxGetRaw( muxFileName, 600e3, numChannelsMux, 'downSampleOffset',0, ...
               'downSampleTrigger', 1);
VMux = meanSubtraction(Vordered);   % Remove DC offsets
VMux_DS = meanSubtraction(Vordered_DS);   % Remove DC offsets
% VMux = comAvgRef(Vordered);
% VMux = Vordered;

%%
% Next, filter the data. 
% First we run a first order low pass filter at 4.9 kHz to approximate the
% bandwidth of the Ripple. Then apply spike filter as above.
[ dataFiltMux ] = singlePoleAnalogFilt(VMux, FsMux, 4.9e3);
[ dataFiltMux ] = filterFunc(dataFiltMux, FsMux, 3, ...
               'highPassCorner', hpCornerFreq, ...
               'lowPassCorner', lpCornerFreq);
[ dataFiltMux_DS ] = singlePoleAnalogFilt(VMux_DS, FsMux_DS, 4.9e3);
[ dataFiltMux_DS ] = filterFunc(dataFiltMux_DS, FsMux_DS, 3, ...
               'highPassCorner', hpCornerFreq, ...
               'lowPassCorner', lpCornerFreq);
for ii = 1:numChannelsMux*2
    if ii < (numChannelsMux) + 1
        dataStructure(ii).filteredData = dataFiltMux(ii,:);
        dataStructure(ii).Fs = FsMux;
        dataStructure(ii).electrode = muxChannelOrder(ii);
        dataStructure(ii).time = timeMux;
        subFigSelect = 1;
    else
        dataStructure(ii).filteredData = dataFiltMux_DS(ii-numChannelsMux,:);
        dataStructure(ii).Fs = FsMux_DS;
        dataStructure(ii).electrode = muxChannelOrder(ii-numChannelsMux);
        dataStructure(ii).time = timeMux_DS;
        subFigSelect = 2;
    end
        
   figure(dataStructure(ii).electrode)
   subplot(2,1,subFigSelect)
   plot(dataStructure(ii).time, dataStructure(ii).filteredData)
   titleStr = sprintf('Electrode_%d_PassBand_%d_%d_%s', ...
                      dataStructure(ii).electrode, ...
                      hpCornerFreq, lpCornerFreq, muxFileName);
   title(titleStr, 'Interpreter', 'none')
   xlabel('Time (s)')
   ylabel('Amplitude (uV)')
   ylim([-100 100])
end

%%
% Let's walk through from 1 to 8 multiplexing factors. 

%%
% Below is a comparison of full sampling frequency (top) and demultiplexed
% to 30 kSamples/second (bottom) for multiplexing a single channel
%
% <<..\output\experiment_spikeFilteredComparison_Downsampling\Electrode_10_PassBand_750_4000_2019_5_29_12_33_20_1_2097152_15_smpls_raw.mat.png>>
%
% Clearly, here we see that the full sampling rate (600 kHz) retains what
% looks to be some of the burst-suppression behavior seen in the Ripple
% recordings. For whatever reason, these disappear when donw sampling.
% Let's look at the others...

%%
% Factor of 2
%
% <<..\output\experiment_spikeFilteredComparison_Downsampling\Electrode_10_PassBand_750_4000_2019_5_29_12_5_41_2_2097152_15_8_smpls_raw.mat.png>>
%

%%
% Factor of 4.
% It looks like electrode 10 has pretty clear spiking in both the full
% sampling rate as well as the downsampled:
%
% <<..\output\experiment_spikeFilteredComparison_Downsampling\Electrode_10_PassBand_750_4000_2019_5_29_12_36_8_4_2097152_15_8_7_0_smpls_raw.mat.png>>
%

%%
% Factor of 8
%
% <<..\output\experiment_spikeFilteredComparison_Downsampling\Electrode_10_PassBand_750_4000_2019_5_29_12_0_53_8_2097152_15_8_7_0_2_5_1_6_smpls_raw.mat.png>>
%



