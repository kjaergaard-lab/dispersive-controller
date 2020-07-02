classdef SocketServerClient < DeviceClient
    properties
        host
        port
        aux
    end
    
    properties(SetAccess = protected)
        headerLength
        header
        recvDone
    end
    
    properties(Constant)
        DEFAULT_TCP_PORT = 6666;
        DEFAULT_HOST_ADDRESS = '172.22.250.94';
    end
    
    methods
        function self = SocketServerClient(varargin)
            if mod(nargin,2)~=0
                error('Input arguments must occur in name/value pairs');
            end
            
            self.host = self.DEFAULT_HOST_ADDRESS;
            self.port = self.DEFAULT_TCP_PORT; 
            
            for nn=1:2:nargin
                v = varargin{nn+1};
                switch varargin{nn}
                    case 'host'
                        self.host = v;
                    case 'port'
                        self.port = v;
                    otherwise
                        error('Unrecognized name ''%s''',varargin{nn});
                end
            end
            self.reset;
        end
        
        function set.aux(self,v)
            if ~iscell(v)
                error('Auxiliary arguments must be a cell array');
            elseif mod(numel(v),2)~=0
                error('Auxiliary arguments must be in the form of name/value pairs');
            else
                self.aux = v;
            end
        end
        
        function open(self)
            self.dev = tcpclient(self.host,self.port,'Timeout',1,'ConnectTimeout',1);
        end
        
        function close(self)
            delete(self.dev);
            self.dev = [];
        end
        
        function delete(self)
            try
                delete(self.dev);
            catch
                disp('Error deleting dev');
            end
        end
        
        function reset(self)
            self.headerLength = [];
            self.header = [];
            self.recvData = [];
            self.recvDone = false;
        end
        
        function self = write(self,data,varargin)
            if mod(numel(varargin),2)~=0
                error('Variable arguments must be in name/value pairs');
            end
            if numel(data) == 0
                data = uint8(0);
            end
            
            if ~isa(data,'uint8')
                data = typecast(data,'uint8');
            end
            
            self.open;
            try
                msg.length = numel(data);

                for nn=1:2:numel(varargin)
                    msg.(varargin{nn}) = varargin{nn+1};
                end
                
                for nn=1:2:numel(self.aux)
                    msg.(self.aux{nn}) = self.aux{nn+1};
                end

                self.reset;
                msg = jsonencode(msg);
                len = uint16(numel(msg));

                msg_write = [typecast(len,'uint8'),uint8(msg),data];
                write(self.dev,msg_write);
%                 if isfield(msg,'mode') && strcmpi(msg.mode,'read')
%                     while ~self.recvDone
%                         self.readInternal;
%                         pause(10e-3);
%                     end
%                 end
                while ~self.recvDone
                    self.readInternal;
                    pause(10e-3);
                end
                self.close
            catch
                self.close;
            end
        end
        
        function self = read(self,data,varargin)
            args = varargin;
            args{end+1} = 'mode';
            args{end+1} = 'read';
            self.write(data,varargin{:});
        end
        
    end
    
    methods(Access = protected)
        function self = readInternal(self,varargin)
            if isempty(self.headerLength)
                self.processProtoHeader();
            end
            
            if isempty(self.header)
                self.processHeader();
            end
            
            if isfield(self.header,'length') && isempty(self.recvData)
                self.processMessage();
            end
        end
        
        function processProtoHeader(self)
            if self.dev.BytesAvailable>=2
                self.headerLength = read(self.dev,1,'uint16');
            end
        end
        
        function processHeader(self)
            if self.dev.BytesAvailable>=self.headerLength
                tmp = read(self.dev,self.headerLength,'uint8');
                self.header = jsondecode(char(tmp));
                if ~isfield(self.header,'length')
                    self.recvDone = true;
                end
            end
        end
        
        function processMessage(self)
            if self.dev.BytesAvailable>=self.header.length
                self.recvData = read(self.dev,round(self.header.length/4),'uint32');
                self.recvDone = true;
            end
        end
    end
   
    
end