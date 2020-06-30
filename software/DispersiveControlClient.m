classdef DispersiveControlClient < handle
    properties
        client
        host
    end
    
    properties(SetAccess = protected)
        headerLength
        header
        recvMessage
        recvDone
    end
    
    properties(Constant)
        TCP_PORT = 6666;
%         HOST_ADDRESS = '127.0.0.1';
        HOST_ADDRESS = '172.22.250.94';
    end
    
    methods
        function self = DispersiveControlClient(host)
            if nargin==1
                self.host = host;
            else
                self.host = self.HOST_ADDRESS;
            end
            self.initRead;
        end
        
        function open(self)
            self.client = tcpclient(self.host,self.TCP_PORT,'Timeout',1,'ConnectTimeout',1);
        end
        
        function close(self)
            delete(self.client);
            self.client = [];
        end
        
        function delete(self)
            try
                delete(self.client);
            catch
                disp('Error deleting client');
            end
        end
        
        function initRead(self)
            self.headerLength = [];
            self.header = [];
            self.recvMessage = [];
            self.recvDone = false;
        end
        
        function self = write(self,data,varargin)
            if mod(numel(varargin),2)~=0
                error('Variable arguments must be in name/value pairs');
            end
            if numel(data) == 0
                data = 0;
            end
            self.open;
            try
                msg.length = numel(data);

                for nn=1:2:numel(varargin)
                    msg.(varargin{nn}) = varargin{nn+1};
                end

                self.initRead;
                msg = jsonencode(msg);
                len = uint16(numel(msg));

                msg_write = [typecast(len,'uint8'),uint8(msg),typecast(uint32(data),'uint8')];
                write(self.client,msg_write);
                while ~self.recvDone
                    self.read;
                    pause(10e-3);
                end
                self.close
            catch
                self.close;
            end
        end
        
        function read(self)
            if isempty(self.headerLength)
                self.processProtoHeader();
            end
            
            if isempty(self.header)
                self.processHeader();
            end
            
            if isfield(self.header,'length') && isempty(self.recvMessage)
                self.processMessage();
            end
        end
    end
    
    methods(Access = protected)       
        function processProtoHeader(self)
            if self.client.BytesAvailable>=2
                self.headerLength = read(self.client,1,'uint16');
            end
        end
        
        function processHeader(self)
            if self.client.BytesAvailable>=self.headerLength
                tmp = read(self.client,self.headerLength,'uint8');
                self.header = jsondecode(char(tmp));
                if ~isfield(self.header,'length')
                    self.recvDone = true;
                end
            end
        end
        
        function processMessage(self)
            if self.client.BytesAvailable>=self.header.length
                self.recvMessage = read(self.client,round(self.header.length/4),'uint32');
                self.recvDone = true;
            end
        end
    end
   
    
end