%% Plotscript: High Frequency Noise with Tye's Circuit
% Here we were trying to understand the source of the unexpected noise in
% the multiplexing recordings. To do this, we took measurements with
% different levels of shielding and activity from the Mux, at higher
% frequencies with Tye's boards. Measurements were taken using compileSpans
% and the Agilent and removing the original low frequency span and adding a
% third thigh frequency span that went up to 600e3 Hz
%%
% NOTE: Because these measurements were taken at much higher frequencies,
% than the old board ground measurements, they have not been deembedded.
% Also the gain has not been factored out.

% Initialize and set relative filepaths FROM THIS script
close all 
clearvars 
currentFile = mfilename( 'fullpath' );
cd(fileparts(currentFile));
addpath(genpath('../matlab'));
[ outputDir ] = initializeScript( currentFile );

%%
% First, let's look at the effect of grounding the PXIe output to earth
% ground.

load('2019-06-24_15hr_16min_03sec_elec_1110_HSonly_Av767_HS.mat')
highSpanNoGnd = y(3,:);
freqSpan = x(3,:);
load('2019-06-24_15hr_37min_07sec_elec_1110_HSonly_Av767_HS.mat')
highSpanGnd = y(3,:);

figure
plot( freqSpan, highSpanNoGnd )
hold on
plot( freqSpan, highSpanGnd )
ylabel('V/rt(Hz)')
xlabel('Frequency (Hz)')
legend('NoGnd', 'Gnded')

%%
% From this plot, we see that grounding at the output of the PXIe had a
% pretty significant effect on these high frequency noise sources.
% Interestingly, this same grounding configuration didn't seem to have much
% of an effect on the noise when Mohit recreated this setup and then tried
% multiplexing. 


