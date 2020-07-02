classdef SpartanImaging < handle
    %SpartanImaging Provides a familiar interface for defining a sequence
    %
    %   The SpartanImaging class provides familiar properties for common
    %   imaging sequences.  The user should be able to just make an object,
    %   set properties, and run a couple of functions to upload a new
    %   imaging sequence.  However, the user can also edit the channel
    %   events directly
    %
    %   For ease-of-use, this class uses a variable expansion method that
    %   allows users to specify a property(ies) as arrays, and the class
    %   will expand all other variables to create a suitable number of
    %   configurations to cover all values.
    properties(Access = public)
        file                        %Structure with fields dir and base
        
        %% Imaging properties
        
        probeType                   %Type of probe sequence: Rb, K, RbRb, RbK, KRb, KK, F, V
        imageDelay                  %Delay between two images when using dual imaging
        crossbeamOnTime             %Time for the crossed-beam dipole trap to be on
        timeOfFlight                %Delay after crossbeamOnTime until first imaging pulse
        additionalWaveguideOnTime   %Additional time for the horizontal waveguide
        probeWidthRb                %Width of Rb probe pulse
        probeWidthK                 %Width of K probe pulse
        probeWidthV                 %Width of the vertical imaging pulse
        probeWidthF                 %Width of the fluorescence imaging pulse
        
        probeShutterDelay           %Delay between probe shutter opening and probe pulse
        camDelay                    %Delay between camera trigger high and probe pulse high
        camLoopTime                 %Loop time between absorption images
        repumpProbeWidth            %Width of the repump probe pulse
        repumpProbeDelay            %Delay between start of repump probe pulse and imaging probe pulse
        repumpShutterDelay          %Delay between opening of repump shutter and start of repump probe pulse
        
        enableProbe                 %Enable probe pulses?
        enableRepump                %Enable repump pulse?
        
    end
    
    properties(Access = protected)
       	numConfigs                  %Number of configurations to write.  If >1, writes to files
    end
    
    properties(Constant)
        %These properties are 'constant' only in the sense that their type
        %cannot be changed, but their properties can be changed
        
        controller = SpartanImagingController;          %Timing controller object
        flexDDSTriggers = SpartanFlexDDSTriggerSystem;  %FlexDDS trigger system
        pulses = StatePrepPulses;                       %Interface for creating state preparation pulses
    end
    
    properties(Constant, Hidden=true)
        SER_COM_PORT = 'com3';          %Serial com port, in case different from SpartanImagingController
        ANDOR_FIRST_LOOP_TIME = 30;     %First loop time for the Andor camera in [ms]
        ANDOR_READ_TIME = 20;           %Read time for the Andor camera in [ms]
        ANDOR_TRANSFER_TIME = 0.16;     %Transfer time of Andor camera from image CCD to storage CCD in [ms]
        EX_PROP = {'file','controller','flexDDSTriggers'};  %Properties to exclude from variable expansion
    end
    
    
    methods
        function sp = SpartanImaging
            %SpartanImaging Constructs an object with default values
            %
            %   sp = SpartanImaging constructs SpartanImaging object sp 
            %   with default values
            sp.reset;
            sp.file.dir = 'C:\Users\nkgroup.PX\Documents\FPGA Files\';
