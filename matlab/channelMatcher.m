function [outChannelOrder] = channelMatcher( inChannelOrder, fromInst, toInst)
%[muxChannelOrderNew] = channelMatcher( muxChannelOrder, fromInst, toInst)
%   Will reindex channels to make sure you're looking at the same electrode
%   when comparing two different instruments. Currently just works for
%   going from Mux to Ripple
%   Inputs:
%       inChannelOrder: array with channel order of device to be reindexed
%       fromInst      : String. Name of device to be converted
%       toInst        : String. Name of device to convert to

rippleIndex = [01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16];
muxIndex =    [04 03 05 02 06 01 07 00 08 15 09 14 10 13 11 12];
if strcmp(fromInst,'Mux') && strcmp(toInst,'Ripple')
    for ii = 1:length(inChannelOrder)
        globalIndex = find(muxIndex == inChannelOrder(ii));
        outChannelOrder(ii) = rippleIndex(globalIndex);
    end
end

end

