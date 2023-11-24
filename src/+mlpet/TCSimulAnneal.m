classdef TCSimulAnneal < mlpet.TracerSimulAnneal
    %% TCSIMULANNEAL operates on single voxels/regions.
    %  
    %  Created 22-Nov-2023 19:50:42 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
    %  Developed on Matlab 23.2.0.2428915 (R2023b) Update 4 for MACA64.  Copyright 2023 John J. Lee.
    
    methods
        function this = TCSimulAnneal(varargin)
 			%% TCSIMULANNEAL
            %  @param context is mlglucose.Huang1980.
            %  @param sigma0.
            %  @param fileprefix.
            
            this = this@mlpet.TracerSimulAnneal(varargin{:});
        end
        
        function [k,sk] = k1(this, varargin)
            [k,sk] = find_result(this, 'k1');
        end
        function [k,sk] = k2(this, varargin)
            [k,sk] = find_result(this, 'k2');
        end
        function [k,sk] = k3(this, varargin)
            [k,sk] = find_result(this, 'k3');
        end    
        function [k,sk] = k4(this, varargin)
            [k,sk] = find_result(this, 'k4');
        end          
        function [k,sk] = k5(this, varargin)
            [k,sk] = find_result(this, 'k5');
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
