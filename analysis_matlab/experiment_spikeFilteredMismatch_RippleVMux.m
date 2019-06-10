%% Investigating Source of High Noise Floor
% The newer recordings we've made seem to have a much higher noise floor
% than those we published in the MDPI paper. Specifically, I'm referring to
% the fact that we no longer see very close agreement between the
% spike-filtered time domain data of the Mux and Ripple, like we did with
% the MDPI data.

close all
clearvars 

% Sets relative filepaths from this script
currentFile = mfilename( 'fullpath' );
cd(fileparts(currentFile));
addpath(genpath('../matlab'));
addpath(genpath('../rawData'));

%%
% As a quick preliminary test to make sure the changes don't have to do
% with changes we've made to the data processing steps, I'm going to load
% the old data we used for MDPI with our new scripts. For the paper, we
% looked specifically at time 10.2 - 13.9 seconds. For simplicity, I'm
% going to load the whole file and then set the figure window to this time
% window. 


%%
% First, load the data.
muxFileName    = '2018_8_29_15_35_37_8388608_smpls_raw.mat';
numChannelsMux =    2;
analysisWindwo = [10.2 13.9]; % Time in seconds to be analyzed
hpCornerFreq   =  750;
lpCornerFreq   = 4000;

[ Vordered, timeMux, FsMux ] = ...
    muxGetRaw( muxFileName, 600e3, numChannelsMux, ...
    'downSampleOffset', 0, ...
    'timeWindow', [10.2 13.9]);
% VMux = meanSubtraction(Vordered);   % Remove DC offsets
% VMux = comAvgRef(Vordered);
VMux = Vordered;

%%
% Next, filter the data. 
% First we run a first order low pass filter at 4.9 kHz to approximate the
% bandwidth of the Ripple. Then apply spike filter as above.
[ dataFiltMux ] = singlePoleAnalogFilt(VMux, FsMux, 4.9e3);
[ dataFiltMux ] = filterFunc(dataFiltMux, FsMux, 3, ...
               'highPassCorner', hpCornerFreq, ...
               'lowPassCorner', lpCornerFreq);
for ii = 1:numChannelsMux
    dataStructure(ii).filteredData = dataFiltMux(ii,:);
    dataStructure(ii).Fs = 37.5e3;
    dataStructure(ii).instrument = 'Mux';
    dataStructure(ii).electrode = ii;
    dataStructure(ii).time = timeMux;
    figure(1)
    subplot(2,1,ii)
    plot(dataStructure(ii).time, dataStructure(ii).filteredData)
    xlabel('Time (s)')
    ylabel('Amplitude (uV)')
end

%%
% There are some minor differences between this particular plot and what
% was printed in MDPI, but we're also using slightly different filter
% settings (and different filter), so I'm making the potentially dangerous
% assumption that what we're seeing with these new datasets is not just
% because of new signal processing techniques.
%%
% Something else that needs to be systematically looked into, is the effect
% of common average referencing and if maybe there is a better method than
% what I'm currently using. 

%%
% Next, I'm going to look into whether or not it had
% to do with the low multiplexing factor (2 channels) we were using
% previously. Unfortunately, I can't really dig into this one yet since the
% lowest we've gone recently is 8. 