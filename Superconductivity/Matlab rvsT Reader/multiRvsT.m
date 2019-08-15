function multiRvsT(folder)
%Emily Backus 
%Last Edited 10/06/09
%
%get contents of folder
list = dir(folder);
%go through contents one by one and plot rvsT graphs
hold on
for i = 3:length(list)
    filename = [folder,'/',list(i).name];
    [tempK, resistanceOhms] = readRvsT(filename);
    plotRvsT(tempK, resistanceOhms, i);  
    legendList{i-2} = filename;
    legend(legendList);
end
hold off
