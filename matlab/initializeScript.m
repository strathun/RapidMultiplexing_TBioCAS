function [ outputDir ] = initializeScript( currentFile )
%[ outputDir ] = initializeScript( currentFile )
%   This is a simple function meant to be run at the beginning of analysis
%   scripts to set up relative filepaths as well as make an output
%   directory.
%   Inputs :
%       currentFile: Full path of the current script
%   Output : 
%       outputDir:   location of the newly created directory for outputs
%                    generated from the script in which this was called.

cd(fileparts(currentFile));
addpath(genpath('../matlab'));
addpath(genpath('../rawData'));
addpath(genpath('../output'));
parts = strsplit(currentFile, {'\', '\'});
outputDir = ['../output/' parts{end}];
[~, ~] = mkdir(outputDir);
end

