classdef ModelBuilder 
	%% MODELBUILDER  

	%  $Revision$
 	%  was created 30-May-2018 01:54:25 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
    properties (Constant)
        DENSITY_BRAIN = 1.05    % assumed mean brain density, g/mL
        CBF_UTHRESH = 500
        CBV_UTHRESH = 100
        LAMBDA = 0.95           % brain-blood equilibrium partition coefficient, mL/mL, Herscovitch, Raichle, JCBFM (1985) 5:65
        RBC_FACTOR = 0.766      % per Tom Videen, metproc.inc, line 193  
        RATIO_SMALL_LARGE_HCT = 0.85 % Grubb, et al., 1978         
    end
    
	properties (Dependent)
 		product
 		sessionContext
 	end

	methods 
        
        %% GET/SET
        
        function g = get.product(this)
            g = this.product_;
        end
        function g = get.sessionContext(this)
            g = this.tracerContext_.sessionContext;
        end
        
        %%
        
        function a = assembleAif(this)
            a = mlswisstrace.Twilite( ...
                'tracerContext', this.tracerContext_, ...
                'calibrations', this.calibrations_, ...
                'alignmentContext', this.alignmentContext_);
            %this.aif.time0 = this.configAifTime0; % mlpet.AlignmentContext
            %this.aif.timeF = this.configAifTimeF;
        end
        function c = assembleCalibrations(this)
            c = mlsiemens.CalibrationContext( ...
                'tracerContext', this.tracerContext_);
        end
        function l = assembleLabs(this)
            l = mlraichle.LabsContext( ...
                'sessionContext', this.sessionContext);
        end
        function s = assembleScan(this, varargin)
            %this.mask = sessdFdg.aparcAsegBinarized('typ','mlfourd.ImagingContext');
            s = mlsiemens.BiographMMR(varargin{:}, ...
                'tracerContext', this.tracerContext_, ...
                'calibrations', this.calibrations_, ...
                'alignmentContext', this.alignmentContext_);
            %this.sessd.tracerResolvedFinal('typ','niftid'), ...
            %'sessionData',       this.sessd, ...
            %'doseAdminDatetime', this.doseAdminDatetimeActive(tracer_), ...
            %'invEfficiency',     this.invEffMMR, ...
            %'manualData',        this.mand, ...
            %'mask',              this.mask);
            %this.scanner.time0 = this.configScannerTime0; % mlpet.AlignmentContext
            %this.scanner.timeWindow = this.aif.timeWindow;
            %this.scanner.dt = 1;
            %this.scanner.isDecayCorrected = false;  
        end
		  
 		function this = ModelBuilder(varargin)
 			%% MODELBUILDER
 			%  @param named tracerContext.
 			
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'tracerContext', [], @(x) isa(x, 'mlpet.TracerContext'));
            parse(ip, varargin{:});            
            this.tracerContext_ = ip.Results.tracerContext;
            
            this.alignmentContext_ = mlpet.AlignmentContext( ...
                'tracerContext', this.tracerContext_);
 		end
 	end 
    
    %% PROTECTED
    
    properties (Access = protected)
        alignmentContext_
        calibrations_
        product_
        tracerContext_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

