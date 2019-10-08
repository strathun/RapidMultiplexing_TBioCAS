%% Results: Variable Slice Allocation
% Loaded data was generated on 20190813 from:
%   plotScript_variableSliceAllocation_allocationA_APs_16slices.m 
%       &
%   plotScript_variableSliceAllocation_allocationB_APs_16slices.m 

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
load('..\output\plotScript_variableSliceAllocation_allocationA_APs_16slices\dataStructures_ripThresh.mat')
dataStructure_A = dataStructure;
dataStructureMuxCumAP_A = dataStructureMuxCumAP;

load('..\output\plotScript_variableSliceAllocation_allocationB_APs_16slices\dataStructure_ripThresh.mat')
dataStructure_B = dataStructure;
dataStructureMuxCumAP_B = dataStructureMuxCumAP;

load('..\output\rev_plotScript_variableSliceAllocation_allocationC_APs_16slices\dataStructureS_orderC.mat')
dataStructure_C = dataStructure;
dataStructureMuxCumAP_C = dataStructureMuxCumAP;

load('..\output\rev_plotScript_variableSliceAllocation_allocationD_APs_16slices\dataStructureS_orderD.mat')
dataStructure_D = dataStructure;
dataStructureMuxCumAP_D = dataStructureMuxCumAP;


%% Shadow Plots
% [~, numWavePoints] = size(dataStructureMuxCumAP_A(1).meanWave);
% timeWave = (1:1:numWavePoints)./(37.5);
% colorWheel_A = [  0  0  1;
%                  .5 .5 .5;
%                   0  0  1;
%                  .5 .5 .5 ];    % high slice number = blue, lower = grey
% [~, numChannels] = size(dataStructureMuxCumAP);
% for ii = 1:(numChannels)
%     figure(dataStructureMuxCumAP_A(ii).electrode)
%     shadowPlot(gcf,timeWave.',dataStructureMuxCumAP_A(ii).waveformSorted.',colorWheel_A(ii,:),'linear')
%     hold on
% end
% 
% colorWheel_B = [ .5 .5 .5;
%                   0  0  1;
%                  .5 .5 .5;
%                   0  0  1];    % high slice number = blue, lower = grey
% for ii = 1:(numChannels)
%     figure(dataStructureMuxCumAP_B(ii).electrode)
%     shadowPlot(gcf,timeWave.',dataStructureMuxCumAP_B(ii).waveformSorted.',colorWheel_B(ii,:),'linear')
%     hold on
% ylim([ -20 20])
% ylabel('Amplitude (uV)')
% xlabel('Time (ms)')
% end

%% Noise floor analysis

[~, totalChannels] = size(dataStructure_A);
noiseFloorCell_A = cell(1,16);
for ii = 17:totalChannels % skipping Riple data (1-16)
    noiseFloorCell_A{dataStructure_A(ii).electrode} = ...
        [ noiseFloorCell_A{dataStructure_A(ii).electrode} dataStructure_A(ii).noiseFloor];
end
[~, totalChannels] = size(dataStructure_B);
noiseFloorCell_B = cell(1,16);
for ii = 17:totalChannels % skipping Riple data (1-16)
    noiseFloorCell_B{dataStructure_B(ii).electrode} = ...
        [ noiseFloorCell_B{dataStructure_B(ii).electrode} dataStructure_B(ii).noiseFloor];
end
[~, totalChannels] = size(dataStructure_C);
noiseFloorCell_C = cell(1,16);
for ii = 17:totalChannels % skipping Riple data (1-16)
    noiseFloorCell_C{dataStructure_C(ii).electrode} = ...
        [ noiseFloorCell_C{dataStructure_C(ii).electrode} dataStructure_C(ii).noiseFloor];
end
[~, totalChannels] = size(dataStructure_D);
noiseFloorCell_D = cell(1,16);
for ii = 17:totalChannels % skipping Riple data (1-16)
    noiseFloorCell_D{dataStructure_D(ii).electrode} = ...
        [ noiseFloorCell_D{dataStructure_D(ii).electrode} dataStructure_D(ii).noiseFloor];
end

