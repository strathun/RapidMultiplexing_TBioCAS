
clearvars 

% Sets relative filepaths from this script
currentFile = mfilename( 'fullpath' );
cd(fileparts(currentFile));
addpath(genpath('../matlab'));
addpath(genpath('../rawData'));


%% Prepares Impedance Predicted Noise Spectrum
[fImp1, Zreal1, Zim1, Phase1] = ...
    extractImpedanceDataGlobal('..\rawData\Gamry\2019-07-22_TDT19_Day03');
kT=300*1.38e-23;
Z1 = sqrt(Zreal1.^2);


[fImp2, Zreal2, Zim2, Phase2] = ...
    extractImpedanceDataGlobal('..\rawData\Gamry\2019-07-24_TDT19_Day05');
kT=300*1.38e-23;
Z2 = sqrt(Zreal2.^2);

for ii = 1:16
    figure(ii)
loglog(fImp1(:,1,ii),Z1(:,1,ii))
hold on
loglog(fImp1(:,1,ii),Z2(:,1,ii))
grid on
legend('Day 1','Day 2')
end