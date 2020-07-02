classdef StatePrepPulses < handle
    %spartanPulses Class defining properties and methods related to state
    %preparation pulses for the spartan 3AN imaging controller
    %implementation.
    properties
        numPulses
        pulses
    end
    
    properties(Constant)
        PULSE_TYPES = {'RB','K','RF'};
    end
    
    methods
        function obj = StatePrepPulses
            %StatePrepPulses Initializes the object with no pulses and a
            %pulses structure with fields start, duration, and type
            obj.reset;
        end
        
        function obj = reset(obj)
            %reset Resets the properties to their defaults
            obj.numPulses = 0;
            obj.pulses = struct('start',{},'duration',{},'type',{});
        end
        
        function obj = addPulse(obj,startTime,duration,pulseType)
            %addPulse Adds a pulse with a starting time, a duration, and a
            %type
            obj.checkType(pulseType);
            obj.numPulses = obj.numPulses+1;
            obj.setPulse(obj.numPulses,startTime,duration,pulseType);
        end
        
        function obj = setPulse(obj,idx,startTime,duration,pulseType)
            %setPulse Sets the properties of an individual pulse
            if idx>obj.numPulses || idx<1
                error('Index is out of range!');
            end
            obj.checkType(pulseType);
            obj.pulses(idx) = struct('start',startTime,'duration',duration,'type',pulseType);
        end
        
        function obj = checkType(obj,pulseType)
            %checkType Checks to see if given pulse type is allowed
            %
            %   obj = obj.checkType(pulseType) checks if pulseType is
            %   allowed
            r = false;
            for nn=1:numel(obj.PULSE_TYPES)
                if strcmpi(pulseType,obj.PULSE_TYPES{nn})
                    r = true;
                end
            end
            if ~r
                error('Pulse type not found!');
            end
        end
        
        function obj = removePulses(obj,idx)
            %removePulses Removes the specified pulses
            %
            %   obj = obj.removePulses(idx) removes the pulses specified by
            %   idx
            if any(idx>obj.numPulses) || any(idx<1)
                error('Index is out of range!');
            end
            incl = true(obj.numPulses,1);
            incl(idx) = false;
            obj.pulses = obj.pulses(incl);
            obj.numPulses = numel(obj.pulses);
        end
        
        function r = getMaxVarLength(obj)
            %getMaxVarLength Returns the maximum length of a variable in
            %the object
            r = 1;
            for nn=1:obj.numPulses
                v = obj.pulses(nn);
                names = fieldnames(v);
                for mm = 1:length(names)
                    if ischar(v.(names{mm}))
                        N = 1;
                    else
                        N = numel(v.(names{mm}));
                    end
                    if N>r
                        r = N;
                    end
                end
            end
        end
        
        function obj = repVars(obj,maxLength)
            %repVars Replicates the variables to a given size
            %
            %   obj.repVars(maxLength) Replicates the variables to the
            %   length given by maxLength
            for nn = 1:obj.numPulses
                names = fieldnames(obj.pulses(nn));
                for mm = 1:numel(names)
                    v = obj.pulses(nn).(names{mm});
                    if isnumeric(v) || iscell(v)
                        obj.pulses(nn).(names{mm}) = [v(:)' repmat(v(end),1,maxLength-numel(v))];
                    elseif ischar(v)
                        obj.pulses(nn).(names{mm}) = repmat({v},1,maxLength);
                    end
                end
            end
        end
        
        function obj = makeSequences(obj,mw,rf,pt,idx)
            %makeSequences Makes relevant sequences based
            %
            %   obj = obj.makeSequences(MW,RF,PT) adds the relevant events
            %   to the microwave MW, radio-frequency RF, and pulse type PT
            %   channels based on the parameters set within.  MW, RF, and
            %   PT should be of type TimingControllerChannel
            %
            %   obj = obj.makeSequences(MW,RF,PT,idx) makes the relevant
            %   sequences for parameters given by idx
            if nargin < 5
                idx = 1;
            end
            for nn=1:obj.numPulses
                p = obj.pulses(nn);
                if iscell(p.type)
                    pulseType = p.type{idx};
                else
                    pulseType = p.type;
                end
                switch upper(pulseType)
                    case 'RB'
                        mw.at(p.start(idx),1,'ms').after(p.duration(idx),0,'ms');
                        pt.at(p.start(idx),1,'ms').after(p.duration(idx),0,'ms');
                    case 'K'
                        mw.at(p.start(idx),1,'ms').after(p.duration(idx),0,'ms');
                        pt.at(p.start(idx),0,'ms').after(p.duration(idx),0,'ms');
                    case 'RF'
                        rf.at(p.start(idx),1,'ms').after(p.duration(idx),0,'ms');
                    otherwise
                        error('Pulse type %s not supported!',p.type{idx});
                end
            end
        end
        
    end %end methods
    
end