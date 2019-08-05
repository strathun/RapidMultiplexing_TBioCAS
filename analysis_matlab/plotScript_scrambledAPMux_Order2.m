%% PlotScript: Scrambled AP Mux
% This is to generate the mean waveforms for mux order 2 to test whether AP
% waveform is preserved for different mux orders. 
% Data is from 07/30/2019 under ketamine anesthesia

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
muxFileNames    = {'2019_7_30_10_27_7_4_2097152_5_6_1_2_smpls_raw.mat';
                   '2019_7_30_10_27_12_4_2097152_5_6_1_2_smpls_raw.mat';
                   '2019_7_30_10_27_17_4_2097152_5_6_1_2_smpls_raw.mat';
                   '2019_7_30_10_27_22_4_2097152_5_6_1_2_smpls_raw.mat';
                   '2019_7_30_10_27_27_4_2097152_5_6_1_2_smpls_raw.mat';
                   '2019_7_30_10_27_32_4_2097152_5_6_1_2_smpls_raw.mat';
                   '2019_7_30_10_27_37_4_2097152_5_6_1_2_smpls_raw.mat';
                   '2019_7_30_10_27_42_4_2097152_5_6_1_2_smpls_raw.mat';
                   '2019_7_30_10_27_46_4_2097152_5_6_1_2_smpls_raw.mat'};


%% Filter Data
% Prepare Mux Data
dataStructure = [];
[dataStructure, numChannelsMux, muxChannelOrder] = multiMuxCombine(dataStructure, muxFileNames);

%% Spike Sorting
% First detect, then grab threshold crossing events.
rejectMod =  1.7;
ARP       = .001;
threshold = -3.5;
[~, totalChannels] = size(dataStructure);
for ii = 1:totalChannels

 [dataStructure(ii).waveforms, dataStructure(ii).timeWave, ...
  dataStructure(ii).waveformSorted, spikeEventsNew] = ...
     spikeSortBlock( ...
                    dataStructure(ii).filteredData, ...
                    dataStructure(ii).Fs, ...
                    threshold, ...
                    rejectMod, ...
                    ARP );                   
    dataStructure(ii).meanWave = mean(dataStructure(ii).waveformSorted);
    dataStructure(ii).spikeTimes = dataStructure(ii).time(spikeEventsNew);
end

%%
% Plot APs
for ii = 1:totalChannels
    figNum = dataStructure(ii).electrode;
    figure(figNum)
    try
        [numTraces, ~] = size(dataStructure(ii).waveformSorted);
        for jj = 1:numTraces    % Have to do it this gross way to do transparency
            plot1 = plot(dataStructure(ii).timeWave*1e3, dataStructure(ii).waveformSorted(jj,:), ...
                'Color', dataStructure(ii).threshColor, ...
                'LineWidth', 1.2);
            plot1.Color(4) = 0.1;   % Sets transparency
            hold on
        end
    catch
        warning('No action potentials detected for E%d', dataStructure(ii).electrode)
    end
    ylim([ -40 40])
    title(dataStructure(ii).instrument)
    ylabel('Amplitude (uV)')
    xlabel('Time (ms)')
end

% Gross mess to combine all of the waveforms for matching mux channels from
% different runs so that we can take the mean
muxAPCellArray = cell(1, 16);
for ii = 1:totalChannels
    if strcmp(dataStructure(ii).instrument, 'Mux')
        muxAPCellArray{dataStructure(ii).electrode} = ...
            [muxAPCellArray{dataStructure(ii).electrode}; dataStructure(ii).waveformSorted];
    end
end

% Plot cumulative meanwaves
numSTDs = 1;
for ii = 1:length(muxChannelOrder)
    traceColor = [1 0 0]; %[0.6350 0.0780 0.1840]; %[0 0.4470 0.7410]; % Better blue than 'blue'
    figNum = muxChannelOrder(ii);
    figure(figNum)
    [ meanTrace, highTrace, lowTrace ] = genSTDTraces( ...
        muxAPCellArray{figNum}, numSTDs);
    plot(dataStructure(totalChannels).timeWave*1e3, ...
         meanTrace, 'color', traceColor, 'LineWidth', 3.5)
    figure(100 + figNum)
    % Second plot for array cartoon
    plot(dataStructure(totalChannels).timeWave*1e3, ...
         meanTrace, 'LineWidth', 3.5)
     hold on
     ylim([ -30 30])
%      set(gcf, 'Position',  [50, 100, 200, 300])
%     plot( dataStructure(totalChannels).timeWave*1e3, highTrace, '--', 'color', traceColor, 'LineWidth', 2.5)
%     plot( dataStructure(totalChannels).timeWave*1e3, lowTrace, '--', 'color', traceColor, 'LineWidth', 2.5)
end

% Plot mean waves from _Order 1
load('muxAPCellArray_Order1_revOrder.mat')
for ii = 1:16
    if ~isempty( muxAPCellArray{ii} )
        [ meanTrace, highTrace, lowTrace ] = genSTDTraces( ...
            muxAPCellArray{ii}, numSTDs);
        figure(100 + ii)
        plot(dataStructure(totalChannels).timeWave*1e3, ...
            meanTrace, 'LineWidth', 3.5)
        legend('Order 2', 'Order 1')
    end
end
%%
% 