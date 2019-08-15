% Vrms.m    
% analog input with rms calculation after detrend
% For use with Johnson noise experiment
ai=analoginput('nidaq','Dev1');
addchannel(ai,2);
set(ai,'SampleRate',2000,'SamplesPerTrigger',500);
set(ai,'InputType','SingleEnded');
start(ai);
data=getdata(ai)

n= length(data);
%v=detrend(data);
v=data;

vrms=sqrt(sum(v.^2)/n)
plot(data);
delete(ai);
clear ai

