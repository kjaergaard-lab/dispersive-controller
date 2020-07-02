classdef DispersiveController < handle
    %DispersiveController Provides a familiar interface for defining a sequence
    %
    %   The DispersiveController class provides familiar properties for common
    %   dispersive sequences.  The user should be able to just make an object,
    %   set properties, and run a couple of functions to upload a new
    %   imaging sequence.  However, the user can also edit the channel
    %   events directly
    %
    %   For ease-of-use, this class uses a variable expansion method that
    %   allows users to specify a property(ies) as arrays, and the class
    %   will expand all other variables to create a suitable number of
    %   configurations to cover all values.
    properties(Access = public)
        Rb
        K
        digitizerType
    end
    
    properties(Constant)
        %These properties are 'constant' only in the sense that their type
        %cannot be changed, but their properties can be changed
        controller = DispersiveTimingController;          %Timing controller object
    end
    
    properties(Constant, Hidden=true)
        DEFAULT_TCP_PORT = 5006;
        DEFAULT_HOST = '172.22.251.42';
        EX_PROP = {'controller','flexDDSTriggers'};  %Properties to exclude from variable expansion
    end
    
    
    methods
        function self = DispersiveController(varargin)
            %DispersiveController Constructs an object with default values
            %
            %   sp = DispersiveController constructs DispersiveController object sp 
            %   with default values
            self.reset;
            if nargin > 0
                self.controller.setDevice(varargin{:});
            else
                self.controller.setDevice('tcp','port',self.DEFAULT_TCP_PORT,'host',self.DEFAULT_HOST);
            end
        end
        
        function self = open(self)
            %OPEN Opens the device associated with the controller
            self.controller.open;
        end
        
        function self = close(self)
            %Close Closes the device associated with the controller
            self.controller.close;
        end
        
        function self = reset(self)
            %RESET Resets properties to their defaults.
            %
            %   self = self.reset resets object's properties to defaults,
            %   including the controller, FlexDDS trigger system, and state
            %   prep interface
            self.digitizerType = 'Rb';
            self.Rb = DispersivePulses;
            self.K = DispersivePulses;
            self.controller.reset;
        end
        
        function sp = checkValues(sp)
            %checkValues Checks certain properties to ensure that they are
            %in valid ranges
            for nn=1:numel(self.Rb)
                self.Rb(nn).checkValues;
            end
            
            for nn=1:numel(self.K)
                self.K(nn).checkValues;
            end
            
            if ~strcmpi(self.digitizerType,'Rb') && ~strcmpi(self.digitizerType,'K')
                error('Digitizer type must be either Rb or K');
            end
        end

        function self = makeSequence(self)
            %makeSequence Makes a complete dispersive pulse sequence
            %
            %   sp = sp.makeSequence makes a pulse sequence
            self.makePulseSequence(self.controller.pulseRb,self.Rb);
            self.makePulseSequence(self.controller.pulseK,self.K);
            switch upper(self.digitizerType)
                case 'RB'
                    [t,v] = self.controller.pulseRb.getEvents;
                case 'K'
                    [t,v] = self.controller.pulseK.getEvents;
                otherwise
                    error('Unknown digitizer type');
            end
            self.controller.digitizer.setEvents(t,v);
        end
        
        function self = makePulseSequence(self,ch,pulses)
            ch.at(0,0);
            for nn=1:numel(pulses)
                p = pulses(nn);
                ch.after(p.delay,0,'us');
                for mm=1:p.numPulses
                    ch.after(0,1,'us');
                    ch.after(p.width,0,'us')...
                         .after(p.period-p.width,0,'us');
                end
            end
        end
        
        function self = upload(self)
            %UPLOAD Uploads current sequence to controller or file
            %
            %   sp.upload uploads current sequence to controller if only
            %   one configuration is present or to a set of files in dir
            %   sp.file.dir with base-name sp.file.base if more than one
            %   configuration is present.
            self.controller.compile;
            self.controller.upload;
            
        end
        
        function self = plot(self,varargin)
            %PLOT Plots all channel sequences with associated names
            %
            %   This is an alias of SpartanImagingController.plot
            %
            %   sp = sp.plot plots all channel sequences on the same graph
            %
            %   sp = sp.plot(offset) plots all channel sequences on the
            %   same graph but with each channel's sequence offset from the
            %   next by offset
            self.controller.plot(varargin{:});
        end
        
        function self = softStart(self)
            %softStart Issues a software start of the controller
            %
            %   sp = sp.softStart issues a software start to the controller
            self.controller.dev.write(uint32(hex2dec('ff000000')));
        end
        
        
        
    end
    
    
    
end