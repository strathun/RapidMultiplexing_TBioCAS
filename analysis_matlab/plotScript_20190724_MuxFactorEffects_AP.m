%% PlotScript: MuxFactor_Ap
% This is to plot the mean waveform of two electrodes averaged across
% approximately 35 seconds of mux data at 1, 4, 8 and 10 mux factor
% respectively. Data was generated/saved from scripts in the filenames 
% below.

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
% 1x
figNum = 4;
figure(figNum)
load('../output/plotScript_RippleVsMuxAP_multiMux_20190724_1x_firstR_E02/muxAPCellArray.mat')
load('../output/plotScript_RippleVsMuxAP_multiMux_20190724_1x_firstR_E05/timeWave20.mat')
plot(timeWave20*1e3, mean(muxAPCellArray{figNum}), 'LineWidth', 3.5)
hold on

% 1x
figNum = 3;
figure(figNum)
load('../output/plotScript_RippleVsMuxAP_multiMux_20190724_1x_firstR_E05/muxAPCellArray.mat')
load('../output/plotScript_RippleVsMuxAP_multiMux_20190724_1x_firstR_E05/timeWave20.mat')
plot(timeWave20*1e3, mean(muxAPCellArray{figNum}), 'LineWidth', 3.5)
hold on

% 4x
load('../output/plotScript_RippleVsMuxAP_multiMux_20190724_4x_firstR/muxAPCellArray.mat')
load('../output/plotScript_RippleVsMuxAP_multiMux_20190724_1x_firstR_E05/timeWave20.mat')
for ii = 3:4
    figure(ii)
    plot(timeWave20*1e3, mean(muxAPCellArray{ii}), 'LineWidth', 3.5)
end

% 8x
load('../output/plotScript_RippleVsMuxAP_multiMux_20190724_8x_secondR/muxAPCellArray.mat')
load('../output/plotScript_RippleVsMuxAP_multiMux_20190724_8x_secondR/timeWave16.mat')
for ii = 3:4
    figure(ii)
    plot(timeWave16*1e3, mean(muxAPCellArray{ii}), 'LineWidth', 3.5)
end

% 10x
load('../output/plotScript_RippleVsMuxAP_multiMux_20190724_10x_secondR/muxAPCellArray.mat')
load('../output/plotScript_RippleVsMuxAP_multiMux_20190724_1x_firstR_E05/timeWave20.mat')
for ii = 3:4
    figure(ii)
    plot(timeWave20*1e3, mean(muxAPCellArray{ii}), 'LineWidth', 3.5)
    xlabel('Time (ms)')
    ylabel('Amplitude (uV)')
    hleg = legend('1', '4', '8', '10');
    title(hleg, 'Mux Factor')
end