% Calculate mean noise floor for all six recordings
for ii = 1:16
    if ii == 5  %ignore the last two bad channels for E05 orderB
            noiseFloorCell_A{2,ii} = mean(noiseFloorCell_A{1,ii});
            noiseFloorCell_B{2,ii} = mean(noiseFloorCell_B{1,ii}(1:3));
            noiseFloorCell_C{2,ii} = mean(noiseFloorCell_C{1,ii});
            noiseFloorCell_D{2,ii} = mean(noiseFloorCell_D{1,ii});
            noisestdCell_A{2,ii} = std(noiseFloorCell_A{1,ii});
            noisestdCell_B{2,ii} = std(noiseFloorCell_B{1,ii}(1:3));
            noisestdCell_C{2,ii} = std(noiseFloorCell_C{1,ii});
            noisestdCell_D{2,ii} = std(noiseFloorCell_D{1,ii});
    else
    noiseFloorCell_A{2,ii} = mean(noiseFloorCell_A{1,ii});
    noiseFloorCell_B{2,ii} = mean(noiseFloorCell_B{1,ii});
    noiseFloorCell_C{2,ii} = mean(noiseFloorCell_C{1,ii});
    noiseFloorCell_D{2,ii} = mean(noiseFloorCell_D{1,ii});
    noisestdCell_A{2,ii} = std(noiseFloorCell_A{1,ii});
    noisestdCell_B{2,ii} = std(noiseFloorCell_B{1,ii});
    noisestdCell_C{2,ii} = std(noiseFloorCell_C{1,ii});
    noisestdCell_D{2,ii} = std(noiseFloorCell_D{1,ii});
    end
end


%% Bar graphs for noise reduction
% Plot noise floor for electrodes 3 and 4 at 6 and 2 slice allocations
% ^ No longer correct
figure
noiseFloor = [noiseFloorCell_A{2,3}, noiseFloorCell_B{2,4}, noiseFloorCell_D{2,5}, noiseFloorCell_C{2,6}; ...   % N = 6
              noiseFloorCell_B{2,3}, noiseFloorCell_A{2,4}, noiseFloorCell_C{2,5}, noiseFloorCell_D{2,6}; ...   % N = 2
              noiseFloorCell_D{2,3}, noiseFloorCell_C{2,4}, noiseFloorCell_A{2,5}, noiseFloorCell_B{2,6}; ...   % N = 3
              noiseFloorCell_C{2,3}, noiseFloorCell_D{2,4}, noiseFloorCell_B{2,5}, noiseFloorCell_A{2,6}];      % N = 5
noiseStd =   [noisestdCell_A{2,3}, noisestdCell_B{2,4}, noisestdCell_D{2,5}, noisestdCell_C{2,6}; ...     % N = 6
              noisestdCell_B{2,3}, noisestdCell_A{2,4}, noisestdCell_C{2,5}, noisestdCell_D{2,6}; ...   % N = 2
              noisestdCell_D{2,3}, noisestdCell_C{2,4}, noisestdCell_A{2,5}, noisestdCell_B{2,6}; ...   % N = 3
              noisestdCell_C{2,3}, noisestdCell_D{2,4}, noisestdCell_B{2,5}, noisestdCell_A{2,6}];      % N = 5
          
x = [6; 2; 3; 5];
bar(x, noiseFloor)
xlabel('Slice Budget')
ylabel('Noise (uV)')
legend('E03', 'E04', 'E05', 'E06')
ylim([0 5])

%%


% % Plot noise floor for electrodes 5 and 6 at 3 and 5 slice allocations
% figure
% noiseFloor = [noiseFloorCell_A{2,5}, noiseFloorCell_B{2,6}; ...
%               noiseFloorCell_B{2,5}, noiseFloorCell_A{2,6}];
% x = [3; 5];
% bar(x, noiseFloor)
% xlabel('Slice Budget')
% ylabel('Noise (uV)')
% legend('E05', 'E06')
% ylim([0 5])

%% Scatter plot for noise reduction
% Changed to line plot per Ross' request

noiseFloor_ordered = [noiseFloor(2:end,:); noiseFloor(1,:)];
x_ordered = [x(2:end); x(1)];
% Matches colors from paper
colorArray = [ 193  81  81;
                90 170 201;
               239 188  86;
               177 143 181]./256;
figure
for ii = 1:4
    scatter(x, noiseFloor(:, ii), 'Filled', 'MarkerFaceColor', colorArray(ii,:))
    hold on
    plot(x_ordered, noiseFloor_ordered(:, ii), 'Color', colorArray(ii,:), ...
        'LineWidth', 1.5 )
end

xlim([1 7])
xlabel('Slice Budget')
ylabel('Noise (uV)')
legend('E03', '', 'E04','', 'E05','', 'E06')

%% Average bar plot with error bars

figure
hold on
% See order from above
noiseFloor_bar(4) = mean(noiseFloor(1,:));
noiseStd_bar(4) = std(noiseFloor(1,:));
noiseFloor_bar(1) = mean(noiseFloor(2,:));
noiseStd_bar(1) = std(noiseFloor(2,:));
noiseFloor_bar(2) = mean(noiseFloor(3,:));
noiseStd_bar(2) = std(noiseFloor(3,:));
noiseFloor_bar(3) = mean(noiseFloor(4,:));
noiseStd_bar(3) = std(noiseFloor(4,:));
slice_bar = [2, 3, 5, 6];
bar(slice_bar, noiseFloor_bar)
errorbar(slice_bar, noiseFloor_bar, noiseStd_bar, '.', 'color', 'k', ...
         'LineWidth', 1.5)

