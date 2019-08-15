 function result=getHeatFlowData(pulsetime, dataduration);
% Written by B.G. Thompson.
% Edited MCS February 2015 for Matlab session interface.
% Edited MCS June 2016 to add third and fourth thermistor
% Edited MCS January 2017 to add input voltage, V_0 for voltage divider
% function to send a pulse for the number of seconds given
%   by pulsetime and gather data from the thermistors
%   for the number of seconds dataduration.
% Uses the NIDAQ Data Aquisition Board.
% Wire DAC0_OUT to the pulse FET and also to the input
%   channel ACH0.
% Channel 0 takes the heater voltage.
% Channel 1 takes the input to the thermometer circuit
% Wire Analog Input channels 2 through 5 to the outputs of the thermistor
%   circuits.
% Returns data for three channels in rawData at the times timeData.
SR = 100;
NSAO = floor(pulsetime * SR);
NSAI = floor(dataduration * SR);
% set up analog input
%This uses the Session-based interface.  MCS Jan 2015
s = daq.createSession('ni');
addAnalogInputChannel(s,'Dev1',[0:5], 'Voltage');
s.Channels(1).InputType = 'SingleEnded';
s.Channels(2).InputType = 'SingleEnded';
s.Channels(3).InputType = 'SingleEnded';
s.Channels(4).InputType = 'SingleEnded';
s.Channels(5).InputType = 'SingleEnded';
s.Channels(6).InputType = 'SingleEnded';
s.Rate = SR;
s.DurationInSeconds = dataduration;

addAnalogOutputChannel(s,'Dev1',0,'Voltage')
outputData = zeros(1,dataduration*SR);
outputData(50:50+NSAO) = 5;
queueOutputData(s,outputData');

[rawData,timeData] = s.startForeground;


t=((1:NSAI)/SR)';

result(:,1) = t;  %times, in seconds
result(:,2) = rawData(:,1); % heater voltage data
result(:,3) = rawData(:,2); % thermometer input voltage
result(:,4) = rawData(:,3); % thermistor one
result(:,5) = rawData(:,4); % thermistor two
result(:,6) = rawData(:,5); % thermistor three
result(:,7) = rawData(:,6); % thermistor four

close all

plotHeatFlow(result,4);
