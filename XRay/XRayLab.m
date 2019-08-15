% XRayLab.m - function
% X-Ray Stepper Motor Controller
% Maksim Sipos 2005
% Physics 360, Advanced Lab, Prof. Bruce Thompson
% modified 2/26/2005 by Bruce Thompson to embed all the code
%   and show angles
%   and do a real time plot
% Edited 4/8/2011 by BGT to Version II
% II - contains fix for papallel port problem
%    - must write both lines 1&2 at the same time for some reason
% Edited 7/17/2012 by Emily Backus
%   - changed from script to function
%   - saves data to a text file while reading
%   - updated to a new nidaq device (NI USB-6009)

function [Angles, Counts] = XRayLab

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Constants

pauseTimeHi = 0.01;  % time of the HI step in seconds
pauseTimeLo = 0.01;  % time of the LO step in seconds
limit_free = 100; % number of first steps to ignore the limit
extra_limit = 1700; % number of maximum steps
Nsec = 2;   % time span to take count data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialization

% Create DAQ object
%DHI = daqhwinfo
%DHI.InstalledAdaptors
DIO = digitalio('parallel', 'LPT1');

% Add 2 lines for data pins, for output
lines = addline(DIO, [0; 1], 'Out');

% Add 2 lines for Acknowledge and Busy (for some reason, have to use 3 & 4)
lines = addline(DIO, [3;4], 1, 'In');

% line 1 is the step line
% line 2 is the direction line
% line 3 is the count line
% line 4 is the limit sensor line

% line2 = 0 is the direction RIGHT or towards HIGHER angles
% line2 = 1 is the direction LEFT or towards LOWER angles
% line4 = 0 means black surface below (LIMIT)
% line4 = 1 means light surface below (NOT LIMIT)

% Initialize lines:
putvalue(DIO.line(1),0);
putvalue(DIO.line(2),0);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %Initialize National Instruments Data Acquisition Device
%     %Vmin = -10; %define voltage read range
%     %Vmax = 10;
%     
%     %CHECK YOUR INPUT CHANNEL NUMBER AND DEVICE ID AND ENTER THEM HERE
%     channel = 0; % Channel number
%     AI = analoginput('nidaq', 'Dev2');
%     % Add 2 lines for data pins, for output
%     addchannel(AI, [0;1], 'Out') ;
%     % Add 2 lines for Acknowledge and Busy (for some reason, have to use 3 & 4)
%     addchannel(AI, [3;4], 1, 'In');
%     % line 1 is the step line
%     % line 2 is the direction line
%     % line 3 is the count line
%     % line 4 is the limit sensor line
% 
%     % line2 = 0 is the direction RIGHT or towards HIGHER angles
%     % line2 = 1 is the direction LEFT or towards LOWER angles
%     % line4 = 0 means black surface below (LIMIT)
%     % line4 = 1 means light surface below (NOT LIMIT)
% 
%     %set(AI, 'InputType', 'SingleEnded') ;
%     %set(AI, 'SampleRate', sampleRate);
%     %set(AI, 'SamplesPerTrigger', sampleRate * seconds) ;
% 
%     % Set the range of data input
%     %set(AI.Channel(1), 'InputRange', [Vmin Vmax]) ;
%     %set(AI.Channel(1), 'UnitsRange', [Vmin Vmax]) ;
%     %set(AI.Channel(1), 'SensorRange', [Vmin Vmax]) ;
%     
%     % Initialize lines:
%     putvalue(DIO.line(1),0);
%     putvalue(DIO.line(2),0);
% 
% %%%%%%%%%%%%%%%%%%%
% 
% %Take the Data
%     start(AI);
%     data = getdata(AI);
%     
% %Clean Up
%     delete(AI);
%     clear AI;

%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Work

% Go left until you see LIMIT
putvalue(DIO.line(2), 1); % direction = left; don't really need this in II
limit = 1 ;  % check limit
while limit == 1                % loop until limit is reached
    putvalue(DIO.line(1:2), 3); % step up; must write both lines 1&2 II
    pause(pauseTimeHi);         % wait while HI
    putvalue(DIO.line(1:2), 2); % step down; must write both lines 1&2 II
    pause(pauseTimeLo);         % wait while LO
    limit = getvalue(DIO.line(4));  % check limit
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%get a filename from the user to write the data to
filename = input('Enter the filepath and filename where you would like to save your data \n (ex: C:\\Documents and Settings\\User\\Desktop\\myData.txt): ', 's');
fid = fopen(filename, 'wt'); %creates the file and sets it to write
fprintf(fid,'%s \n','Starting Angle: ');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the angle and the first data, begin plot
StartAngle = input('Nudge the carrier and enter the starting angle (ex: 15): ');
data = XrayCounts2(Nsec); %calls the sub functions
close all;
plt = plot(0,data,'.','erasemode','none');
axis([0 2000 0 500]);
xlabel('Steps'); ylabel('Counts');
title('Real time Xray plot');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Save this first data point to a text file with the initial angle
fprintf(fid,'%6.1f \n',StartAngle);
fprintf(fid,'%s \n','Counts: ');
fprintf(fid,'%6.1f \n',data);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Go right until you see LIMIT gathering data as you go
putvalue(DIO.line(2), 0);    % direction = right; not needed in II
limit = 1 ;  % check limit
n = 0;
while limit == 1        % loop until limit is reached
%    for ii=1:5
        putvalue(DIO.line(1:2), 1);   % step up; wirte both lines II
        pause(pauseTimeHi);       % wait while HI
        putvalue(DIO.line(1:2), 0);   % step down; write both lines II
        pause(pauseTimeLo);       % wait while LO
