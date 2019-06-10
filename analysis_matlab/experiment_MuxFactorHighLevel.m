%% Investigating high level effects of Mux Factor
% This experiment will look at things like raw and filtered time domain
% data of recordings done at different multiplexing levels. 

clearvars 

% Sets relative filepaths from this script
currentFile = mfilename( 'fullpath' );
cd(fileparts(currentFile));
addpath(genpath('../matlab'));
addpath(genpath('../rawData'));

%% Load data
% Will be looking at data recorded from the same day at different mux
% factors. These channels were chosen by examining the multiplexed data
% (viewMohit) and looking for waveforms that did not have any obvious
% railing.

%% 
% Mux Factor of 2
[ Vordered, time, ~ ] = ...
    muxGetRaw( '2019_5_15_12_22_33_2_2097152_14_15_smpls_raw.mat', ...
    600e3, 2, 'downSampleOffset',0 );
VorderedMF2 = meanSubtraction(Vordered);

figure(1)
plot(time,VorderedMF2)

%% 
% Mux Factor of 4
[ Vordered, time, ~ ] = ...
    muxGetRaw( '2019_5_15_12_12_0_4_2097152_13_14_9_5_smpls_raw.mat', ...
    600e3, 4, 'downSampleOffset',0 );
VorderedMF4 = meanSubtraction(Vordered);

figure(2)
plot(time,VorderedMF4)
