function plotRvsT(tempK, resistanceOhms, i)
%Emily Backus 
%Last Edited 10/06/09
%
colorVec = ['_','_','_','g','b','c','m','k','w','r','y'];
plot(tempK, resistanceOhms,colorVec(i+1));
xlabel('Temperature (K)');
ylabel('Resistance (\Omega)');
title(strcat('Rvs.T ',datestr(now)));
box on;