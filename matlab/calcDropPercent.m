%% 

for ii = 1:10
    numUnsorted(ii) = length(dataStructure(ii).waveforms);
    numSorted(ii)   = length(dataStructure(ii).waveformSorted);
    percentDrop(ii)     = (numUnsorted(ii) - numSorted(ii)) / numUnsorted(ii);
end