%    end
    limit = getvalue(DIO.line(4));  % check limit
    n = n + 1; 
    if n < limit_free
        limit = 1;
    end
    if n > extra_limit
        limit = 0 ;
    end
    c = XrayCounts2(Nsec);
    data =[data c] ;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %add this new data point to the text file
    fprintf(fid,'%6.1f \n',c);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    set(plt,'xdata',n,'ydata',c);
    drawnow;
end

% stop the digital I/O engine
delete(DIO);
clear DIO;

% determine the carrier angles
EndAngle = input('Enter the ending angle: ');
AnglePerStep = (EndAngle-StartAngle)/(length(data)-1);
Counts = data;
Angles = StartAngle + AnglePerStep*(0:length(data)-1);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %add the angles to the text file
    fprintf(fid,'%6.2f \n',Angles);
    %close the text file
    fclose(fid);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% make a final plot
figure
plot(Angles,Counts);
xlabel('Angles(deg)'); ylabel('Counts');
title(strcat('Xray data - ', datestr(now)));
disp('The data are contained in the arrays Angles and Counts.');
end

function cps=XrayCounts2(SampleSec)
% 
% determines the counts of the xray detector
% first it gets the analog data for a time of SampleSec 
% then it determines the number of counts it recognises
%
% GetAnalogData is embedded in this file
% FindBouceTimes is embedded in this file
% 
% bgt 3/26/2005

Vth=1.5;          % voltage threshold for start of bounce
Tskip=0.0007;     % time to skip after detection

SampleRate=8000;
NofChannels=1;
Ts = SampleSec;           % time to sample in seconds
NofSamples=Ts*SampleRate;

% get data
[data, t] = GetAnalogDataF( NofChannels, SampleRate, NofSamples);
% disp('Data Aq. done');

% analyze data
d=detrend(data);
% [B,A]=butter(6,f0/fn);
% d=filter(B,A,d);
[tb,xb] = findBounceTimesF(d,SampleRate,Vth,Tskip);
cps = length(tb)/Ts;
end

function [data, t] = GetAnalogDataF( NofChannels, SampleRate, NofSamples)
% [data,t]=GetAnalogData( NofChannels, SampleRate, NofSamples)
% function to get analog data via the National Instruments DAQ card
%
% input:
%   NofChannels -   the number of channels to aquire, sampling will be
%                   sequential from channel 0 to N-1
%   SampleRate  -   the sample rate in Hz
%   NofSamples  -   total number of samples to obtain per channel
%
% output:
%   data        -   data samples in NofChannels columns
%   t           -   times of the samples in data
%
% Hardware inputs are configured as SingleEnded and with the default
% InputRange which is [-5 5]. See code for changing this.
%
% bgt   -   1/28/2003

% set up analog IO
	ai=analoginput('nidaq','Dev1');
    c=0:NofChannels-1;
	addchannel(ai, c);
    set(ai, 'InputType','SingleEnded');
	set(ai, 'SampleRate', SampleRate);
	set(ai, 'SamplesPerTrigger',NofSamples);
	set(ai, 'TriggerType','Manual');
    % to change the InputRange use the following line as a template,
    % the only valid values are 10,5,2,1,0.5,0.2,0.1,0.05 for the
    % PCI-MIO-16E4 card
    % this line sets channel 1 to the range -1 to 1 volt
    % set(ai.Channel(1),'InputRange',[-1 1];
    
% start the 'engine'
	start(ai);

% show parameters and wait for start keypress
	TT=NofSamples/SampleRate;
	sprintf('NChan: %2i SRate: %f NSamples: %6i Time: %f\n', ...
        NofChannels, SampleRate, NofSamples, TT);   
% 	'Pause - press any key to start data aquisition'
% 	pause

% hit the 'gas' and wait for the data
	trigger(ai);
	[data,t]=getdata(ai);

% stop the 'engine' and clear the memory
	delete(ai);
	clear ai;

% end GetAnalogData
end

function [tb,xb] = findBounceTimesF(x,SampleRate,Vth,Tskip)
% [tb,xb]=findBounceTimes(x)
% find the times at which the signal in array x exceeds the threshold,
% works by finding the time of a bounce and then skipping forward before
% finding the next, skip lengths are varied from start to end

% set Vth to a resonable threshhold based on looking at the time series
% and set the Max and Min skip times and total time of all bounces
% Vth=0.04;

Iskip=floor(Tskip*SampleRate);

% init the loop
I=1;
Ibegin=1;
Ilength=length(x);

% find first
Ifirst = findBounce(x,Vth,Ibegin);
Ib=Ifirst;

while Ib(I)<Ilength,
    Ibegin = Ib(I)+Iskip;
    if Ibegin >= Ilength 
        break; 
    end
    Ibb = findBounce(x,Vth,Ibegin);
    Ib=[Ib; Ibb];
    I=I+1;
end
Ibc = Ib(1:length(Ib)-1);
tb = (Ibc-1)/SampleRate;
xb = x(Ibc);
end
function Ibounce = findBounce(x,Vth,Ibegin)
% find the next bounce or the end of the array
    ix=Ibegin;
    lx=length(x);
    while abs(x(ix))<Vth,
        if ix==lx; 
            break; 
        end
        ix=ix+1;
    end
    Ibounce=ix;
end
