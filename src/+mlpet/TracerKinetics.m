classdef (Abstract) TracerKinetics < handle & matlab.mixin.Heterogeneous & matlab.mixin.Copyable
	%% TRACERKINETICS  

	%  $Revision$
 	%  was created 10-Sep-2020 17:07:33 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.7.0.1434023 (R2019b) Update 6 for MACI64.  Copyright 2020 John Joowon Lee.
    
    properties
        measurement % expose for performance when used strategies for solve
        model       %
    end

    properties (Constant)
        BLOOD_DENSITY = 1.06         % https://hypertextbook.com/facts/2004/MichaelShmukler.shtml; human whole blood 37 C
        BRAIN_DENSITY = 1.05         % Torack et al., 1976, g/mL        
        PLASMA_DENSITY = 1.03
        DENSITY_BLOOD = 1.06
        DENSITY_BRAIN = 1.05
        DENSITY_PLASMA = 1.03
        LAMBDA = 0.95                % brain-blood equilibrium partition coefficient, mL/mL, Herscovitch, Raichle, JCBFM (1985) 5:65
        RATIO_SMALL_LARGE_HCT = 0.85 % Grubb, et al., 1978
        RBC_FACTOR = 0.766           % per Tom Videen, metproc.inc, line 193  
    end
    
    properties (Dependent)
        blurTag
        devkit
        regionTag
        sessionData % defers to nonempty devkit

        artery_interpolated
        roi % mlfourd.ImagingContext2
        times_sampled
    end
    
    methods % GET, SET
        function g = get.blurTag(this)
            g = this.sessionData.registry.instance().blurTag;
        end
        function g = get.devkit(this)
            g = this.devkit_;
        end
        function g = get.regionTag(this)
            g = this.sessionData.regionTag;
        end
        function g = get.sessionData(this)
            if ~isempty(this.devkit)
                g = this.devkit.sessionData;
                return
            end
            g = this.sessionData_;
        end

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
    end
    
    methods
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

    methods (Static)
        function cbf  = f1ToCbf(f1)
            % 1/s -> mL/min/hg
            cbf = f1 .* 6000/mlpet.TracerKinetics.DENSITY_BRAIN;
        end
        function f1   = cbfToF1(cbf)
            % mL/min/hg -> 1/s
            f1 = cbf .* mlpet.TracerKinetics.DENSITY_BRAIN/6000;
        end
        function v1   = cbvToV1(cbv)
            % mL/hg -> unit-less
            v1 = cbv .* mlpet.TracerKinetics.DENSITY_BRAIN/100;
        end
        function mLmL = lambdaToUnitless(mLg)
            % mL/g -> mL/mL            
            mLmL = mLg .* mlpet.TracerKinetics.DENSITY_BRAIN;
        end
        function mLg  = unitlessToLambda(mLmL)
            % mL/mL -> mL/g
            mLg = mLmL ./ mlpet.TracerKinetics.DENSITY_BRAIN;
        end
        function cbv  = v1ToCbv(v1)
            % unit-less -> mL/hg            
            cbv = v1 .* 100/mlpet.TracerKinetics.DENSITY_BRAIN;
        end
    end
    
    %% PROTECTED

    properties (Access = protected)
        devkit_
        sessionData_

        roi_
        strategy_ % for solve
    end
    
    methods (Access = protected)
        function this = TracerKinetics(varargin)
            %  @param devkit is mlpet.IDeviceKit.
            %  @param sessionData is mlpipeline.{ISessionData,ImagingData}, but defers to devkit.sessionData.
            %
            %  @param Dt is numeric, s of time-shifting for AIF.
            %  @param model for strategy.
            %  @param times_sampled is numeric.
            %  @param artery_interpolated is numeric.
            %  @param averageVoxels is logical, choosing creation of scalar results.  DEPRECATED.
            %  @param roi is understood by mlfourd.ImagingContext2; will be binarized.            
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            ip.PartialMatching = false;
            addParameter(ip, 'devkit', [])
            addParameter(ip, 'sessionData', [])
            addParameter(ip, 'model', [], @(x) ~isempty(x))
            addParameter(ip, 'roi', [])
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            this.devkit_ = ipr.devkit;
            this.sessionData_ = ipr.sessionData;
            if isempty(this.sessionData_)
                this.sessionData_ = this.devkit_.sessionData;
            end

            this.model = ipr.model;
            if ~isempty(ipr.roi)
                this.roi_ = mlfourd.ImagingContext2(ipr.roi);
                this.roi_ = this.roi_.binarized();
            end
        end
        function that = copyElement(this)
            %%  See also web(fullfile(docroot, 'matlab/ref/matlab.mixin.copyable-class.html'))
            
            that = copyElement@matlab.mixin.Copyable(this);
            that.devkit_ = copy(this.devkit_);

            that.roi_ = copy(this.roi_);
            that.strategy_ = copy(this.strategy_);
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
end

