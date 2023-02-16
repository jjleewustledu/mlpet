classdef TracerKineticsStrategy < handle & mlpet.TracerKinetics
	%% TRACERKINETICSSTRATEGY is the context to a strategy design pattern for implementations of solve().    
    %  For performance considerations, see also https://blogs.mathworks.com/loren/2012/03/26/considering-performance-in-object-oriented-matlab-code/

	%  $Revision$
 	%  was created 06-Dec-2020 00:38:21 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.9.0.1524771 (R2020b) Update 2 for MACI64.  Copyright 2020 John Joowon Lee.
 	 	   
    properties  
        measurement % expose for performance when used strategies for solve
        model       %
    end
    
	properties (Dependent) 	
        artery_interpolated
        roi % mlfourd.ImagingContext2
        times_sampled
 	end

	methods 
        
        %% GET, SET
        
        function g = get.artery_interpolated(this)
            g = this.strategy_.artery_interpolated;
        end 
        function g = get.roi(this)
            g = this.roi_;
        end    
        function     set.roi(this, s)
            if ~isempty(s)
                this.roi_ = mlfourd.ImagingContext2(s);
                this.roi_ = this.roi_.binarized();
            end
        end
        function g = get.times_sampled(this)
            g = this.strategy_.times_sampled;
        end
        
        %%
         
        function Q = loss(this)
            Q = this.strategy_.loss();
        end
        function h = plot(this, varargin)
            h = this.strategy_.plot(varargin{:});
        end
        function this = simulated(this, varargin)
            this.measurement = this.model.simulated(varargin{:});
            this.strategy_.Measurement = this.measurement; % strategy_ needs value copies for performance
        end
        function this = solve(this, varargin)
            this.strategy_ = solve(this.strategy_, varargin{:});
        end
    end 
    
    %% PROTECTED
    
    properties (Access = protected)
        roi_
        strategy_ % for solve
    end
    
    methods (Access = protected) 
 		function this = TracerKineticsStrategy(varargin)
            %  @param Dt is numeric, s of time-shifting for AIF.
            %  @param model for strategy.
            %  @param times_sampled is numeric.
            %  @param artery_interpolated is numeric.
            %  @param averageVoxels is logical, choosing creation of scalar results.  DEPRECATED.
            %  @param roi is understood by mlfourd.ImagingContext2; will be binarized.
            
 			this = this@mlpet.TracerKinetics(varargin{:});
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'model', [], @(x) ~isempty(x))
            addParameter(ip, 'roi', [])
            parse(ip, varargin{:});
            ipr = ip.Results;
            
            this.model = ipr.model;
            if ~isempty(ipr.roi)
                this.roi_ = mlfourd.ImagingContext2(ipr.roi);
                this.roi_ = this.roi_.binarized();
            end
 		end
        function that = copyElement(this)
            %%  See also web(fullfile(docroot, 'matlab/ref/matlab.mixin.copyable-class.html'))
            
            that = copyElement@matlab.mixin.Copyable(this);
            that.roi_ = copy(this.roi_);
            that.strategy_ = copy(this.strategy_);
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
end

