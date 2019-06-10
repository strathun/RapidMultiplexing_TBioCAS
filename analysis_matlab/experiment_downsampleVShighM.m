%% Experiment: Downsampling vs high Mux factor.
% How does the noise of a downsampled M2 compare to the same channel at
% M20. Approach: run 3 recordings for both cases, calculate the RMS (std)
% of each signal and compare.

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
% M1
% 2019_5_29_12_32_39_1_2097152_15_smpls_raw
% 2019_5_29_12_33_20_1_2097152_15_smpls_raw
% 2019_5_29_12_34_6_1_2097152_15_smpls_raw
%
% M20
% 2019_5_29_11_53_53_20_2097152_3_4_5_2_1_6_0_7_15_8_9_14_13_10_11_12_3_4_5_2_smpls_raw
% 2019_5_29_11_54_8_20_2097152_3_4_5_2_1_6_0_7_15_8_9_14_13_10_11_12_3_4_5_2_smpls_raw
% 2019_5_29_12_23_12_20_2097152_3_4_5_2_1_6_0_7_15_8_9_14_13_10_11_12_3_4_5_2_smpls_raw
% 2019_5_29_12_24_30_20_2097152_3_4_5_2_1_6_0_7_15_8_9_14_13_10_11_12_3_4_5_2_smpls_raw
% 
%%%

%%
muxFileNameCell= {'2019_5_29_12_32_39_1_2097152_15_smpls_raw.mat', ...
                  '2019_5_29_12_33_20_1_2097152_15_smpls_raw.mat', ...
                  '2019_5_29_12_34_6_1_2097152_15_smpls_raw.mat', ...
                  '2019_5_29_11_53_53_20_2097152_3_4_5_2_1_6_0_7_15_8_9_14_13_10_11_12_3_4_5_2_smpls_raw.mat', ...
                  '2019_5_29_12_24_30_20_2097152_3_4_5_2_1_6_0_7_15_8_9_14_13_10_11_12_3_4_5_2_smpls_raw.mat', ...
                  '2019_5_29_12_23_12_20_2097152_3_4_5_2_1_6_0_7_15_8_9_14_13_10_11_12_3_4_5_2_smpls_raw.mat'};
numSamples = length(muxFileNameCell);
analysis_channel = 15;

for ii = 1:numSamples
    muxFileName = muxFileNameCell{ii};             
    hpCornerFreq   =  750;
    lpCornerFreq   = 4000;

    % Mux Data
    [muxChannelOrder] = muxChannelGrabber(muxFileName); % Gets channels from filename
    numChannelsMux = length(muxChannelOrder);
    channel_position = find( muxChannelOrder == analysis_channel );
    [ Vordered, timeMux, FsMux ] = ...
        muxGetRaw( muxFileName, 600e3, numChannelsMux, 'downSampleOffset',0, ...
                   'downSampleTrigger', 1);
    VMux = meanSubtraction(Vordered);   % Remove DC offsets
    % VMux = comAvgRef(Vordered);
    % VMux = Vordered;

    %% Filter Data
    % Data is stored in a single data structure 
    % Mux
    % First we run a first order low pass filter at 5 kHz to approximate the
    % bandwidth of the Ripple. Then apply spike filter as above.
    [ VMux ] = singlePoleAnalogFilt(VMux, FsMux, 4.9e3);
    [ dataFiltMux ] = filterFunc(VMux, FsMux, 3, ...
                   'highPassCorner', hpCornerFreq, ...
                   'lowPassCorner', lpCornerFreq);
    dataStructure(ii).rawData = VMux( channel_position, : );
    dataStructure(ii).filteredData = dataFiltMux( channel_position, : );
    dataStructure(ii).Fs = FsMux;
    dataStructure(ii).MFactor = numChannelsMux;
    dataStructure(ii).time = timeMux;
    dataStructure(ii).noise = std( dataFiltMux( channel_position, : ) );

    %% Plotting data
    figure( dataStructure(ii).MFactor )
    plot(dataStructure(ii).time, dataStructure(ii).filteredData);
    ylabel('Amplitude (uV)')
    xlabel('Time (s)')
    hold on
    ylim([-100 100])
    figure(5)
    scatter( dataStructure(ii).MFactor, dataStructure(ii).noise )
    hold on
    xlabel('M Factor')
    ylabel('Signal RMS')
end
