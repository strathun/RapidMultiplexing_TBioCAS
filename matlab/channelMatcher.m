function [outChannelOrder] = channelMatcher( inChannelOrder, fromInst, toInst)
%[muxChannelOrderNew] = channelMatcher( muxChannelOrder, fromInst, toInst)
%   Will reindex channels to make sure you're looking at the same electrode
%   when comparing two different instruments. Currently just works for
%   going from Mux to Ripple
%   Inputs:
%       inChannelOrder: array with channel order of device to be reindexed
%       fromInst      : String. Name of device to be converted
%       toInst        : String. Name of device to convert to
%   Possible Device Names: 'Ripple', 'Mux', 'Tye'

rippleIndex = [01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16];
muxIndex =    [04 03 05 02 06 01 07 00 08 15 09 14 10 13 11 12];
tyeIndex =    [08 16 07 15 06 14 05 13 04 12 03 11 02 10 01 09];
if strcmp(fromInst,'Mux') && strcmp(toInst,'Ripple')
    for ii = 1:length(inChannelOrder)
        globalIndex = find(muxIndex == inChannelOrder(ii));
        outChannelOrder(ii) = rippleIndex(globalIndex);
    end
elseif strcmp(fromInst,'Tye') && strcmp(toInst,'Ripple')
    for ii = 1:length(inChannelOrder)
        globalIndex = find(tyeIndex == inChannelOrder(ii));
        outChannelOrder(ii) = rippleIndex(globalIndex);
    end
elseif strcmp(fromInst,'Ripple') && strcmp(toInst,'Tye')
    for ii = 1:length(inChannelOrder)
        globalIndex = find(rippleIndex == inChannelOrder(ii));
        outChannelOrder(ii) = tyeIndex(globalIndex);
    end
end

end

