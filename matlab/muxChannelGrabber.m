function [elecNumbers] = muxChannelGrabber(muxFileName)
%[elecNumbers] = muxChannelGrabber(channelString)
%   Grabs channel names from filename. 
%   Input:
%       muxFileName: Needs to be a string

elecIndex = strfind(muxFileName,'_');
stringSpacing = diff(elecIndex);
stringSpacing = find( stringSpacing > 3 );
elecIndex = elecIndex( ( stringSpacing(1) + 1 ): ( stringSpacing(2) ) );
for ii = 1:( length(elecIndex) - 1 )
    startIndex = elecIndex(ii) + 1;
    stopIndex  = elecIndex(ii+1) - 1;
    elecNumbers(ii) = str2num(muxFileName(startIndex:stopIndex));
end

