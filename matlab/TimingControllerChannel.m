classdef TimingControllerChannel < handle
    %TimingControllerChannel Defines a channel for the digital
    %TimingController class.  Provides methods for adding times/values and
    %for plotting the resulting sequence
    properties
        default     %Default value for this channel
        manual      %Manual value
    end
    
    properties(Access = protected)
        bit         %Bit in std_logic_vector in VHDL code corresponding to this channel
        parent      %Parent timing controller object
        
        values      %Array of values in channel sequence.  Only 0 or 1 values are allowed
        times       %Array of times in the channel sequence in seconds
        numValues   %Number of time/value pairs
        
        lastTime    %Last time written - used for before/after functions
    end
    
    methods
        function ch = TimingControllerChannel(parent,bit)
            %TimingControllerChannel Contructs a channel
            %   ch = TimingControllerChannel(parent) Contructs a channel
            %   with the given parent
            %   ch = TimingControllerChannel(parent,bit) Constructs a
            %   channel with the given parent and bit number
            if nargin >= 1
                if ~isa(parent,'TimingController')
                    error('Parent must be a TimingController object!');
                end
                ch.parent = parent;
            end
            if nargin >= 2
                ch.bit = bit;
            end
            ch.default = 0;
            ch.manual = ch.default;
            ch.reset;
        end
        
        function ch = setParent(ch,parent)
            %setParent Sets the parent TimingController
            %
            %   ch = ch.setParent(PARENT) sets the parent to PARENT if
            %   PARENT is a TimingController object.  Returns the channel object
            %   ch
            if ~isa(parent,'TimingController')
                error('Parent must be a TimingController object!');
            end
            ch.parent = parent;
        end
        
        function p = getParent(ch)
            %getParent Returns the parent object
            %
            %   p = ch.getParent Returns the parent object for
            %   TimingControllerChannel object ch
            p = ch.parent;
        end
        
        function ch = setBit(ch,bit)
            %setBit Sets the bit-number for this channel
            %
            %   ch = ch.setBit(BIT) sets the bit number to integer BIT when
            %   ch is a TimingControllerChannel
            if bit>=0 && bit<ch.parent.NUM_CHANNELS
                ch.bit = bit;
            end
        end
        
        function b = getBit(ch)
            %getBit Returns the bit-number
            %
            %   B = ch.getBit returns bit as B
            b = ch.bit;
        end
        
        function [t,v] = getEvents(ch)
            %getEvents Returns the times and values as separate Nx1 arrays.
            % 
            %   Events are checked for errors and sorted before being
            %   returned.
            %   [t,v] = ch.getEvents returns times t and values v
            ch.check;
            ch.sort;
            if ch.numValues==0
                t = 0;
                v = ch.default;
            elseif ch.times(1) == 0
                t = ch.times;
                v = ch.values;
            else
                t = [0;ch.times];
                v = [ch.default;ch.values];
            end
        end
        
        function ch = setEvents(ch,t,v)
            %setEvents Sets the events to the given values
%             if t(1) == 0
%                 t = t(2:end);
%                 v = v(2:end);
%             end
            ch.times = t(:);
            ch.values = v(:);
            ch.numValues = numel(ch.times);
        end
        
        function N = getNumValues(ch)
            %getNumValues Returns the number of time/value pairs
            %
            %   N = ch.getNumValues returns the number of time/value pairs
            %   N
            N = ch.numValues;
        end
        
        function ch = at(ch,time,value,timeUnit)
            %AT Adds a value at the given time
            %
            %   ch = ch.at(TIME,VALUE) adds VALUE to the events at the time 
            %   given by TIME.  TIME must be in seconds and VALUE either 0
            %   or 1.  Sets the lastTime property to TIME
            %   ch = ch.at(TIME,VALUE,UNIT) adds VALUE to the events at the
            %   time given by TIME in units of UNIT.  Allowed units are
            %   'ns', 'us', 'ms', and 's'
            if nargin==4 && isnumeric(timeUnit)
                time = time*timeUnit;
            elseif nargin==4 && ischar(timeUnit)
                time = time*ch.getTimeUnit(timeUnit);
            end
            time = round(time*TimingController.FPGA_SAMPLE_CLK)/TimingController.FPGA_SAMPLE_CLK;
            
            idx = find(ch.times==time,1,'first');
            if value~=0 && value~=1
                error('Value must be either 0 or 1');
            end
            
            if isempty(idx)
                N = ch.numValues+1;
                ch.values(N,1) = value;
                ch.times(N,1) = time;
                ch.numValues = N;
                ch.lastTime = time;
            else
