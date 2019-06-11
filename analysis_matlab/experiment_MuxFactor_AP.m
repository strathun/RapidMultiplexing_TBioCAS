%% Experiment: Mux Factor and AP Shape
% Here, I'm looking to see if there are any apparent trends/effects of mux
% factor on the shape of the detected threshold crossing events. 

close all 
clearvars 

% Sets relative filepaths from this script
currentFile = mfilename( 'fullpath' );
[ outputDir ] = initializeScript( currentFile );

%%
% All the recordings used to generate these files are listed below:
%
%%%
muxFileNameArray    = {'2019_5_29_12_33_20_1_2097152_15_smpls_raw.mat';
                       '2019_5_29_12_5_30_2_2097152_15_8_smpls_raw.mat';
                       '2019_5_29_12_36_8_4_2097152_15_8_7_0_smpls_raw.mat';
                       '2019_5_29_12_38_2_8_2097152_15_8_7_0_2_5_1_6_smpls_raw.mat';
                       '2019_5_29_11_59_48_16_2097152_3_4_5_2_1_6_0_7_15_8_9_14_13_10_11_12_smpls_raw.mat';
                       '2019_5_29_11_53_53_20_2097152_3_4_5_2_1_6_0_7_15_8_9_14_13_10_11_12_3_4_5_2_smpls_raw.mat'};
hpCornerFreq   =  750;
lpCornerFreq   = 4000;
dataStructureOffset = 0; % Prevents new data from overwriting prev. recording
legend_cell{17} = 0;   % for generating correct legend on plots

for jj = 1:length( muxFileNameArray )
muxFileName = muxFileNameArray{ jj };
[muxChannelOrder] = muxChannelGrabber( muxFileName ); % Gets channels from filename
[muxChannelOrder] = channelMatcher( muxChannelOrder, 'Mux', 'Ripple' ); % Converts to Ripple index
numChannelsMux = length( muxChannelOrder );
[ Vordered, timeMux, FsMux ] = ...
    muxGetRaw( muxFileName, 600e3, numChannelsMux, 'downSampleOffset',0, ...
               'downSampleTrigger', 1, 'averageSampleTrigger', 0 );
VMux = meanSubtraction( Vordered );   % Remove DC offsets
% VMux = comAvgRef(Vordered);
% VMux = Vordered;

% Next, filter the data. 
% First we run a first order low pass filter at 4.9 kHz to approximate the
% bandwidth of the Ripple. Then apply spike filter.
[ dataFiltMux ] = singlePoleAnalogFilt(VMux, FsMux, 4.9e3);
[ dataFiltMux ] = filterFunc(dataFiltMux, FsMux, 3, ...
               'highPassCorner', hpCornerFreq, ...
               'lowPassCorner', lpCornerFreq);

% Then, spike sorting
threshold = -3.5;   % rms multiplier for threshold crossing
[waveform_sorted_cell, timeWave] = spikeSortSuite(dataFiltMux, threshold, ...
                         FsMux, 'absRefractoryPeriod', .001);         
    for ii = 1:numChannelsMux
        dataStructure(ii + dataStructureOffset).filteredData = dataFiltMux(ii,:);
        dataStructure(ii + dataStructureOffset).Fs = FsMux;
        dataStructure(ii + dataStructureOffset).electrode = muxChannelOrder(ii);
        dataStructure(ii + dataStructureOffset).time = timeMux;
        dataStructure(ii + dataStructureOffset).waveforms = waveform_sorted_cell{ii};
        dataStructure(ii + dataStructureOffset).timeWave = timeWave;
        dataStructure(ii + dataStructureOffset).fileName = muxFileName;
        dataStructure(ii + dataStructureOffset).muxFactor = numChannelsMux;
        
       meanWave = mean( waveform_sorted_cell{ii} );
       figure(dataStructure(ii + dataStructureOffset ).electrode)
       legend_cell{dataStructure(ii + dataStructureOffset ).electrode} = ...
           [ legend_cell{dataStructure(ii + dataStructureOffset ).electrode}; ...
           dataStructure(ii + dataStructureOffset ).muxFactor ];
       plot(dataStructure( ii + dataStructureOffset ).timeWave, meanWave, ...
            'LineWidth', 1.5)
       hold on
       titleStr = sprintf('Electrode_%d', ...
                          dataStructure(ii + dataStructureOffset ).electrode );
       title(titleStr, 'Interpreter', 'none')
       xlabel('Time (ms)')
       ylabel('Amplitude (uV)')
       ylim([-80 40])
    end
    dataStructureOffset = dataStructureOffset + numChannelsMux;
end

for ii = 1:16
   legendString = regexp(sprintf('M=%d#', legend_cell{ii}), '#', 'split');
   legendString(end) = []; 
   figure(ii)
   hLegend = legend( legendString );
   title(hLegend, 'Multiplexing Factor')
end
%%
% First pass is without averaging or decimation, just subsampling. Without
% doing anything too analytical, there doesn't seem to be any really
% obvious trends that may not be resulting from simple variations in 
% waveforms from one recording to another. 
