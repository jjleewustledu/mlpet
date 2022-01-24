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
    
    methods (Static)
        function q1 = solutionOnScannerFrames(q, times_sampled)
            %  @param q that is empty resets internal data for times and q1 := [].
            %  @param q is activity that is uniformly sampled in time.
            %  @param times_sampled are the times of the midpoints of scanner frames, all times_sampled > 0.
            %  @return q1 has the shape of times_sampled.
            
            persistent times % for performance
            if isempty(q)
                times = [];
                q1 = [];
                return
            end
            if isempty(times)
                times = zeros(1, length(times_sampled)+1);
                for it = 2:length(times)
                    times(it) = times_sampled(it-1) + (times_sampled(it-1) - times(it-1));
                end
            end
            
            q1 = zeros(size(times_sampled));
            Nts = length(times_sampled);
            Nq = length(q);
            for it = 1:Nts-1
                indices = floor(times(it):times(it+1)) + 1;
                q1(it) = trapz(q(indices)) / (times(it+1) - times(it));
            end
            indices = floor(times(Nts):Nq-1) + 1;
            q1(Nts) = trapz(q(indices)) / (Nq - 1 - times(Nts));
        end
    end

	methods		  
 		function this = TracerKineticsModel(varargin)
            %  @param map is a containers.Map.  Default := this.preferredMap.
            %  @param times_sampled for scanner is typically not uniform.
            %  @param artery_interpolated must be uniformly interpolated.
            
            ip = inputParser;
            ip.PartialMatching = false;
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
            RR = mlraichle.StudyRegistry.instance();
            tBuffer = RR.tBuffer;
            if length(s) ~= floor(this.times_sampled(end)) + tBuffer + 1
                if RR.stableToInterpolation
                    this.artery_interpolated = ...
                        makima(-tBuffer:(length(s)-tBuffer-1), s, -tBuffer:this.times_sampled(end));
                else
                    this.artery_interpolated = ...
                        interp1(-tBuffer:(length(s)-tBuffer-1), s, -tBuffer:this.times_sampled(end), ...
                        'linear', 0);
                end
            else
                this.artery_interpolated = s;
            end
        end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

