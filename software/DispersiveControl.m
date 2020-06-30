classdef DispersiveControl < handle
    properties
        dispRb
        dispK
        digitizerOutput
        debug
    end
    
    properties(Access = protected)
        sendStr
    end
    
    properties(Constant)
        timeUnits=1e-6;   %All times in microseconds
        clkFPGA=100e6;    %In MHz
        maxNumSeq=4;
        allowedDigitizerOutputs={'Rb','K'};
        
        remoteIP='172.22.251.42';
        remotePort=5006;
    end
    
    methods
        function obj=DispersiveControl(opt)
            if nargin==0 || ~strcmpi(opt,'blank')
                obj.dispRb=DispersivePulses;
                obj.dispK=DispersivePulses;
                obj.dispRb(obj.maxNumSeq,1)=DispersivePulses;
                obj.dispK(obj.maxNumSeq,1)=DispersivePulses;
                obj.digitizerOutput='Rb';
            end
            obj.sendStr='';
            obj.debug=false;
        end
        
        function set.digitizerOutput(obj,v)
            obj.digitizerOutput=v;
            obj.checkDigitizerOutput;
        end
        
        function checkDigitizerOutput(obj)
            flag=false;
            for nn=1:numel(obj.allowedDigitizerOutputs)
                if strcmpi(obj.allowedDigitizerOutputs{nn},obj.digitizerOutput)
                    flag=true;
                end
            end
            if ~flag
                s=[sprintf('%s, ',obj.allowedDigitizerOutputs{1:end-1}),obj.allowedDigitizerOutputs{end}];
                error('Digitizer setting must be one of %s',s);
            end;
        end
        
        function obj=checkValues(obj)
            if numel(obj.dispRb)>obj.maxNumSeq || numel(obj.dispK)>obj.maxNumSeq
                error('Maximum number of pulse sequences is %d',obj.maxNumSeq);
            end
            %Check individual values
            for nn=1:numel(obj.dispRb)
                obj.dispRb(nn).checkValues;
            end
            for nn=1:numel(obj.dispK)
                obj.dispK(nn).checkValues;
            end
            
        end %end checkValues
        
        function obj=upload(obj)
            obj.checkValues;
            obj.sendStr='';
            c=obj.timeUnits*obj.clkFPGA;    %Conversion to clock cycles
            obj.addStr(obj.encode('Rb disp period',[obj.dispRb.period]*c));
            obj.addStr(obj.encode('Rb disp width',[obj.dispRb.width]*c));
            obj.addStr(obj.encode('Rb disp delay',[obj.dispRb.delay]*c));
            obj.addStr(obj.encode('Rb disp num pulses',[obj.dispRb.numPulses])); %No unit conversion
            
            obj.addStr(obj.encode('K disp period',[obj.dispK.period]*c));
            obj.addStr(obj.encode('K disp width',[obj.dispK.width]*c));
            obj.addStr(obj.encode('K disp delay',[obj.dispK.delay]*c));
            obj.addStr(obj.encode('K disp num pulses',[obj.dispK.numPulses])); %No unit conversion
            
            obj.addStr(obj.encode(sprintf('Digitizer: %s',obj.digitizerOutput),0));
            
            conn=obj.open;
            fwrite(conn,obj.sendStr);
            pause(0.25);
            
            if obj.debug
                while conn.BytesAvailable>0
                    disp(fgets(conn));
                end
            end
            
            fclose(conn);
            delete(conn);
        end
        
        function obj=addStr(obj,s)
            if isempty(obj.sendStr)
                obj.sendStr=sprintf('%s',s);
            else
                obj.sendStr=sprintf('%s\n%s',obj.sendStr,s);
            end
        end
        
    end
    
    methods(Static)
        function s=encode(name,val,isArray)
            if nargin==2
                isArray=true;
            end;
            formatStr='{"name":"%s","value":%s}';
            arrayStr=sprintf('%d,',val);
            arrayStr=arrayStr(1:end-1);
            if isArray
                arrayStr=['[',arrayStr,']'];
            end
            s=sprintf(formatStr,name,arrayStr);
        end %end encode
        
        function conn=open
            conn=tcpip(DispersiveControl.remoteIP,DispersiveControl.remotePort);
            try
                fopen(conn);
            catch err
                if strcmpi(conn.status,'open')
                    fclose(conn);
                end
                delete(conn);
                fprintf(2,'No server could be found on %s:%d\n',DispersiveControl.remoteIP,DispersiveControl.remotePort);
                fprintf(2,'Log onto the server with user name nkgroup, password K40Rb87\n');
                fprintf(2,'and run the command ''nohup ./dispersiveServer.py & disown''\n');
                rethrow(err);
            end
        end
        
        function shutter(state)
            conn=DispersiveControl.open;
            fwrite(conn,DispersiveControl.encode('shutter',state,false));
            fclose(conn);delete(conn);
        end
        
        function rb(state)
            conn=DispersiveControl.open;
            fwrite(conn,DispersiveControl.encode('Rb disp',state,false));
            fclose(conn);delete(conn);
        end
        
        function k(state)
            conn=DispersiveControl.open;
            fwrite(conn,DispersiveControl.encode('K disp',state,false));
            fclose(conn);delete(conn);
        end
        
    end
    
end