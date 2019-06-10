%% Experiment: Oversampling, downsampling, averaging, decimation
% This experiment is to help determine the best way to handle any data that
% is less than 16 or 20 channels. 

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
% 2019_5_29_12_36_8_4_2097152_15_8_7_0_smpls_raw
% 2019_5_29_12_0_53_8_2097152_15_8_7_0_2_5_1_6_smpls_raw

muxFileName    = '2019_5_29_12_0_53_8_2097152_15_8_7_0_2_5_1_6_smpls_raw.mat';
hpCornerFreq   =  750;
lpCornerFreq   = 4000;

% Mux Data
[muxChannelOrder] = muxChannelGrabber(muxFileName); % Gets channels from filename
[muxChannelOrder] = channelMatcher( muxChannelOrder, 'Mux', 'Ripple'); % Converts to Ripple index
numChannelsMux = length(muxChannelOrder);

if mod(20, numChannelsMux) == 0
    decimationFactor = 20/numChannelsMux;
else
    decimationFactor = 16/numChannelsMux;
end
%%
% We need to create two separate data sets, one with downsampling and the
% other without. 

[ Vordered, timeMux, FsMux ] = ...
    muxGetRaw( muxFileName, 600e3, numChannelsMux, 'downSampleOffset',0, ...
               'downSampleTrigger', 1, 'averageSampleTrigger', 0);
[ Vordered_DS, timeMux_DS, FsMux_DS ] = ...
    muxGetRaw( muxFileName, 600e3, numChannelsMux, 'downSampleOffset',0, ...
               'downSampleTrigger', 0, 'averageSampleTrigger', 1);
[ Vordered_PreDec, timeMux_Dec, FsMux_Dec ] = ...
    muxGetRaw( muxFileName, 600e3, numChannelsMux, 'downSampleOffset',0, ...
               'downSampleTrigger', 0, 'averageSampleTrigger', 0);
for ii = 1:numChannelsMux
    Vordered_Dec(ii,:) = decimate( Vordered_PreDec(ii,:), decimationFactor );
end
VMux = meanSubtraction(Vordered);   % Remove DC offsets
VMux_DS = meanSubtraction(Vordered_DS);   % Remove DC offsets
VMux_Dec = meanSubtraction(Vordered_Dec);   % Remove DC offsets
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
[ dataFiltMux_Dec ] = singlePoleAnalogFilt(VMux_Dec, FsMux_DS, 4.9e3);
[ dataFiltMux_Dec ] = filterFunc(dataFiltMux_Dec, FsMux_DS, 3, ...
               'highPassCorner', hpCornerFreq, ...
               'lowPassCorner', lpCornerFreq);
for ii = 1:numChannelsMux*3
    if ii < (numChannelsMux) + 1
        dataStructure(ii).filteredData = dataFiltMux(ii,:);
        dataStructure(ii).Fs = FsMux;
        dataStructure(ii).electrode = muxChannelOrder(ii);
        dataStructure(ii).time = timeMux;
        subFigSelect = 1;
    elseif ii < (numChannelsMux * 2) + 1
        dataStructure(ii).filteredData = dataFiltMux_DS(ii-numChannelsMux,:);
        dataStructure(ii).Fs = FsMux_DS;
        dataStructure(ii).electrode = muxChannelOrder(ii-numChannelsMux);
        dataStructure(ii).time = timeMux_DS;
        subFigSelect = 2;
    else 
        dataStructure(ii).filteredData = dataFiltMux_Dec(ii-( numChannelsMux * 2),:);
        dataStructure(ii).Fs = FsMux_DS;
        dataStructure(ii).electrode = muxChannelOrder(ii-( numChannelsMux * 2) );
        dataStructure(ii).time = timeMux;
        subFigSelect = 3;
    end
        
   figure(dataStructure(ii).electrode)
   subplot(3,1,subFigSelect)
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
% There does not seem to a whole lot of difference between the averaging
% and the proper decimation technique. 