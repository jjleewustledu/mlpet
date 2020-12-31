classdef (Abstract) TracerKineticsModel 
	%% TRACERKINETICSMODEL  

	%  $Revision$
 	%  was created 07-Dec-2020 18:22:05 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.9.0.1524771 (R2020b) Update 2 for MACI64.  Copyright 2020 John Joowon Lee. 	 	
    
    methods (Abstract, Static)
        preferredMap
        sampled
        simulanneal_objective
        solution
    end
    
    methods (Abstract)      
        simulated(this)
    end
    
	properties
        artery_interpolated
 		map
        times_sampled
    end

	methods		  
 		function this = TracerKineticsModel(varargin)
            %  @param map is a containers.Map.  Default := this.preferredMap.
            %  @param times_sampled for scanner is typically not uniform.
            %  @param artery_interpolated must be uniformly interpolated.
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'map', this.preferredMap(), @(x) isa(x, 'containers.Map'))
            addParameter(ip, 'times_sampled', [], @isnumeric)
            addParameter(ip, 'artery_interpolated', [], @isnumeric)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            this.map = ipr.map;
            this = set_times_sampled(this, ipr.times_sampled);
            this = set_artery_interpolated(this, ipr.artery_interpolated);
 		end
        
        function this = set_times_sampled(this, s)
            if isempty(s)
                return
            end
            this.times_sampled = s;
        end
        function this = set_artery_interpolated(this, s)
            if isempty(s)
                return
            end
            % artery_interpolated may be shorter than scanner times_sampled
            assert(~isempty(this.times_sampled))
            if length(s)-1 ~= this.times_sampled(end)
                this.artery_interpolated = ...
                    makima(0:length(s)-1, s, this.times_sampled(1):this.times_sampled(end));
            else
                this.artery_interpolated = s;
            end
        end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