%                 warning('Value %d at time %.3g is being replaced',ch.values(idx),ch.times(idx));
                ch.values(idx,1) = value;
                ch.times(idx,1) = time;
                ch.lastTime = time;
            end
        end
        
        function ch = on(ch,varargin)
            %ON Alias of AT method
            ch.at(varargin{:});
        end
        
        function ch = after(ch,delay,value,timeUnit)
            %AFTER Adds a value to the events after the last added event
            %
            %   ch = ch.after(DELAY,VALUE) adds value to the events a time
            %   DELAY seconds after the property lastTime.  Note that this
            %   is not necessarily the latest time in the sequence.
            %   ch = ch.after(DELAY,VALUE,UNIT) assumes that DELAY has
            %   units specified by UNIT.  See AT documentation.
            if nargin==4 && isnumeric(timeUnit)
                delay = delay*timeUnit;
            elseif nargin==4 && ischar(timeUnit)
                delay = delay*ch.getTimeUnit(timeUnit);
            end
            
            time = ch.lastTime+delay;
            ch.at(time,value);
        end
        
        function ch = before(ch,delay,value,timeUnit)
            %BEFORE Adds a value to the events before the last added event
            %
            %   ch = ch.before(DELAY,VALUE) adds value to the events a time
            %   DELAY seconds before the property lastTime.  Note that this
            %   is not necessarily the latest time in the sequence.
            %   ch = ch.before(DELAY,VALUE,UNIT) assumes that DELAY has
            %   units specified by UNIT.  See AT documentation.
            if nargin==4 && isnumeric(timeUnit)
                delay = delay*timeUnit;
            elseif nargin==4 && ischar(timeUnit)
                delay = delay*ch.getTimeUnit(timeUnit);
            end
            
            time = ch.lastTime-delay;
            ch.at(time,value);
        end
        
        function ch = anchor(ch,time,timeUnit)
            %ANCHOR Sets the lastTime property
            %
            %   ch.anchor(TIME,UNIT) sets the lastTime property to TIME
            %   with units UNIT.  UNIT can be omitted.
            if nargin==3 && isnumeric(timeUnit)
                time = time*timeUnit;
            elseif nargin==3 && ischar(timeUnit)
                time = time*ch.getTimeUnit(timeUnit);
            end
            
            ch.lastTime = round(time*TimingController.FPGA_SAMPLE_CLK)/TimingController.FPGA_SAMPLE_CLK;
        end
        
        function [time,value] = last(ch)
            %LAST Returns the last time and last value
            %
            %   [t,v] = ch.last returns the last time t and last value v
            time = ch.times(end);
            value = ch.values(end);
        end
        
        function ch = reset(ch)
            %RESET Resets the channel sequence so that there are no events
            %   ch = ch.reset resets the channel
            ch.times = [];
            ch.values = [];
            ch.numValues = 0;
            ch.lastTime = [];
        end
        
        function ch = sort(ch)
            %SORT Sorts the events so that they are ordered chronologically
            %
            %   ch = ch.sort sorts the events.  The lastTime property is
            %   set to the last time in the sorted events
            if numel(ch.times)>0
                [B,K] = sort(ch.times);
                ch.times = B;
                ch.values = ch.values(K);
                ch.lastTime = ch.times(end);
            end
        end
        
        function ch = check(ch)
            %CHECK Checks times to make sure that they are all >= 0
            %
            %   Also checks to see if unique events actually occur, and
            %   removes sequence if nothing happens
            %
            %   ch = ch.check checks the event times and removes sequence
            %   if nothing happens
            if numel(unique(ch.values))==1
                ch.reset;
            end
            if any(ch.times<0)
                error('All times must be greater than 0 (no acausal events)!');
            end
        end
        
        function ch = plot(ch,offset)
            %PLOT Plots the current sequence as a function of time.
            %
            %   ch.plot plots the current sequence as a function of time.
            %   If there are no events, a message is displayed.
            %
            %   ch.plot(OFFSET) plots the current sequence with a vertical 
            %   offset given by OFFSET.  This is useful if you want to plot
            %   multiple signals on the same plot
            [t,v] = ch.getEvents;
            tplot = sort([t;t-1/ch.parent.FPGA_SAMPLE_CLK]);
            if numel(v)==1
                fprintf(1,'No events on this channel (%d). Plot not generated.\n',ch.bit);
                return
            end
            vplot = interp1(t,v,tplot,'previous');
            if nargin==2
                vplot = vplot+offset;
            end
            plot(tplot,vplot,'.-','linewidth',1.5);
        end
        
        function ch = write(ch,v)
            %WRITE Sets the manual value and writes to the device
            %
            %   ch = ch.write(V) writes the value V to the device using the
            %   parent's WRITEMANUAL method.
            ch.manual = 1*(v~=0);
            ch.parent.writeManual;
        end
        
    end
    
    methods(Static)
        function scale = getTimeUnit(unit)
            %getTimeUnit Returns the correct scaling for a given time unit
            %
            %   scale = TimingControllerChannel.getTimeUnit(UNIT) returns
            %   the numerical scale factor converting the given UNIT to
            %   seconds.  Allowed units are 'ns', 'us', 'ms', and 's'
            switch lower(unit)
                case 'ns'
                    scale = 1e-9;
                case 'us'
                    scale = 1e-6;
                case 'ms'
                    scale = 1e-3;
                case 's'
                    scale = 1;
                otherwise
                    error('Unit unknown');
            end
        end
    end
    
    
end