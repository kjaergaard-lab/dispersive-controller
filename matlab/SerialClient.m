classdef SerialClient < DeviceClient
    properties
        port
        baudrate
        buffersize
    end
    
    properties(Constant)
        DEFAULT_PORT = 'com3';          %Default serial port of the FPGA
        DEFAULT_BAUDRATE = 115200;      %Baud rate of the FPGA serial controller
        DEFAULT_BUFFER_SIZE = 2^16;     %Serial port buffer size
    end
    
    methods
        function self = SerialClient(varargin)
            if mod(nargin,2)~=0
                error('Inputs must occur in name/value pairs!');
            end
            
            self.port = self.DEFAULT_PORT;
            self.baudrate = self.DEFAULT_BAUDRATE;
            self.buffersize = self.DEFAULT_BUFFER_SIZE;
            
            for nn=1:2:nargin
                v = varargin{nn+1};
                switch varargin{nn}
                    case 'port'
                        self.port = v;
                    case 'baudrate'
                        self.baudrate = v;
                    case 'buffersize'
                        self.buffersize = v;
                    otherwise
                        error('Unrecognized name ''%s''',varargin{nn});
                end
            end
        end
        
        function self = open(self)
            %OPEN Opens a serial port
            %
            %   Uses the SerialClient.port and 
            %   SerialClient.baudrate properties to
            %   open a serial port.  Checks for already open or existing
            %   interfaces and uses those if they exist.
            
            if isa(self.dev,'serial') && isvalid(self.dev) && strcmpi(self.dev.port,self.port)
                if strcmpi(self.dev.status,'closed')
                    fopen(self.dev);
                end
                return
            else
                r = instrfindall('type','serial','port',upper(self.port));
                if isempty(r)
                    self.dev = serial(self.comPort,'baudrate',self.baudrate);
                    self.dev.OutputBufferSize = self.buffersize;
                    self.dev.InputBufferSize = self.buffersize;
                    fopen(self.dev);
                elseif strcmpi(r.status,'open')
                    self.dev = r;
                else
                    self.dev = r;
                    self.dev.OutputBufferSize = self.buffersize;
                    self.dev.InputBufferSize = self.buffersize;
                    fopen(self.dev);
                end   
            end
        end
        
        function close(self)
            %CLOSE Closes the serial port
            %   Closes and deletes the serial port associated with the
            %   timing controller.
            if isa(self.dev,'serial') && isvalid(self.dev) && strcmpi(self.dev.port,self.port)
                if strcmpi(self.dev.status,'open')
                    fclose(self.dev);
                end
                delete(self.dev);
            end
        end
        
        function delete(self)
            %DELETE Deletes the SerialClient object
            %   DELETE calls the SerialClient.close() function to close 
            %   the serial connection
            self.close;
        end
        
        function self = write(self,data,varargin)
            self.open;
            if ~isa(data,'uint8')
                data = typecast(data,'uint8');
            end
            for nn=1:numel(data)
                fwrite(self.dev,data(nn),'uint8');
            end
        end
        
        function self = read(self,data,varargin)
            self.open;
            self.write(data);
            while self.dev.BytesAvailable~=4
                pause(10e-3);
            end
            self.recvData = fread(self.dev,self.dev.BytesAvailable/4,'uint32');
        end
        
    end
    
end