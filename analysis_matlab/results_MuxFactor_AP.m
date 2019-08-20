%% Results: Mux Factor V Ap
% Loaded data was generated on 20190724 from:
%   filenames in the load scripts below

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

%% Load Data

% E04 (Ripple) 1x 
load('..\output\plotScript_RippleVsMuxAP_multiMux_20190724_1x_firstR_E02\muxAPCellArray_ripThresh.mat')
muxAPCellArray_E04_1 = muxAPCellArray;

load('..\output\plotScript_RippleVsMuxAP_multiMux_20190724_1x_firstR_E05\muxAPCellArray_ripThresh.mat')
muxAPCellArray_E03_1 = muxAPCellArray;

load('..\output\plotScript_RippleVsMuxAP_multiMux_20190724_4x_firstR\muxAPCellArray_ripThresh.mat')
muxAPCellArray_4 = muxAPCellArray;

load('..\output\plotScript_RippleVsMuxAP_multiMux_20190724_10x_secondR\muxAPCellArray_ripThresh.mat')
muxAPCellArray_10 = muxAPCellArray;

% Time trace for plots
load('..\output\plotScript_RippleVsMuxAP_multiMux_20190724_1x_firstR_E05\timeWave20.mat')

%% Plot
% Plot 1x
close all 

colorPallet = [ 4  29 119;
               90 151 187;
               69 183 211]./256;
               
figure(4)
plot(timeWave20, mean(muxAPCellArray_E04_1{1,4}), 'LineWidth', 2.5, 'color','k')%'color', colorPallet(1,:))
hold on

figure(3)
plot(timeWave20, mean(muxAPCellArray_E03_1{1,3}), 'LineWidth', 2.5, 'color','k')%'color', colorPallet(1,:))
hold on
% Plot Rest
for ii = 3:4
    figure(ii)
       plot(timeWave20, mean(muxAPCellArray_4{1,ii}), '--', 'LineWidth', 2.5, 'color','k') %'color', colorPallet(2,:))
       plot(timeWave20, mean(muxAPCellArray_10{1,ii}), ':', 'LineWidth', 2.5, 'color','k') %'color', colorPallet(3,:))
end