classdef SpartanFlexDDSTriggerSystem < handle
    %SpartanFlexDDSTriggerSystem Class for handling FlexDDS triggers
    properties
        numTriggers     %Number of triggers as NUM_OUTPUTSx1 array
        trigFreq        %Trigger frequency [Hz] as NUM_OUTPUTSx1 array
    end
    
    properties(Constant)
        ID = 1;                 %ID of this subsystem
        SET_NUM_PULSE = 1;      %Command for setting the number of pulses
        SET_PULSE_PERIOD = 0;   %Command for setting the pulse period
        NUM_OUTPUTS = 3;        %Number of FlexDDS trigger outputs
        COMMAND_RESET = 2;
        CLK = 100e6;            %FPGA clock frequency
    end
    
    methods
        function dds = SpartanFlexDDSTriggerSystem
            %SpartanFlexDDSTriggerSystem Constructs the object
            %
            %   dds = SpartanFlexDDSTriggerSystem constructs the trigger
            %   system object dds with default parameters
            dds.reset;
        end
        
        function dds = reset(dds,dev)
            %RESET Resets parameters to defaults
            %
            %   dds = dds.reset resets parameters
            dds.trigFreq = 200e3*ones(dds.NUM_OUTPUTS,1);
            dds.numTriggers = 10*dds.trigFreq;
            if nargin==2
                fwrite(dev,bitshift(dds.ID,24)+dds.COMMAND_RESET,'uint32');
            end
        end
        
        function dds = upload(dds,dev)
            %UPLOAD Uploads parameters to device
            %
            %   dds = dds.upload(dev) uploads parameters to device dev
            for nn=1:dds.NUM_OUTPUTS
                fwrite(dev,bitshift(dds.ID,24)+bitshift(nn-1,8)+dds.SET_NUM_PULSE,'uint32');
                fwrite(dev,uint32(dds.numTriggers(nn)),'uint32');
                fwrite(dev,bitshift(dds.ID,24)+bitshift(nn-1,8)+dds.SET_PULSE_PERIOD,'uint32');
                fwrite(dev,uint32(round(dds.CLK/dds.trigFreq(nn))),'uint32');
            end
        end
        
    end
    
    
    
end