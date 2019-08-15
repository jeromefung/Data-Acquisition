% ThermalConductivityDataCollection.m 
% analyses the output data from the thermal_conductivity function 
% inputs are:
%   sampleRate - 
%   shortTime  - number of minutes for the test run (ex: 15)
%   longTime   - number of minutes for the full run (ex: 90)
% outputs are: 
%   shortTest  -  linear array of voltage data
%   longTest   -  linear array of voltage data 
%   Vs         -  steady state voltage
%   Figure 1   -  natural log graph of short_test
%   Figure 2   -  raw data plot of entire run
%   Figure 3   -  graph of ln(V-Vs) against time in seconds
%
% ex:  [shortData, longData, steadyStateV] = ThermalConductivityDataCollectionEmily(1000,15,90)
function [shortTestAvg, longTestAvg, Vs] = ThermalConductivityLab(sampleRate, shortTime, longTime)
% Script Written by Rhea Hanrahan 10/30/2008
% Edited by MCS 1/6/09, Converted to a function by Emily Backus 7/17/12 

input('Press Enter when you are ready to collect data for the short test: ');
[shortTest, timedata] = thermal_conductivity(sampleRate,shortTime*60); %linear array of voltage data
plot(shortTest) %uncomment this line to check experiment after short run
[longTest, timedata2] = thermal_conductivity(sampleRate,longTime*60);%take data


% flipData = input('Are your voltages in figure 1 negative? Y/[N]: ','s');
% if strcmp(flipData,'Y')
%     disp('Ok, this will be fixed in the full data run.')
%     shortTest = -1*shortTest;
%     input('Press Enter when you are ready to collect data for the full test: ');
%     longTest = thermal_conductivity(sampleRate,longTime*60);%take data
%     longTest = -1*longTest;
% else
%     input('Press Enter when you are ready to collect data for the full test: ');
%     [longTest, timedata2] = thermal_conductivity(sampleRate,longTime*60);%take data
% end

%close all   %close all open figures
shortTestAvg = averageData(shortTest,sampleRate);  %average data every 1000 pts
figure(1)  %plot the natural log of voltage vs seconds
plot(log(shortTestAvg)) %Take the natural log of the data and plot it
title('ln(Voltage) vs. Time (s): Short test');
xlabel('Time (s)');
ylabel('ln(Voltage)');

longTestAvg=averageData(longTest,sampleRate);  %average data every 1000 pts
figure(2)  %plot of all raw data, notice the steady state voltage (compare to Vs)
plot([shortTestAvg';longTestAvg'])
title('Voltage (V) vs. Time (s): All data');
xlabel('Time (s)');
ylabel('Voltage');

length = size(longTestAvg,2);
%steady state voltage (average of last few values in long_test_ave array)
Vs = sum(longTestAvg((length-(shortTime*60/20)):length))/(shortTime*60/20);  

short = shortTestAvg-Vs;
long = longTestAvg-Vs;
all = [short';long'];
lnAll = log(all);
figure(3)  %graph of ln(V-Vs) against time in seconds for entire run
%plot(lnAll(1:45*60)); %plots first 45 minutes of the data.
title('ln(V-V_s) vs. Time (s): All data');
xlabel('Time (s)');
ylabel('ln(V-V_s)');
end
function out = averageData(vector, len)
%Averaging vectors script
%Maksim Sipos, Thursday January 26, 2006
%Feel free to use this script and/or modify it as needed!

out = [];

if mod(length(vector), len) ~= 0
    error 'Length of vector must be an integer multiple of averaging interval'
end

%Number of resulting data points (each interval is averaged out)
num_of_intervals = length(vector)/len;

%do the actual averaging
for i = 1:num_of_intervals
    out(i)= sum(vector(((i-1)*len+1):(i*len)))/len;
end

end
