
% Sets relative filepaths from this script
currentFile = mfilename( 'fullpath' );
cd(fileparts(currentFile));
addpath(genpath('../matlab'));
addpath(genpath('../rawData'));

%% Prepares Impedance Predicted Noise Spectrum
[fImp, Zreal, Zim, Phase] = ...
    extractImpedanceDataGlobal('..\rawData\Mux\2019-05-31_TDTMoh_InVitro');
kT=300*1.38e-23;
Z = sqrt(Zreal.^2);
noiseImpArray = sqrt(4*kT*Z)*1e9;

figure
for ii = 1:8
semilogx(fImp(:,1,1), noiseImpArray(:,1,ii),'LineWidth',1.4)
hold on
end
grid on
xlabel('Frequency (Hz)')
ylabel('Spectrum (nV/rt(Hz)')
legend('1','2','3','4','5','6','7','8');

figure
for ii = 9:12
semilogx(fImp(:,1,1), noiseImpArray(:,1,ii),'LineWidth',1.4)
hold on
end
grid on
xlabel('Frequency (Hz)')
ylabel('Spectrum (nV/rt(Hz)')
legend('9','10','11','12');

figure
for ii = 13:16
semilogx(fImp(:,1,1), noiseImpArray(:,1,ii),'LineWidth',1.4)
hold on
end
grid on
xlabel('Frequency (Hz)')
ylabel('Spectrum (nV/rt(Hz)')
legend('13','14','15','16');