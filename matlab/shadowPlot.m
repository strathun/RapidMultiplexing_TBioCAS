function [meanVar,stdVar] = shadowPlot(figHandle,xData,yData,plotColor,plotType)
%UNTITLED2 Summary of this function goes here
%   This function will take in a data set and plot the mean with +/- 1
%   standard deviation as the shadow. NOTE: ANY VALUES <= 0 will be changed
%   to eps(). The fill function can't handle them on log scales.
%   figHandle; 
%       0 will grab current fig.
%   plotColor; 
%       must be in array or matrix. 
%   -make conditional for what sort of plot: semilog, loglog, plot. Use the
%   axis changing function, not semilogx, loglog, etc. in code. 


if figHandle == 0 
    figHandle = gcf;
end

colorShadow = brighten(plotColor,.3);
xData = real(xData);
yData = real(yData);
meanVar = mean(yData,2);
stdVar = std(yData,0,2);
stdVarl = meanVar - stdVar;
stdVarh = meanVar + stdVar;
% stdVarh(stdVarh<=0) = eps() ;
% stdVarl(stdVarl<=0) = eps() ;

[xTEST1, xTEST2] = size(xData);
if xTEST2 > xTEST1 
    xData = xData.';
end
figure(figHandle);
X=[xData.',fliplr(xData.')];
Y=[stdVarl.',fliplr(stdVarh.')];

if strcmp(plotType,'semilogx')
    set(gca,'XScale','log','YScale','linear')
elseif strcmp(plotType,'linear')
    set(gca,'XScale','linear','YScale','linear')
elseif strcmp(plotType,'loglog')
    set(gca,'XScale','log','YScale','log')
end

fill(X,Y,colorShadow,'LineStyle','none','FaceAlpha',.3);

end

