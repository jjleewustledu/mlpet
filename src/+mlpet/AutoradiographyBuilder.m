classdef (Abstract) AutoradiographyBuilder < mlbayesian.AbstractPerfusionProblem   
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
        TIME_SUP = 120          % sec
        REUSE_STORED = true
        USE_RECIRCULATION = false
        INJECTION_RATE = 0.25
    end

    properties (Abstract)
        map 
    end
    
    properties         
        xLabel = 'times/s'
        yLabel = 'concentration/(well-counts/mL)'
    end
    
    properties (Dependent)
        pnum
        aif
        aifShift
        mask
        ecat
        ecatShift
        ecatSumtFilename
        dose
        duration
        volume
    end
    
    methods %% GET
        function p = get.pnum(~)
            p = str2pnum(pwd);
        end
        function a  = get.aif(this)
            assert(~isempty(this.aif_));
            a = this.aif_;
        end
        function a  = get.aifShift(this)
            assert(~isempty(this.aifShift_));
            a = this.aifShift_;
        end
        function m  = get.mask(this)
            assert(~isempty(this.mask_));
            m = this.mask_;
        end
        function e  = get.ecat(this)
            assert(~isempty(this.ecat_));
            e = this.ecat_;
        end
        function a  = get.ecatShift(this)
            assert(~isempty(this.ecatShift_));
            a = this.ecatShift_;
        end
        function fn = get.ecatSumtFilename(this)
            fn = fullfile(this.ecat.filepath, sprintf('%sho1_sumt.nii.gz', this.pnum));
        end
        function d  = get.dose(this)
            assert(~isempty(this.dose_));
            d = this.dose_;
        end
        function d  = get.duration(this)
            assert(~isempty(this.duration_));
            d = this.duration_;
        end
        function d  = get.volume(this)
            assert(~isempty(this.volume_));
            d = this.volume_;
        end
    end
    
    methods (Static)
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
        
        function tito = indexTakeOff(curve)
            maxCurve = max(curve);
            minCurve = min(curve);
            for ti = 1:length(curve)
                if (curve(ti) - minCurve > 0.05 * (maxCurve - minCurve))
                    break;
                end
            end
            tito = ti - 1;
        end
        function f    = invs_to_mLmin100g(f)
            f = 100 * 60 * f / mlpet.AutoradiographyBuilder.BRAIN_DENSITY;
        end
    end
    
	methods
 		function this = AutoradiographyBuilder(conc_a, times_i, conc_i, varargin) 
 			%% AUTORADIOGRAPHYBUILDER  
 			%  Usage:  this = AutoradiographyBuilder( ...
            %                 concentration_a, times_i, concentration_i[, mask, aif, ecat]) 
            %                 ^ counts/s/mL    ^ s      ^ counts/s/g
            %                                                             ^ INIfTId
            %                                                                   ^ ILaif, IWellData 
            %                                                                        ^ IScannerData
            %  for DSC*Autoradiography, concentration_a <- concentrationBar_a

 			this = this@mlbayesian.AbstractPerfusionProblem(conc_a, times_i, conc_i); 
            ip = inputParser;
            addRequired(ip, 'conc_a',  @isnumeric);
            addRequired(ip, 'times_i', @isnumeric);
            addRequired(ip, 'conc_i',  @isnumeric);
            addOptional(ip, 'mask', [], @(x) isa(x, 'mlfourd.INIfTId'));
            addOptional(ip, 'aif',  [], @(x) isa(x, 'mlperfusion.ILaif') || isa(x, 'mlpet.IWellData'));
            addOptional(ip, 'ecat', [], @(x) isa(x, 'mlpet.IScannerData'));
            parse(ip, conc_a, times_i, conc_i, varargin{:});
            
            this.mask_     = ip.Results.mask;
            this.aif_      = ip.Results.aif;
            this.ecat_     = ip.Results.ecat;
            this.dose_     = this.itsDose; 
            this.duration_ = this.itsDuration;
            this.volume_   = this.itsVolume;
        end
        
        function dcv  = itsDcv(this)
            dcv = mlpet.PETAutoradiography.loadAif( ...
                 fullfile(this.ecat.filepath, [this.pnum 'ho1.dcv'])); 
        end 
        function dose = itsDose(this)
            taus              = this.times(2:end) - this.times(1:end-1);
            taus(this.length) = taus(this.length - 1);                       
            dose = this.concentration_obs * taus'; % time-integral
            dose = dose / this.itsVolume / this.itsDuration;
        end
        function dura = itsDuration(this)
            dura = this.times(end) - ...
                   this.times(this.indexTakeOff(this.concentration_obs));
        end
        function vol  = itsVolume(this)
            vol = this.mask.count * prod(this.mask.mmppix/10); % mL
        end
        function this = estimateAll(this)
            this = this.estimateParameters(this.map);
            fprintf('FINAL STATS dose            %g\n', this.dose);
            fprintf('FINAL STATS duration        %g\n', this.duration);
            fprintf('FINAL STATS volume          %g\n', this.volume);
            fprintf('FINAL STATS mtt_obs         %g\n',   this.mtt_obs);
            fprintf('FINAL STATS mtt_a           %g\n',   this.mtt_a);
        end   
 	end     
    
    %% PROTECTED
    
    properties (Access = 'protected')
        aif_
        aifShift_
        mask_
        ecat_
        ecatShift_
        dose_ 
        duration_
        volume_
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

