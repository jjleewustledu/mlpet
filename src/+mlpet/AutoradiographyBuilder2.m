classdef (Abstract) AutoradiographyBuilder2 < mlbayesian.AbstractMcmcProblem
	%% AUTORADIOGRAPHYBUILDER2 

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
        SMALL_LARGE_HCT = 0.85  % Grubb et al., 1978, Videen et al., 1987
        TIME_SUP = 200          % sec
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
        conc_crv
        conc_dcv
        mask
        dose
        duration
        volume
    end
    
    methods %% GET
        function p = get.pnum(~)
            p = str2pnum(pwd);
        end
        function d  = get.conc_crv(this)
            assert(~isempty(this.conc_crv_));
            d = this.conc_crv_;
        end
        function d  = get.conc_dcv(this)
            assert(~isempty(this.conc_dcv_));
            d = this.conc_dcv_;
        end
        function d  = get.mask(this)
            assert(~isempty(this.maskObj_));
            d = this.maskObj_;
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
        function this = load(varargin)  %#ok<VANUS>
            this = [];
        end
        function this = loadDcv(varargin)  %#ok<VANUS>
            this = [];
        end
        function this = loadCrv(varargin)  %#ok<VANUS>
            this = [];
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
            error('mlpet:requiredObjectNotFound', 'AutoradiographyBuilder2.loadEcat');
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
            error('mlpet:requiredObjectNotFound', 'AutoradiographyBuilder2.loadDecayCorrectedEcat');
        end
        function mask = loadMask(varargin)
            p = inputParser;
            addOptional(p, 'fqfn',    [], @(x) lexist(x, 'file'));
            addOptional(p, 'iniftid', [], @(x) isa(x, 'mlfourd.INIfTI'));
            parse(p, varargin{:});
            
            if (~isempty(p.Results.fqfn))
                mask = mlfourd.MaskingNIfTId.load(p.Results.fqfn);
                return
            end
            if (~isempty(p.Results.iniftid))
                mask = p.Results.iniftid;
                return
            end
            error('mlpet:requiredObjectNotFound', 'AutoradiographyBuilder2.loadMask');
        end         
        function f    = invs_to_mLmin100g(f)
            f = 100 * 60 * f / mlpet.AutoradiographyBuilder2.BRAIN_DENSITY;
        end           
        function tito = indexTakeOff(curve)
            maxCurve = max(curve);
            minCurve = min(curve);
            for ti = 1:length(curve)
                if (curve(ti) - minCurve > 0.05 * (maxCurve - minCurve))
                    break;
                end
            end
            tito = max(1, ti - 1);
        end
        function m    = moment1(t, c)
            tto = t(mlpet.AutoradiographyBuilder2.indexTakeOff(c));
            m = sum((t - tto) .* c) / sum(c);
        end
        function c    = myPchip(t0, c0, t)
            if (t(end) > t0(end))
                t0(end+1) = t(end);
                c0(end+1) = c0(end);
            end
            c = pchip(t0, c0, t);
        end    
        function [times,counts] = shiftData(times0, counts0, Dt)
            import mlpet.*
            if (Dt > 0)
                [times,counts] = AutoradiographyBuilder2.shiftDataRight(times0, counts0, Dt);
            else
                [times,counts] = AutoradiographyBuilder2.shiftDataLeft( times0, counts0, Dt);
            end
        end
        function [times,counts] = shiftDataLeft(times0, counts0, Dt)
            %  Dt in sec
            Dt     = abs(Dt);
            idx_0  = floor(sum(double(times0 < Dt + times0(1)))+1);
            times  = times0(idx_0:end);
            times  = times - times(1);
            counts = counts0(idx_0:end);
            counts = counts - min(counts);
        end
        function [times,counts] = shiftDataRight(times0, counts0, Dt)
            %  Dt in sec
            Dt     = abs(Dt);
            lenDt  = ceil(Dt/(times0(2) - times0(1)));
            newLen = length(counts0) + lenDt;
            
            times0 = times0 - times0(1) + Dt;
            times  = [0:1:lenDt-1 times0];
            counts = counts0(1) * ones(1,newLen);            
            counts(end-length(counts0)+1:end) = counts0;
            counts = counts - min(counts);
        end
    end
    
	methods
 		function this = AutoradiographyBuilder2(times, conc_ecat, varargin) 
 			%% AUTORADIOGRAPHYBUILDER2  

 			this = this@mlbayesian.AbstractMcmcProblem(times, conc_ecat); 
            ip = inputParser;
            addRequired(ip, 'times',     @isnumeric);
            addRequired(ip, 'conc_ecat', @isnumeric);
            addRequired(ip, 'conc_crv',  @isnumeric);
            addRequired(ip, 'conc_dcv',  @isnumeric);  
            addRequired(ip, 'maskObj',   @(x) isa(x, 'mlfourd.MaskingNIfTId'));  
            parse(ip, times, conc_ecat, varargin{:});
            
            this.conc_crv_ = ip.Results.conc_crv;
            this.conc_dcv_ = ip.Results.conc_dcv;
            this.maskObj_  = ip.Results.maskObj;
            this.dose_     = this.itsDose; 
            this.duration_ = this.itsDuration;
            this.volume_   = this.itsVolume;
        end
        
        function dose = itsDose(this)
            taus              = this.times(2:end) - this.times(1:end-1);
            taus(this.length) = taus(this.length - 1);                       
            dose = this.dependentData * taus'; % time-integral
            dose = dose / this.itsVolume / this.itsDuration;
        end
        function dura = itsDuration(this)
            dura = this.times(end) - ...
                   this.times(this.indexTakeOff(this.dependentData));
        end
        function vol  = itsVolume(this)
            vol = this.mask.count * prod(this.mask.mmppix/10); % mL
        end
        function this = estimateAll(this)
            this = this.estimateParameters(this.map);
            fprintf('FINAL STATS dose            %g\n', this.dose);
            fprintf('FINAL STATS duration        %g\n', this.duration);
            fprintf('FINAL STATS volume          %g\n', this.volume);
        end   
        function        plotInitialData(this)
            figure;
            max_aif  = max([max(this.conc_crv) max(this.conc_dcv)]);
            max_ecat = max(this.conc_ecat);
            plot(this.times, this.conc_dcv /max_aif, ...
                 this.times, this.conc_crv /max_aif, ...
                 this.times, this.conc_ecat/max_ecat);
            title(sprintf('%s plotInitialData', this.baseTitle), 'Interpreter', 'none');
            legend('conc_{dcv}', 'conc_{crv}', 'conc_{ecat}');
            xlabel(this.xLabel);
            ylabel(sprintf('%s; rescaled %g, %g', this.yLabel, max_aif, max_ecat));
        end      
        function this = save(this)
            this = this.saveas(sprintf('%s.save.mat', class(this)));
        end
        function this = saveas(this, fn)
            autoradiographyBuilder2 = this; %#ok<NASGU>
            save(fn, 'autoradiographyBuilder2');   
        end   
 	end     
    
    %% PROTECTED
    
    properties (Access = 'protected')
        conc_crv_
        conc_dcv_
        maskObj_
        dose_ 
        duration_
        volume_
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

