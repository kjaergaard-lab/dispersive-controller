classdef (Abstract) DeviceClient < handle
    properties (SetAccess = protected)
        dev
        recvData
    end
    
    methods (Abstract)
        self = open(self)
        close(self)
        self = write(self,data,varargin)
        self = read(self,data,varargin)
    end
    
    methods
        function delete(self)
            self.close;
        end
    end
end