%             sp.file.dir = 'FPGA Files\';
            sp.file.base = 'FPGA';
        end
        
        function sp = open(sp)
            %OPEN Opens a serial port associated with the controller
            sp.controller.open;
        end
        
        function sp = close(sp)
            %Close Closes a serial port associated with the controller
            sp.controller.close;
        end
        
        function sp = reset(sp)
            %RESET Resets properties to their defaults.
            %
            %   sp = sp.reset resets object sp's properties to defaults,
            %   including the controller, FlexDDS trigger system, and state
            %   prep interface
            sp.probeType = 'Rb';
            sp.imageDelay = 0.16;
            
            sp.crossbeamOnTime = 50;
            sp.timeOfFlight = 20;
            sp.additionalWaveguideOnTime = 0;
            sp.probeWidthRb = 15;
            sp.probeWidthK = 15;
            sp.probeWidthF = 15;
            sp.probeWidthV = 15;
            
            sp.repumpProbeDelay = 0.15;
            sp.repumpProbeWidth = 150;
            sp.repumpShutterDelay = 2.5;
            
            sp.camDelay = 0.25;
            sp.camLoopTime = 30;
            sp.probeShutterDelay = 2.5;
            
            sp.enableProbe = 1;
            sp.enableRepump = 1;
            
            sp.controller.reset;
            sp.flexDDSTriggers.reset;
            sp.pulses.reset;
            
            sp.controller.comPort = sp.SER_COM_PORT;
        end
        
        function sp = checkValues(sp)
            %checkValues Checks certain properties to ensure that they are
            %in valid ranges
            if any(sp.imageDelay<sp.ANDOR_TRANSFER_TIME)
                warning('Transfer time of Andor camera is %d us.  Image delay should not be less than this!',sp.ANDOR_TRANSFER_TIME*1e3);
            end
        end
        
        function sp = expandVariables(sp)
            %expandVariables Replicates public variables such that each
            %variable is the same length.  This frees the user from making
            %sure that each variable is the same length
            maxVarLength = 1;
            p = properties(sp);
            for nn = 1:length(p)
                if ~sp.checkProp(p{nn})
                    continue;
                end
                
                v = sp.(p{nn});
                if isnumeric(v) || islogical(v) || iscell(v)
                    N = numel(v);
                elseif isa(v,'StatePrepPulses')
                    N = v.getMaxVarLength;
                else
                    N = 1;
                end
                if N>maxVarLength
                    maxVarLength = N;
                end
            end
            
            for nn = 1:length(p)
                if ~sp.checkProp(p{nn})
                    continue;
                end
                
                v = sp.(p{nn});
                if isnumeric(v) || islogical(v) || iscell(v)
                    N = numel(v);
                    sp.(p{nn}) = [v(:)' repmat(v(end),1,maxVarLength-N)];
                elseif isa(v,'StatePrepPulses')
                    v.repVars(maxVarLength);
                elseif ischar(v)
                    sp.(p{nn}) = repmat({v},1,maxVarLength);
                end
            end
            
            sp.numConfigs = maxVarLength;
        end
        
        function r = checkProp(sp,p)
            %checkProp Checks if property is to be excluded from expansion
            %
            %   r = sp.checkProp(p) checks if property p is part of
            %   SpartanImaging.EX_PROP, returns false if so and true
            %   otherwise
            for nn = 1:numel(sp.EX_PROP)
                if strcmpi(sp.EX_PROP(nn),p)
                    r = false;
                    return;
                end
            end
            r = true;     
        end
        
        function sp = makeSingleImageSeq(sp,idx)
            %makeSingleImageSeq Makes a single imaging sequence
            %
            %   sp = sp.makeSingleImageSeq makes an imaging sequence for a
            %   supported type of single absorption imaging sequence.
            %
            %   sp = sp.makeSingleImageSeq(idx) makes an imaging sequence
            %   corresponding to the element idx in each property array.
            %   For idx>1, sp.expandVariables should be called first.
            if nargin < 2
                idx = 1;
            end
            if iscell(sp.probeType)
                pt = sp.probeType{idx};
            else
                pt = sp.probeType;
            end
            switch upper(pt)
                case 'RB'
                    width = sp.probeWidthRb(idx);
                    probe = sp.controller.probeRb;
                    shutter = sp.controller.shutterRb;
                    camTrig = sp.controller.camTrig;
                case 'K'
                    width = sp.probeWidthK(idx);
                    probe = sp.controller.probeK;
                    shutter = sp.controller.shutterK;
                    camTrig = sp.controller.camTrig;
                case 'F'
                    width = sp.probeWidthF(idx);
                    probe = sp.controller.probeMOTF;
                    shutter = sp.controller.shutterMOTF;
                    camTrig = sp.controller.camTrig;
                case 'V'
                    width = sp.probeWidthV(idx);
                    probe = sp.controller.probeV;
                    shutter = sp.controller.shutterV;
                    camTrig = sp.controller.camTrigV;
                otherwise
                    error('Single imaging case not supported')
            end
            
            onTime = sp.crossbeamOnTime(idx)+sp.timeOfFlight(idx);
            probeR = sp.controller.probeRepumpF;
            shutterR = sp.controller.shutterRepumpF;
            enableP = 1*(sp.enableProbe(idx)~=0);
            enableR = 1*(sp.enableRepump(idx)~=0);
            
            %% First image with atoms
            probe.at(onTime,enableP,'ms').after(width,0,'us');
            shutter.anchor(onTime,'ms').before(sp.probeShutterDelay(idx),enableP,'ms').at(probe.last,0);
            camTrig.anchor(onTime,'ms').before(sp.camDelay(idx),1,'ms').at(probe.last,0);
            
            probeR.anchor(onTime,'ms').before(sp.repumpProbeDelay(idx),enableR,'ms');
            shutterR.anchor(probeR.last).before(sp.repumpShutterDelay(idx),enableR,'ms');
            probeR.after(sp.repumpProbeWidth(idx),0,'us');
            shutterR.at(probeR.last,0);
            
            %% Second image with atoms
            onTime = onTime+sp.camLoopTime(idx);
            probe.at(onTime,enableP,'ms').after(width,0,'us');
            shutter.anchor(onTime,'ms').before(sp.probeShutterDelay(idx),enableP,'ms').at(probe.last,0);
            camTrig.anchor(onTime,'ms').before(sp.camDelay(idx),1,'ms').at(probe.last,0);
            
            probeR.anchor(onTime,'ms').before(sp.repumpProbeDelay(idx),enableR,'ms');
            shutterR.anchor(probeR.last).before(sp.repumpShutterDelay(idx),enableR,'ms');
            probeR.after(sp.repumpProbeWidth(idx),0,'us');
            shutterR.at(probeR.last,0);
            
            %% Third image without atoms
            onTime = onTime+sp.camLoopTime(idx);
            camTrig.at(onTime,1,'ms').before(sp.camDelay(idx),1,'ms').sort.after(width,0,'us');
            
        end
        
        function sp = makeDoubleImageSeq(sp,idx)
            %makeDoubleImageSeq Makes a double imaging sequence
            %
            %   sp = sp.makeDoubleImageSeq makes an imaging sequence for a
            %   supported type of double absorption imaging sequence.
            %
            %   sp = sp.makeDoubleImageSeq(idx) makes an imaging sequence
            %   corresponding to the element idx in each property array.
            %   For idx>1, sp.expandVariables should be called first.
            if nargin < 2
                idx = 1;
            end
            if iscell(sp.probeType)
                pt = sp.probeType{idx};
            else
                pt = sp.probeType;
            end
            switch upper(pt)
                case 'RBRB'
                    width1 = sp.probeWidthRb(idx);
                    width2 = sp.probeWidthRb(idx);
                    probe1 = sp.controller.probeRb;
                    probe2 = sp.controller.probeRb;
                    shutter1 = sp.controller.shutterRb;
                    shutter2 = sp.controller.shutterRb;
                case 'RBK'
                    width1 = sp.probeWidthRb(idx);
                    width2 = sp.probeWidthK(idx);
                    probe1 = sp.controller.probeRb;
                    probe2 = sp.controller.probeK;
                    shutter1 = sp.controller.shutterRb;
                    shutter2 = sp.controller.shutterK;
                case 'KRB'
                    width1 = sp.probeWidthK(idx);
                    width2 = sp.probeWidthRb(idx);
                    probe1 = sp.controller.probeK;
                    probe2 = sp.controller.probeRb;
                    shutter1 = sp.controller.shutterK;
                    shutter2 = sp.controller.shutterRb;
                case 'KK'
                    width1 = sp.probeWidthK(idx);
                    width2 = sp.probeWidthK(idx);
                    probe1 = sp.controller.probeK;
                    probe2 = sp.controller.probeK;
                    shutter1 = sp.controller.shutterK;
                    shutter2 = sp.controller.shutterK;
                otherwise
                    error('Double imaging case not supported')
            end
            
            camTrig = sp.controller.camTrig;
            onTime = sp.crossbeamOnTime(idx)+sp.timeOfFlight(idx);
            delay = max(sp.imageDelay(idx),sp.ANDOR_READ_TIME);
            
            probeR = sp.controller.probeRepumpF;
            shutterR = sp.controller.shutterRepumpF;
            enableP = sp.enableProbe(idx)~=0;
            enableR = bitget(sp.enableRepump(idx),1:2);
            %% Zeroeth, throw-away image for Andor iXon camera in frame-transfer mode
            camTrig.anchor(onTime,'ms').before(sp.ANDOR_FIRST_LOOP_TIME,1,'ms').after(sp.camDelay(idx),0,'ms');
            
            %% First images with atoms
            shutter1.anchor(onTime,'ms').before(sp.probeShutterDelay(idx),enableP,'ms').sort;
            shutter2.anchor(onTime,'ms').before(sp.probeShutterDelay(idx),enableP,'ms').sort;
            probe1.at(onTime,enableP,'ms').after(width1,0,'us');
            camTrig.at(probe1.last,0).before(sp.camDelay(idx),1,'ms');
            
            probe2.anchor(probe1.last).after(sp.imageDelay(idx),enableP,'ms').after(width2,0,'us');
            shutter1.at(probe2.last,0);
            shutter2.at(probe2.last,0);
            
            camTrig.after(delay,1,'ms').after(sp.camDelay(idx),0,'ms');
            
            probeR.anchor(onTime,'ms').before(sp.repumpProbeDelay(idx),enableR(1),'ms');
            shutterR.anchor(probeR.last).before(sp.repumpShutterDelay(idx),enableR(1),'ms');
            probeR.after(sp.repumpProbeWidth(idx),0,'us');
            shutterR.at(probeR.last,enableR(2));
            
            probeR.anchor(probe2.last-width2*1e-6).before(sp.repumpProbeDelay(idx),enableR(2),'ms');
            shutterR.anchor(probeR.last).before(sp.repumpShutterDelay(idx),enableR(2),'ms');
            probeR.after(sp.repumpProbeWidth(idx),0,'us');
            shutterR.at(probeR.last,0);
            
            %% Second images without atoms
            onTime = onTime+delay+sp.camLoopTime(idx);
            shutter1.anchor(onTime,'ms').before(sp.probeShutterDelay(idx),enableP,'ms').sort;
            shutter2.anchor(onTime,'ms').before(sp.probeShutterDelay(idx),enableP,'ms').sort;
            probe1.at(onTime,enableP,'ms').after(width1,0,'us');
            camTrig.at(probe1.last,0).before(sp.camDelay(idx),1,'ms');
            
            probe2.anchor(probe1.last).after(sp.imageDelay(idx),enableP,'ms').after(width2,0,'us');
            shutter1.at(probe2.last,0);
            shutter2.at(probe2.last,0);
            
            camTrig.after(delay,1,'ms').after(sp.camDelay(idx),0,'ms');
            
            probeR.anchor(onTime,'ms').before(sp.repumpProbeDelay(idx),enableR(1),'ms');
            shutterR.anchor(probeR.last).before(sp.repumpShutterDelay(idx),enableR(1),'ms');
            probeR.after(sp.repumpProbeWidth(idx),0,'us');
            shutterR.at(probeR.last,enableR(2));
            
            probeR.anchor(probe2.last-width2*1e-6).before(sp.repumpProbeDelay(idx),enableR(2),'ms');
            shutterR.anchor(probeR.last).before(sp.repumpShutterDelay(idx),enableR(2),'ms');
            probeR.after(sp.repumpProbeWidth(idx),0,'us');
            shutterR.at(probeR.last,0);
            
            %% Third dark images
            onTime = onTime+delay+sp.camLoopTime(idx);
            camTrig.at(onTime,0,'ms').before(sp.camDelay(idx),1,'ms');
            camTrig.after(delay,1,'ms').after(sp.camDelay(idx),0,'ms');
            
        end
        
        function sp = makeSequence(sp,idx)
            %makeSequence Makes a complete imaging sequence
            %
            %   sp = sp.makeSequence makes an imaging sequence, including
            %   state preparation pulses and FlexDDS triggers
            %
            %   sp = sp.makeDoubleImageSeq(idx) makes an imaging sequence
            %   corresponding to the element idx in each property array.
            %   For idx>1, sp.expandVariables should be called first.
            if nargin < 2
                idx = 1;
            end
            tc = sp.controller;
            tc.reset;
            
            sp.controller.laser.at(0,1).after(sp.crossbeamOnTime(idx)+sp.additionalWaveguideOnTime(idx),0,'ms');
            if iscell(sp.probeType)
                pt = sp.probeType{idx};
            else
                pt = sp.probeType;
            end
            switch upper(pt)
                case {'RB','K','V','F'}
                    sp.makeSingleImageSeq(idx);
                case {'RBRB','KK','RBK','KRB'}
                    sp.makeDoubleImageSeq(idx);
                otherwise
                    error('Probe type %s not supported!',sp.probeType(idx));
            end
            
            sp.pulses.makeSequences(tc.mw,tc.rf,tc.pulseType,idx);
        end
        
        function sp = upload(sp)
            %UPLOAD Uploads current sequence to controller or file
            %
            %   sp.upload uploads current sequence to controller if only
            %   one configuration is present or to a set of files in dir
            %   sp.file.dir with base-name sp.file.base if more than one
            %   configuration is present.
            sp.controller.compile;
            if isempty(sp.numConfigs) || sp.numConfigs == 1
                sp.controller.open;
                sp.flexDDSTriggers.upload(sp.controller.ser);
                sp.controller.upload;
            else
%                 delete(sprintf('%s*',sp.file.dir));
                for nn = 1:sp.numConfigs
                    sp.makeSequence(nn);
                    dev = fopen(sprintf('%s%s_%d',sp.file.dir,sp.file.base,nn),'w');
                    sp.flexDDSTriggers.upload(dev);
                    sp.controller.upload(dev);
                    fclose(dev);
                end
            end
        end
        
        function sp = plot(sp,varargin)
            %PLOT Plots all channel sequences with associated names
            %
            %   This is an alias of SpartanImagingController.plot
            %
            %   sp = sp.plot plots all channel sequences on the same graph
            %
            %   sp = sp.plot(offset) plots all channel sequences on the
            %   same graph but with each channel's sequence offset from the
            %   next by offset
            sp.controller.plot(varargin{:});
        end
        
        function sp = softStart(sp)
            %softStart Issues a software start of the controller
            %
            %   sp = sp.softStart issues a software start to the controller
            sp.controller.open;
            dev = sp.controller.ser;
            fwrite(dev,hex2dec('ff000000'),'uint32');
        end
        
        
        
    end
    
    
    
end