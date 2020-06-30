classdef DispersivePulses < handle
    properties
        %All times in us
        period
        width
        delay
        numPulses
    end
    
    properties(SetAccess = immutable)
        addr
        index
    end
    
    properties(Constant)
        
    end
    
    methods
        function self = DispersivePulses(addr,index)
            self.addr = addr;
            self.index = index;
            
            self.period = 50;
            self.width = 25;
            self.delay = 0;
            self.numPulses = 0;
        end
        
        function self = set(self,p,w,d,N)
            self.period = p;
            self.width = w;
            self.delay = d;
            self.numPulses = N;
            self.checkValues;
        end
        
        function self = checkValues(self)
            if self.period<=0
                error('Period must be positive!');
            elseif self.width<=0
                error('Width must be positive!');
            elseif self.delay<0
                error('Delay must be non-negative!');
            elseif self.numPulses<0
                error('Number of pulses cannot be negative!');
            elseif self.width>=self.period
                error('Width of pulse must be shorter than pulse period!');
            end
        end
        
        function self = upload(self,client)
            data = 
        end
        
        
    end
    
end