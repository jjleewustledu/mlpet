classdef (Abstract) ScannerDevice < handle & mlpet.AbstractDevice
    %% line1
    %  line2
    %  
    %  Created 16-Dec-2023 22:27:06 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
    %  Developed on Matlab 23.2.0.2428915 (R2023b) Update 4 for MACA64.  Copyright 2023 John J. Lee.
    
    properties (Dependent)
        isWholeBlood
    end
    
    methods %% GET        
        function g = get.isWholeBlood(~)
            g = true;
        end
    end

    methods (Access = protected)
        function this = ScannerDevice(varargin)
 			this = this@mlpet.AbstractDevice(varargin{:});
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
