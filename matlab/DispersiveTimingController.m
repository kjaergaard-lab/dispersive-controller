classdef DispersiveTimingController < TimingController
    %DispersiveController A wrapper for the TimingController object
    %
    %   Provides a wrapper around the TimingController class that defines
    %   names for relevant channels belonging to our dispersive controller
    properties
        pulseRb         %Rb dispersive pulse output
        pulseK          %K dispersive pulse output
        shutter         %Shutter output
        digitizer       %Digitizer trigger
    end
    
    properties (Constant, Hidden = true)
        DEFAULT_TCP_PORT = 5006;
        DEFAULT_HOST = '172.22.251.42';
        DEFAULT_AUX = {'method','serial','port','/dev/serial0','baudrate',115200};
    end
    
    methods
        function self = DispersiveTimingController(varargin)
            %DispersiveController Constructs a SpartanImagingController
            %object
            %
            %   sp = DispersiveController creates the
            %   DispersiveController object
            if nargin == 0
                args = {'tcp','port',DispersiveTimingController.DEFAULT_TCP_PORT,...
                    'host',DispersiveTimingController.DEFAULT_HOST};
            else
                args = varargin;
            end
            self = self@TimingController(args{:});
            self.defineChannels;
            
            if isa(self.dev,'SocketServerClient')
                self.dev.aux = self.DEFAULT_AUX;
            end
        end
        
        function self = setDevice(self,protocol,varargin)
            switch lower(protocol)
                case {'uart','serial'}
                    self.dev = SerialClient(varargin{:});
                case {'tcp','tcpip'}
                    self.dev = SocketServerClient(varargin{:});
                    self.dev.aux = self.DEFAULT_AUX;
                otherwise
                    error('Protocol %s not recognized. Choose either %s or %s',v,'uart','tcp');
            end
        end
        
        function self = defineChannels(self)
            %defineChannels Defines the different channels with names
            self.pulseRb = self.findBit(0);
            self.pulseK = self.findBit(1);
            self.shutter = self.findBit(2);
            self.digitizer = self.findBit(3);
            
        end
        
        function sp = plot(sp,offset)
            %PLOT Plots all channel sequences with associated names
            %
            %   tc = tc.plot plots all channel sequences on the same graph
            %
            %   tc = tc.plot(offset) plots all channel sequences on the
            %   same graph but with each channel's sequence offset from the
            %   next by offset
            if nargin < 2
                offset = 0;
            end
            jj = 1;
            p = properties(sp);
            for nn = 1:numel(p)
                ch = sp.(p{nn});
                if ~isa(ch,'TimingControllerChannel') || numel(ch)>1
                    continue;
                end
                ch.plot((jj-1)*offset);
                hold on;
                if ch.getNumValues > 0
                    str{jj} = sprintf('%s (%d)',p{nn},ch.getBit);  %#ok<AGROW>
                    jj = jj+1;
                end
            end
            hold off;
            legend(str);
            xlabel('Time [s]');
        end
    
    end
    
end