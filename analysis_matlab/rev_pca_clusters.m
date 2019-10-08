%% Showing poor clusters
% Must run rev_results_RippleVsMux_actionPotentials.m first
close all

%% PCA
for ii = 1:10
    figure
    wf = dataStructure(ii).waveforms;
    [coeff, score] = pca( wf );
    scatter(score(:,1), score(:,2), '.')
    xlabel('PC1')
    ylabel('PC2')
end

