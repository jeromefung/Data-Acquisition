%SPINDOWN
%Reads the spinning photogate data and sends it to a text file.
%
%[times, counts] = spinDown(timeBWpts, numPts)
%INPUTS:  timeBWpts = how many seconds to skip between each 
%                     one-second data reading 
%         numPts = the number of data points to read
%OUTPUTS: times = the time elapsed at each data reading
%         counts = the photogate counter reading at each time
%
%ex: [times, counts] = spinDown(10, 8)
%
%bgt 6/18/2003, edited by Emily Backus June 2012
%Edited MCS Fall 2015 for new Matlab DAQ drivers
% Edited KDS Spring 2019 to include channel range (wouldn't work otherwise)
function [counts, times] = spinDown_v2019(timeBWpts,numPts)
    % get filename to save data
    file = input('Filename for data (include the .txt extension): ','s');
    fid = fopen(file,'at');
    fprintf(fid,'%6s %7s\n','Time (s)','Counts'); %header
    fclose(fid);
    % prompt for start
    input('Spin up disk, press enter to start')
    fprintf('\t\t %6s %7s \n','Time (s)','Counts')
    
    %initialize variables
    ptsRecorded = 0;
    counts = zeros(1,numPts);
    times = zeros(1,numPts);
    tic; %start the timer
    tlast = toc;
    tnow = toc;
    i = 1; %for indexing into preallocated vectors
    
    while ptsRecorded<numPts %while still need to take data
        % get 1 second of data
        [p,~]=GetAnalogData(48000, 48000);
        %figure
        %plot(p)
        numEdges = CountEdges(p);
        counts(i) = numEdges;
        times(i) = tnow;
        i = i + 1;

        % output to screen and file
        fprintf('%5.0f %8.1f %8.0f \n',ptsRecorded+1,tlast,numEdges);
        fid=fopen(file,'at');
        fprintf(fid,'%8.1f %10.0f\n',tlast,numEdges);
        fclose(fid);

        %increment the number of points recorded
        ptsRecorded=ptsRecorded+1; 
        %update times
        tnow = toc;
        while tnow-tlast < timeBWpts
            pause(0.5) %if this isn't here then this loop runs millions of times
            tnow = toc;
        end
        tlast = ptsRecorded*timeBWpts;      
    end
end

function n = CountEdges(p)
%counts the number of up-going edges in the pulse series p
    ni = 1;
    lp = length(p);
    n = 0;
    %loop until end of file
    while ni<lp
        %find low level
        while p(ni)>2.5
            ni = ni+1;
            if ni>=lp
                break
            end
        end
        %if not end find hi level
        if ni<lp
            while p(ni)<3.5
                ni = ni+1;
                if ni>=lp
                    break
                end
            end
            %if high level found and not end then bump counter
            if ni<lp
                n=n+1;
            end
        end
    end
end





function [data, t] = GetAnalogData(SampleRate, NofSamples)
% [data,t]=GetAnalogData(SampleRate, NofSamples)
% function to get analog data via the National Instruments DAQ card
%
% inputs:
%   SampleRate  -   the sample rate in Hz
%   NofSamples  -   total number of samples to obtain
%
% output:
%   data        -   data samples in one column
%   t           -   times of the samples in data
%
% Input type is single-ended.
% bgt   -   1/28/2003
% Updated to use the Session-based interface.  MCS Jan 2015
s = daq.createSession('ni');
s.addAnalogInputChannel('Dev1', 'ai0', 'Voltage');
%Addint the range line finally gave me data, but it's still the wrong data.
s.Channels(1).Range = [-5 5];
s.Channels(1).InputType = 'SingleEnded';
s.Rate = SampleRate;
%s.Range = [-10,10];
s.DurationInSeconds = NofSamples/SampleRate;

[data,t] = s.startForeground;


end


    