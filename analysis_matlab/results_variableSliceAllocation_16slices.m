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

%% Plots
[~, numWavePoints] = size(dataStructureMuxCumAP_A(1).meanWave);
timeWave = (1:1:numWavePoints)./(37.5);
colorWheel_A = [  0  0  1;
                 .5 .5 .5;
                  0  0  1;
                 .5 .5 .5 ];    % high slice number = blue, lower = grey
[~, numChannels] = size(dataStructureMuxCumAP);
for ii = 1:(numChannels)
    figure(dataStructureMuxCumAP_A(ii).electrode)
    shadowPlot(gcf,timeWave.',dataStructureMuxCumAP_A(ii).waveformSorted.',colorWheel_A(ii,:),'linear')
    hold on
end

colorWheel_B = [ .5 .5 .5;
                  0  0  1;
                 .5 .5 .5;
                  0  0  1];    % high slice number = blue, lower = grey
for ii = 1:(numChannels)
    figure(dataStructureMuxCumAP_B(ii).electrode)
    shadowPlot(gcf,timeWave.',dataStructureMuxCumAP_B(ii).waveformSorted.',colorWheel_B(ii,:),'linear')
    hold on
ylim([ -20 20])
ylabel('Amplitude (uV)')
xlabel('Time (ms)')
end

%% Noise floor analysis

[~, totalChannels] = size(dataStructure_A);
noiseFloorCell_A = cell(1,16);
for ii = 17:totalChannels % skipping Riple data (1-16)
    noiseFloorCell_A{dataStructure_A(ii).electrode} = ...
        [ noiseFloorCell_A{dataStructure_A(ii).electrode} dataStructure_A(ii).noiseFloor];
end
noiseFloorCell_B = cell(1,16);
for ii = 17:totalChannels % skipping Riple data (1-16)
    noiseFloorCell_B{dataStructure_B(ii).electrode} = ...
        [ noiseFloorCell_B{dataStructure_B(ii).electrode} dataStructure_B(ii).noiseFloor];
end

% Calculate mean noise floor for all six recordings
for ii = 1:16
    noiseFloorCell_A{2,ii} = mean(noiseFloorCell_A{1,ii});
    noiseFloorCell_B{2,ii} = mean(noiseFloorCell_B{1,ii});
end

%% Unused plots
% for ii = 1:(numChannels)
%     figure(dataStructureMuxCumAP_A(ii).electrode)
%     [numTraces, ~] = size(dataStructureMuxCumAP_A(ii).waveformSorted);
%     for jj = 1:numTraces
%         plot(timeWave, dataStructureMuxCumAP_A(ii).waveformSorted(jj,:),'k')
%         hold on
%     end
% end
% 
% for ii = 1:(numChannels)
%     figure(dataStructureMuxCumAP_B(ii).electrode)
%     [numTraces, ~] = size(dataStructureMuxCumAP_B(ii).waveformSorted);
%     for jj = 1:numTraces
%         plot(timeWave, dataStructureMuxCumAP_B(ii).waveformSorted(jj,:),'')
%         hold on
%     end
% end

% for ii = 1:(numChannels)
%     figure(dataStructureMuxCumAP_A(ii).electrode)
%     plot(timeWave, dataStructureMuxCumAP_A(ii).meanWave,'k', 'LineWidth', 3.5)
%     hold on
%     plot(timeWave, dataStructureMuxCumAP_A(ii).highTrace, 'k', 'LineWidth', 3.5)
%     plot(timeWave, dataStructureMuxCumAP_A(ii).lowTrace, 'k','LineWidth', 3.5)
% end
% 
% for ii = 1:(numChannels)
%     figure(dataStructureMuxCumAP_B(ii).electrode)
%     plot(timeWave, dataStructureMuxCumAP_B(ii).meanWave, 'b','LineWidth', 3.5)
%     hold on
%     plot(timeWave, dataStructureMuxCumAP_B(ii).highTrace, 'b','LineWidth', 3.5)
%     plot(timeWave, dataStructureMuxCumAP_B(ii).lowTrace, 'b','LineWidth', 3.5)
% end