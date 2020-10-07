%% plotScript: For Thesis Proposal
% Adapted from plotScript_RippleAPAll

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
rippleFileName = 'SD190719A_SurgeryInsertion_20190719_1.ns5';
hpCornerFreq   =  750;
lpCornerFreq   = 4000;

% Ripple Data. Ripple uses .25 uV per bit. Data comes in as bits. Here
% we're leaving units as uV [mini function candidate]
[ NSxFileArray, NSxbasicHeader, NSxchannelHeader, NSxTimeStamps ] = ...
    NSxGetMemMapFile( rippleFileName );
rawdata = NSxFileArray.Data.NSxData;
V = double( rawdata );
timeRipple = double( NSxTimeStamps ) / 30000;
VRipple = ( V  )/4;

%% Filter Data
% Data from both instruments is stored in a single data structure to allow
% a single for loop to take care of all the spike sorting below. 
% Ripple. 
[ dataFiltRipple ] = filterFunc(VRipple, 30e3, 3, ...
               'highPassCorner', hpCornerFreq, ...
               'lowPassCorner', lpCornerFreq);
[numChannelsRip, ~] = size(dataFiltRipple);
for ii = 1:numChannelsRip
    dataStructure(ii).rawData = VRipple(ii,:);
    dataStructure(ii).filteredData = dataFiltRipple(ii,:);
    dataStructure(ii).Fs = 30e3;
    dataStructure(ii).instrument = 'Ripple';
    dataStructure(ii).electrode = ii;
    dataStructure(ii).time = timeRipple;
    dataStructure(ii).threshColor = [.5 .5 .5];
end

%% Plots
figure(1)
plot(dataStructure(2).time,dataStructure(2).rawData)
xlim([9.1 12])
ylim([-300 300])
ylabel('Voltage (uV)')
xlabel('Time (s)')

figure(2)
plot(dataStructure(2).time,dataStructure(2).rawData)
xlim([10.3 10.8])
ylim([-300 100])
ylabel('Voltage (uV)')
xlabel('Time (s)')

figure(3)
plot(dataStructure(2).time,dataStructure(2).rawData)
xlim([10.510 10.543])
ylim([-300 100])
ylabel('Voltage (uV)')
xlabel('Time (s)')

figure(4)
plot(dataStructure(2).time,dataStructure(2).rawData, 'LineWidth', 1.5)
xlim([10.524 10.53])
ylim([-130 -40])
ylabel('Voltage (uV)')
xlabel('Time (s)')