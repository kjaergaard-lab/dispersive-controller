classdef SpartanImagingController < TimingController
    %SpartanImagingController A wrapper for the TimingController object
    %
    %   Provides a wrapper around the TimingController class that defines
    %   names for relevant channels belonging to our imaging controller
    properties
        %% Normal imaging channels
        camTrig             %Normal camera trigger
        probeRb             %Rb probe AOM on/off switch
        shutterRb           %Rb probe shutter on/off switch
        probeK              %K probe AOM on/off switch
        shutterK            %K shutter on/off switch
        
        %% Vertical imaging channels
        probeV              %Vertical imaging probe AOM on/off switch
        shutterV            %Vertical imaging shutter on/off switch
        camTrigV            %Vertical imaging camera trigger
        
        %% Fluorescence imaging
        probeRepumpF        %Repump probe AOM on/off switch
        probeMOTF           %MOT AOM on/off switch
        shutterRepumpF      %Repump shutter on/off switch
        shutterMOTF         %MOT shutter on/off switch
        
        %% Laser control
        laser               %Dipole trapping laser on/off switch
        
        %% Coil control
        coil                %Levitation coil on/off switch
        
        %% State preparation
        mw                  %Microwave on/off switch
        rf                  %RF on/off switch
        pulseType           %Pulse type on/off (Rb/K)

    end
    
    properties (Constant, Hidden = true)
        DEFAULT_SER_PORT = 'com3';
        DEFAULT_BAUD_RATE = 115200;
        DEFAULT_BUFFER_SIZE = 2^16;
    end
    
    methods
        function sp = SpartanImagingController
            %SpartanImagingController Constructs a SpartanImagingController
            %object
            %
            %   sp = SpartanImagingController creates the
            %   SpartanImagingController object
            args = {'uart','port',SpartanImagingController.DEFAULT_SER_PORT,...
                'baudrate',SpartanImagingController.DEFAULT_BAUD_RATE,...
                'buffersize',SpartanImagingController.DEFAULT_BUFFER_SIZE};
            sp = sp@TimingController(args{:});
            sp.defineChannels;
        end
        
        function sp = defineChannels(sp)
            %defineChannels Defines the different channels with names
            %% Normal imaging channels
            sp.camTrig = sp.findBit(0);
            sp.probeRb = sp.findBit(1);
            sp.shutterRb = sp.findBit(2);
            sp.probeK = sp.findBit(3);
            sp.shutterK = sp.findBit(4);
            
            
            %% Vertical imaging channels
            sp.probeV = sp.findBit(5);
            sp.shutterV = sp.findBit(6);
            sp.camTrigV = sp.findBit(7);
            
            %% Fluorescence imaging channels
            sp.probeRepumpF = sp.findBit(8);
            sp.probeMOTF = sp.findBit(9);
            sp.shutterRepumpF = sp.findBit(10);
            sp.shutterMOTF = sp.findBit(11);
            
            %% Laser control
            sp.laser = sp.findBit(12);
            
            %% Coil control
            sp.coil = sp.findBit(13);
            
            %% State preparation
            sp.mw = sp.findBit(14);
            sp.rf = sp.findBit(15);
            sp.pulseType = sp.findBit(16);
            
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