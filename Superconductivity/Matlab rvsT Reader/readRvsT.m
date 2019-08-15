function [tempK, resistanceOhms] = readRvsT(filename)
%Emily Backus 
%Last Edited 10/06/09
%
%[tempK, resistanceOhms] = readRvsT('August6MCS-Y9rvsT.txt');
%A = importdata(filename,delimiter,headerline) where headerline is a number
%that indicates on which line of the file the header text is located, 
%loads data from line headerline+1 to the end of the file.
%delimiter is the column separator

%gives a double array
%[data1] = textread(filename,'','delimiter','\t','headerlines',1);

%gives a structure array with fields 'data' 'textdata' and 'colheaders'
data2 = importdata(filename,'\t',1);
[r,c] = size(data2.data);
tempK = data2.data(1:r,1);
resistanceOhms = data2.data(1:r,2);
%appliedCurrent = data2.data(1:r,3);