%% Combined Scatter and bar (no error bars)

figure
% bar graph
slice_bar = [2, 3, 5, 6];
b = bar(slice_bar, noiseFloor_bar);
hold on
b.EdgeColor = [ 0 0 0 ];
b.LineWidth = 2;
b.FaceColor = [ 1 1 1 ];
% Scatter
for ii = 1:4
    scatter(x, noiseFloor(:, ii), 'Filled')
    hold on
end

xlim([1 7])
xlabel('Slice Budget')
ylabel('Noise (uV)')
legend('Average', 'E03', 'E04', 'E05', 'E06')

%% Stacked 2 -> 6 comparison with error bars
figure
% Take 6 and 2 slice positions for each electrode (ii) from matrix above.
for ii = 1:4
    noise_stacked(ii,:) = noiseFloor(1:2,ii);
end
noise_stacked_plot = noise_stacked;
noise_stacked_plot(:,2) = noise_stacked(:,2) - noise_stacked(:,1);
b = bar( 3:6, noise_stacked_plot, 'Stacked', 'FaceColor', 'flat');
hold on
% Change colors
b(2).FaceColor = [.5 .5 .5];

noiseFloor_stackedError = [noiseFloorCell_A{2,3}, noiseFloorCell_B{2,4}, noiseFloorCell_D{2,5}, noiseFloorCell_C{2,6}; ...   % N = 6
                           noiseFloorCell_B{2,3}, noiseFloorCell_A{2,4}, noiseFloorCell_C{2,5}, noiseFloorCell_D{2,6}]; ...
              
noiseStd_stackedError =   [noisestdCell_A{2,3}, noisestdCell_B{2,4}, noisestdCell_D{2,5}, noisestdCell_C{2,6}; ...     % N = 6
                           noisestdCell_B{2,3}, noisestdCell_A{2,4}, noisestdCell_C{2,5}, noisestdCell_D{2,6}]; ... 
              
errorbar( 3:6, noiseFloor_stackedError(1,:), noiseStd_stackedError(1,:), '.', 'color', 'k', ...
         'LineWidth', 1.5)
errorbar( 3:6, noiseFloor_stackedError(2,:), noiseStd_stackedError(2,:), '.', 'color', 'k', ...
         'LineWidth', 1.5)
     
legend('N = 6','N = 2')
xlabel('Electrode')
ylabel('Noise Voltage (uV)')

%% Threshold plots
% Plot raw sorted events for 6 vs 2 slices
[~, totalChannels] = size(dataStructure_A);
sortedWaveforms_A = cell(1,16);
for ii = 17:totalChannels % skipping Riple data (1-16)
    sortedWaveforms_A{dataStructure_A(ii).electrode} = ...
        [ sortedWaveforms_A{dataStructure_A(ii).electrode}; dataStructure_A(ii).waveformSorted ];
end

sortedWaveforms_B = cell(1,16);
for ii = 17:totalChannels % skipping Riple data (1-16)
    sortedWaveforms_B{dataStructure_B(ii).electrode} = ...
        [ sortedWaveforms_B{dataStructure_B(ii).electrode}; dataStructure_B(ii).waveformSorted];
end

channelSelect = 4;
figure
for ii = 1:length(sortedWaveforms_A{channelSelect})
    plot(dataStructure_A(17).timeWave*(1e3), sortedWaveforms_A{channelSelect}(ii,:), 'Color', [.5 .5 .5])
    hold on
end
for ii = 1:length(sortedWaveforms_B{channelSelect})
    plot(dataStructure_A(17).timeWave*(1e3), sortedWaveforms_B{channelSelect}(ii,:), 'Color', [112 197 246]./256)
    hold on
end
ylim([-20 15])
ylabel('Amplitude (uV)')
xlabel('Time (ms)')


%% Background Noise plots
% Plots .15 s of spike filtered recordings for electrode 3 for 2 and
% 6 slice budgets
figure

% 2 slices
plot(dataStructure_B(17).time(13180:18805)- dataStructure_B(17).time(13180), dataStructure_B(17).filteredData(13180:18805), 'LineWidth', 2.0, 'Color', [.5 .5 .5])
hold on
% 6 slices
plot(dataStructure_A(21).time(35000:40600) - dataStructure_A(21).time(35000), dataStructure_A(21).filteredData(35000:40600), 'LineWidth', 2.0, 'Color', [112 197 246]./256)
ylim([-20 20])

xlabel('Time (s)')
ylabel('Amplitude (uV)')
legend('N = 2', 'N = 6')


