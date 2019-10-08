%% Seems like might be some potential here for finding multiple spikes.
% Should reevaluate for future spike sorting

close all

%% PCA
channel = 7;
% numWaves = length(dataStructure(channel).waveforms);
wf = dataStructure(channel).waveforms;
[coeff, score] = pca( wf );

%% K-means clustering
opts = statset('Display','final');
X = [score(:,1), score(:,2)];
[idx, C] = kmeans(X, 4, 'Distance', 'cityblock', ...
                  'Replicates',10,'Options', opts);
              
%% Plot

% figure
% for ii = 1:length(score)
%     if idx(ii) == 1
%         plot(dataStructure(1).waveforms(ii,:), 'k')
%     elseif idx(ii) == 2
%         plot(dataStructure(1).waveforms(ii,:), 'b')
%     elseif idx(ii) == 3
%         plot(dataStructure(1).waveforms(ii,:), 'r')
%     end
%     hold on
% end

for ii = 1:length(score)
    figure(idx(ii))
    plot(dataStructure(channel).waveforms(ii,:), 'k')
    hold on
end

% % At least two suspected waveforms for channel 1
% figure
% plot(dataStructure(1).waveforms(67,:), 'k')
% hold on
% plot(dataStructure(1).waveforms(7,:), 'k')