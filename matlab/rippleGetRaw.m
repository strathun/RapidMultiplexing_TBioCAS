function [ VRipple, timeRipple ] = rippleGetRaw( rippleFileName )
%[ VRipple, timeRipple ] = rippleGetRaw( rippleFileName )
% This is just to make a block I was using repeatedly more compact. It
% essentially just calls the NSxGetMemMapFile function, generates a time
% vector, converts the voltage data to double format and corrects for the
% .25 uV per bit Ripple uses. 
%   Inputs:
%       rippleFileName: Filename of recording to be analyzed. Must be
%                       string with .ns5 extension.
%   Outputs:
%       VRipple       : Time domain voltage data matrix. Each row will be a
%                       channel.
%       timeRipple    : Time vector
%%
% Ripple Data. Ripple uses .25 uV per bit. Data comes in as bits. Here
% we're leaving units as uV [mini function candidate]
[ NSxFileArray, NSxbasicHeader, NSxchannelHeader, NSxTimeStamps ] = ...
    NSxGetMemMapFile( rippleFileName );
rawdata = NSxFileArray.Data.NSxData;
V = double( rawdata );
timeRipple = double( NSxTimeStamps ) / 30000;
VRipple = ( V  )/4;
end

