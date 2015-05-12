classdef (Abstract) AutoradiographyBuilder < mlbayesian.AbstractMcmcProblem   
	%% AUTORADIOGRAPHYBUILDER is the abstract interface for Autoradiography builders
    %  such as PETAutoradiography, DSCAutoradiography.  Empty methods may be
    %  overridden as needed.

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.5.0.197613 (R2015a) 
 	%  $Id$ 
    
    properties (Constant)
        LAMBDA = 0.95           % brain-blood equilibrium partition coefficient, mL/mL, Herscovitch, Raichle, JCBFM (1985) 5:65
        LAMBDA_DECAY = 0.005677 % KLUDGE:  hard-coded [15O] half-life because propagating this.decayCorrection_ to static methods is difficult
        BRAIN_DENSITY = 1.05    % assumed mean brain density, g/mL
        RBC_FACTOR = 0.766      % per Tom Videen, metproc.inc, line 193
        TIME_SUP = Inf          % sec
        REUSE_STORED = true
    end

    properties (Abstract)
        map 
    end
    
    properties         
        xLabel = 'times/s'
        yLabel = 'concentration/(well-counts/mL/s)'
    end
    
    properties (Dependent)
        pnum
        aif
        mask
        ecat
        ecatSumtFilename
        concentration_a
        concentrationBar_a
        concentration_obs
    end
    
    methods %% GET
        function p = get.pnum(~)
            p = str2pnum(pwd);
        end
        function a  = get.aif(this)
            assert(~isempty(this.aif_));
            a = this.aif_;
        end
        function m  = get.mask(this)
            assert(~isempty(this.mask_));
            m = this.mask_;
        end
        function e  = get.ecat(this)
            assert(~isempty(this.ecat_));
            e = this.ecat_;
        end
        function fn = get.ecatSumtFilename(this)
            fn = fullfile(this.ecat.filepath, sprintf('%sho1_sumt.nii.gz', this.pnum));
        end
        function ca = get.concentration_a(this)
            assert(~isempty(this.concentration_a_));
            ca = this.concentration_a_;
        end
        function ca = get.concentrationBar_a(this) % for notational consistency with DSC*Autoradiography classes
            ca = this.concentration_a;
        end
        function co = get.concentration_obs(this)
            co = this.dependentData;
        end
    end
    
    methods (Static)
        function this = load(varargin)  %#ok<VANUS>
            this = [];
        end
        function this = loadAif(varargin)  %#ok<VANUS>
            this = [];
        end
        function mask = loadMask(varargin)
            p = inputParser;
            addOptional(p, 'fqfn',    [], @(x) lexist(x, 'file'));
            addOptional(p, 'iniftid', [], @(x) isa(x, 'mlfourd.INIfTId'));
            parse(p, varargin{:});
            
            if (~isempty(p.Results.fqfn))
                mask = mlfourd.MaskingNIfTId.load(p.Results.fqfn);
                return
            end
            if (~isempty(p.Results.iniftid))
                mask = p.Results.iniftid;
                return
            end
            error('mlpet:requiredObjectNotFound', 'AutoradiographyBuilder.loadMask');
        end      
        function ecat = loadEcat(varargin)
            p = inputParser;
            addOptional(p, 'fqfn', [],  @(x) lexist(x, 'file'));
            addOptional(p, 'ecat', [],  @(x) isa(x, 'mlpet.EcatExactHRPlus'));
            parse(p, varargin{:});
            
            if (~isempty(p.Results.fqfn))
                ecat = mlpet.EcatExactHRPlus.load(p.Results.fqfn);
                return
            end
            if (~isempty(p.Results.ecat))
                ecat = p.Results.ecat;
                return
            end
            error('mlpet:requiredObjectNotFound', 'AutoradiographyBuilder.loadEcat');
        end
        function ecat = loadDecayCorrectedEcat(varargin)
            p = inputParser;
            addOptional(p, 'fqfn', [],  @(x) lexist(x, 'file'));
            addOptional(p, 'ecat', [],  @(x) isa(x, 'mlpet.DecayCorrectedEcat'));
            parse(p, varargin{:});
            
            if (~isempty(p.Results.fqfn))
                ecat = mlpet.DecayCorrectedEcat.load(p.Results.fqfn);
                return
            end
            if (~isempty(p.Results.ecat))
                ecat = p.Results.ecat;
                return
            end
            error('mlpet:requiredObjectNotFound', 'AutoradiographyBuilder.loadDecayCorrectedEcat');
        end
        function this = simulateMcmc
            this = [];
        end
        function ci   = concentration_i
            ci = [];
        end
        function args = interpolateData
            args = {};
        end
        function f    = invs_to_mLmin100g(f)
            f = 100 * 60 * f / mlpet.AutoradiographyBuilder.BRAIN_DENSITY;
        end
    end
    
	methods         
        function this = simulateItsMcmc(this) %#ok<MANU>
            this = [];
        end
		function ci   = itsConcentration_i(this) %#ok<MANU>
            ci = [];
        end
        function this = estimateAll(this)
            this = this.estimateParameters(this.map);
        end
        function this = estimateParameters(this)
        end
        function ed   = estimateData(this) %#ok<MANU>
            ed = [];
        end
        function ed   = estimateDataFast(this) %#ok<MANU>
            ed = [];
        end
        function x    = priorLow(~, x)
        end
        function x    = priorHigh(~, x)
        end
        function        plotInitialData(this)
            figure;
            max_a   = max(this.concentration_a_);
            max_obs = max(this.concentration_obs);
            plot(this.times, this.concentration_a_/max_a, ...
                 this.times, this.concentration_obs/max_obs);
            title(sprintf('%s plotInitialData', this.baseTitle), 'Interpreter', 'none');
            legend('aif', 'ecat');
            xlabel(this.xLabel);
            ylabel(sprintf('well-counts/mL/s; rescaled %g, %g', max_a, max_obs));
        end        
        function        plotProduct(this)
            figure;
            plot(this.times, this.estimateData, this.times, this.dependentData, 'o');
            legend('Bayesian concentration_i', 'concentration_{obs} from data');
            title(this.detailedTitle, 'Interpreter', 'none');
            xlabel(this.xLabel);
            ylabel(this.yLabel);
        end   
        function        plotParVars(this) %#ok<MANU>
        end
        function this = estimatePriors(this)
        end
        
 		function this = AutoradiographyBuilder(conc_a, times_i, conc_i, varargin) 
 			%% AUTORADIOGRAPHYBUILDER  
 			%  Usage:  this = AutoradiographyBuilder( ...
            %                 concentration_a, times_i, concentration_i[, mask, aif, ecat]) 
            %                 ^ counts/s/mL    ^ s      ^ counts/s/g
            %                                                             ^ INIfTId
            %                                                                   ^ ILaif, IWellData 
            %                                                                        ^ IScannerData
            %  for DSC*Autoradiography, concentration_a <- concentrationBar_a

 			this = this@mlbayesian.AbstractMcmcProblem(times_i, conc_i); 
            ip = inputParser;
            addRequired(ip, 'conc_a',  @isnumeric);
            addRequired(ip, 'times_i', @isnumeric);
            addRequired(ip, 'conc_i',  @isnumeric);
            addOptional(ip, 'mask', [], @(x) isa(x, 'mlfourd.INIfTId'));
            addOptional(ip, 'aif',  [], @(x) isa(x, 'mlperfusion.ILaif') || isa(x, 'mlpet.IWellData'));
            addOptional(ip, 'ecat', [], @(x) isa(x, 'mlpet.IScannerData'));
            parse(ip, conc_a, times_i, conc_i, varargin{:});
            
            this.concentration_a_ = ip.Results.conc_a;
            this.mask_            = ip.Results.mask;
            this.aif_             = ip.Results.aif;
            this.ecat_            = ip.Results.ecat;			 
 		end 
 	end 
    
    %% PROTECTED
    
    properties (Access = 'protected')
        aif_
        mask_
        ecat_
        concentration_a_
    end

    methods (Static, Access = 'protected')
        function [times,counts] = shiftDataLeft(times0, counts0, Dt)
            %  Dt in sec
            idx_0  = floor(sum(double(times0 < Dt + times0(1)))+1);
            times  = times0(idx_0:end);
            times  = times - times(1);
            counts = counts0(idx_0:end);
            counts = counts - min(counts);
        end
        function [times,counts] = shiftDataRight(times0, counts0, Dt)
            %  Dt in sec
            lenDt  = ceil(Dt/(times0(2) - times0(1)));
            newLen = length(counts0) + lenDt;
            
            times0 = times0 - times0(1) + Dt;
            times  = [0:1:lenDt-1 times0];
            counts = counts0(1) * ones(1,newLen);            
            counts(end-length(counts0)+1:end) = counts0;
            counts = counts - min(counts);
        end
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

