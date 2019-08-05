%% Experiment: Scrambled AP
% This experiment is to see if the basic shape of action potentials are
% preserved for each channel, even with the mux order scrambled.
% Data is from 7/31/2019 under ketamine anesthesia
% Scrapped this method and just did two separate runs for the different
% orders.

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
% Need to cycle through this twice for the two Mux orders. 
% Order 1
muxFileNames{1}    = {'2019_7_24_13_24_41_10_2097152_3_4_5_2_1_6_0_7_15_8_smpls_raw.mat';
                   '2019_7_24_13_24_56_10_2097152_3_4_5_2_1_6_0_7_15_8_smpls_raw.mat';
                   '2019_7_24_13_25_1_10_2097152_3_4_5_2_1_6_0_7_15_8_smpls_raw.mat';
                   '2019_7_24_13_27_14_10_2097152_3_4_5_2_1_6_0_7_15_8_smpls_raw.mat';
                   '2019_7_24_13_27_29_10_2097152_3_4_5_2_1_6_0_7_15_8_smpls_raw.mat';
                   '2019_7_24_13_27_34_10_2097152_3_4_5_2_1_6_0_7_15_8_smpls_raw.mat';
                   '2019_7_24_13_27_54_10_2097152_3_4_5_2_1_6_0_7_15_8_smpls_raw.mat';
                   '2019_7_24_13_29_5_10_2097152_3_4_5_2_1_6_0_7_15_8_smpls_raw.mat';
                   '2019_7_24_13_29_0_10_2097152_3_4_5_2_1_6_0_7_15_8_smpls_raw.mat';
                   '2019_7_24_13_28_25_10_2097152_3_4_5_2_1_6_0_7_15_8_smpls_raw.mat';
                   '2019_7_24_13_28_35_10_2097152_3_4_5_2_1_6_0_7_15_8_smpls_raw.mat';}; 

% Order 2
muxFileNames{2}    = {'2019_7_24_13_24_41_10_2097152_3_4_5_2_1_6_0_7_15_8_smpls_raw.mat';
                   '2019_7_24_13_24_56_10_2097152_3_4_5_2_1_6_0_7_15_8_smpls_raw.mat';
                   '2019_7_24_13_25_1_10_2097152_3_4_5_2_1_6_0_7_15_8_smpls_raw.mat';
                   '2019_7_24_13_27_14_10_2097152_3_4_5_2_1_6_0_7_15_8_smpls_raw.mat';
                   '2019_7_24_13_27_29_10_2097152_3_4_5_2_1_6_0_7_15_8_smpls_raw.mat';
                   '2019_7_24_13_27_34_10_2097152_3_4_5_2_1_6_0_7_15_8_smpls_raw.mat';
                   '2019_7_24_13_27_54_10_2097152_3_4_5_2_1_6_0_7_15_8_smpls_raw.mat';
                   '2019_7_24_13_29_5_10_2097152_3_4_5_2_1_6_0_7_15_8_smpls_raw.mat';
                   '2019_7_24_13_29_0_10_2097152_3_4_5_2_1_6_0_7_15_8_smpls_raw.mat';
                   '2019_7_24_13_28_25_10_2097152_3_4_5_2_1_6_0_7_15_8_smpls_raw.mat';
                   '2019_7_24_13_28_35_10_2097152_3_4_5_2_1_6_0_7_15_8_smpls_raw.mat';}; 
               
%% Filter Data
% Prepare Mux Data
numChannelsMux = 0;
for ii = 1:2
    [ dataStructure, numChannelsMuxTemp ] = multiMuxCombine( dataStructure, muxFileNames{ii} );
    numChannelsMux = numChannelsMux + numChannelsMuxTemp;
end


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
% Generate list used to close figures without Ripple and Mux data
figsToClose = 1:1:16;

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
        if strcmp(dataStructure(ii).instrument, 'Ripple')
            % Second plot for array cartoon
            figure(figNum + 100)
            plot(dataStructure(ii).timeWave*1e3, dataStructure(ii).meanWave, ...
                'LineWidth', 3.5, 'Color', dataStructure(ii).meanColor)
            hold on
        end

    ylim([ -40 40])
    title(dataStructure(ii).instrument)
    ylabel('Amplitude (uV)')
    xlabel('Time (ms)')
    if strcmp(dataStructure(ii).instrument, 'Mux')
        % Remove from list of figures to close if Mux data is present
        figsToClose = figsToClose(find(figsToClose~=figNum));
    end
end

% Plot mean AP (Ripple)
numSTDs = 1;
for ii = 1:numChannelsMux
    figNum = dataStructure(ii).electrode;
    figure(figNum)
    
    [ meanTrace, highTrace, lowTrace ] = genSTDTraces( ...
            dataStructure(ii).waveformSorted, numSTDs);
        plot(dataStructure(totalChannels).timeWave*1e3, ...
             meanTrace, 'color', 'k', 'LineWidth', 3.5)
        hold on
%         plot( dataStructure(totalChannels).timeWave*1e3, highTrace, 'k--', 'LineWidth', 2.5)
%         plot( dataStructure(totalChannels).timeWave*1e3, lowTrace, 'k--', 'LineWidth', 2.5)
    ylim([ -30 30])
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
for ii = 1:length(muxChannelOrder)
    traceColor = [1 0 0]; %[0.6350 0.0780 0.1840]; %[0 0.4470 0.7410]; % Better blue than 'blue'
    figNum = dataStructure.muxChannelOrder(ii);
    figure(figNum)
    [ meanTrace, highTrace, lowTrace ] = genSTDTraces( ...
        muxAPCellArray{figNum}, numSTDs);
    plot(dataStructure(totalChannels).timeWave*1e3, ...
         meanTrace, 'color', traceColor, 'LineWidth', 3.5)
    figure(100 + figNum)
    % Second plot for array cartoon
    plot(dataStructure(totalChannels).timeWave*1e3, ...
         meanTrace, 'color', traceColor, 'LineWidth', 3.5)
     hold on
     ylim([ -30 30])
     set(gcf, 'Position',  [50, 100, 200, 300])
%     plot( dataStructure(totalChannels).timeWave*1e3, highTrace, '--', 'color', traceColor, 'LineWidth', 2.5)
%     plot( dataStructure(totalChannels).timeWave*1e3, lowTrace, '--', 'color', traceColor, 'LineWidth', 2.5)
end

% Close excess figures
for ii = 1:length(figsToClose)
    figure(figsToClose(ii))
    close
end

%%
% Still not perfect. Maybe some sort of fill will look better?