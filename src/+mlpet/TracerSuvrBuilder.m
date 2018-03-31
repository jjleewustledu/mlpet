classdef TracerSuvrBuilder < mlpipeline.AbstractSessionBuilder
	%% TRACERSUVRBUILDER  

	%  $Revision$
 	%  was created 28-Mar-2018 22:00:52 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.  Copyright 2018 John Joowon Lee.

    properties (Constant)
        SUPPORTED_TRACERS = {'FDG' 'OC' 'OO' 'HO'}
    end
    
    properties 
        tracerKind = 'tracerResolvedFinalOpFdg' % method@SessionData
    end

	methods   
        function obj = atlas(this, varargin)
            fqfn = fullfile(getenv('REFDIR'), 'TRIO_Y_NDC_333.4dfp.ifh');
            obj  = this.sessionData.fqfilenameObject(fqfn, varargin{:});
        end
        function p = buildAll(this)
            for tr = 1:length(this.SUPPORTED_TRACERS)
                for sc = 1:3
                    if (strcmpi(this.SUPPORTED_TRACERS{tr}, 'FDG') && sc ~= 1)
                        break
                    end
                    try
                        this.snumber = sc;
                        this.tracer = this.SUPPORTED_TRACERS{tr};
                        this = this.buildTimeContraction;
                        this = this.buildOnAtl;
                        this = this.buildTracer;
                    catch ME
                        dispwarning(ME);
                    end
                end                
            end
            p    = {};
            this = this.buildCbf;
            p    = [p this.product];
            this = this.buildCbv;
            p    = [p this.product];
            this = this.buildOef;
            p    = [p this.product];
            this = this.buildCmro2;
            p    = [p this.product];
            this = this.buildCmrglc;
            p    = [p this.product];
            this = this.buildOgi;
            p    = [p this.product];
            this = this.buildAgi;
            p    = [p this.product];
        end
        function [this,tw] = buildTimeContraction(this)
            nn = mlfourd.NumericalNIfTId.load(this.tracerObj);
            [w,nn1] = this.timeWindowIndices(nn);
            this.product_ = nn.timeContracted(w);
            this.product_.fqfilename = this.tracerTimeWindowed;
            this.product_.save;
            tw = nn1.img; % xlabel('frame indices'); ylabel(sprintf('\\Sigma_{x} activity(%s(x)) in Bq', tracer));
        end
        function this = buildOnAtl(this)
            sdFdg = this.sessionData;
            sdFdg.tracer = 'FDG';
            t4 = fullfile(this.vLocation, sprintf('%s_to_TRIO_Y_NDC_t4', sdFdg.tracerRevision('typ','fp')));
            this.buildVisitor_.t4img_4dfp( ...
                t4, this.tracerTimeWindowed, 'out', this.tracerTimeWindowedOnAtl, 'options', '-O333');
            this = this.packageProduct(this.tracerTimeWindowedOnAtl);
        end
        function this = buildTracer(this)
            import mlfourd.*;
            msk = NumericalNIfTId.load( ...
                fullfile(getenv('REFDIR'), 'glm_atlas_mask_333.4dfp.ifh'));
            msk.img = double(msk.img > 0);
            tracerTW = NumericalNIfTId.load(this.tracerTimeWindowedOnAtl);
            expect = tracerTW.volumeAveraged(msk);
            assert(isscalar(expect.img));
            this.product_ = tracerTW / expect.img;
            this.product_.fqfilename = this.tracerSuvr;
            this.product_.save;
        end
        function this = buildCbf(this)
            assert(lexist(this.tracerSuvrNamed('ho'), 'file'));
            this = this.packageProduct(this.tracerSuvrNamed('ho'));
        end
        function this = buildCbv(this)
            assert(lexist(this.tracerSuvrNamed('oc'), 'file'));
            this = this.packageProduct(this.tracerSuvrNamed('oc'));
        end
        function this = buildCmrglc(this)
            assert(lexist(this.tracerSuvrNamed('fdg'), 'file'));
            this = this.packageProduct(this.tracerSuvrNamed('fdg'));
        end
        function [this,cmro2,oef,msk] = buildBetas(this)
            import mlfourd.*;
            msk = NumericalNIfTId.load( ...
                fullfile(getenv('REFDIR'), 'glm_atlas_mask_333.4dfp.ifh'));
            msk_ = logical(msk.img > 0);
            cbf  = this.tracerSuvrNamed('ho', 'typ', 'numericalNiftid');  
            cbv  = this.tracerSuvrNamed('oc', 'typ', 'numericalNiftid');            
            y    = this.tracerSuvrNamed('oo', 'typ', 'numericalNiftid');
            cbf_ = ensureColVector(squeeze(cbf.img(msk_)));
            cbv_ = ensureColVector(squeeze(cbv.img(msk_)));
            y_   = ensureColVector(squeeze(  y.img(msk_)));
            
            % nonlinear regression
            tbl = table(cbf_, cbv_, y_);            
            mdlfun = @(b,x) b(1)*x(:,1) + b(2)*x(:,2);
            beta0 = [1 1];
            mdl = fitnlm(tbl, mdlfun, beta0);
            beta1 = mdl.Coefficients{1, 'Estimate'};
            beta2 = mdl.Coefficients{2, 'Estimate'};
            disp(mdl)           
            [mdl.RMSE min(y_) max(y_)] %#ok<NOPRT>
            this.product_ = mdl;
            
            % assign cmro2, oef
            cmro2 = y - cbv * beta2;
            cmro2.fqfilename = this.tracerSuvrNamed('cmro2');
            cmro2.save;  
            
            oef = cmro2 ./ (cbf * beta1);
            oef.fqfilename = this.tracerSuvrNamed('oef');
            oef.save;              
        end        
        function this = buildOef(this)
            assert(lexist(this.tracerSuvrNamed('oef'), 'file'));
            this = this.packageProduct(this.tracerSuvrNamed('oef'));
        end
        function this = buildCmro2(this)
            assert(lexist(this.tracerSuvrNamed('cmro2'), 'file'));
            this = this.packageProduct(this.tracerSuvrNamed('cmro2'));
        end
        function [this,ogi,agi] = buildGlcMetab(this)
            assert(lexist(this.tracerSuvrNamed('cmro2'), 'file'));            
            assert(lexist(this.tracerSuvrNamed('fdg'),   'file'));
            cmro2  = this.tracerSuvrNamed('cmro2', 'typ', 'numericalNiftid');
            cmrglc = this.tracerSuvrNamed('fdg',   'typ', 'numericalNiftid');
            
            ogi = (cmro2 ./ cmrglc) * 5.4;
            ogi.fqfilename = this.tracerSuvrNamed('ogi');
            ogi.save;            
            
            agi = cmrglc - cmro2/6;
            agi.fqfilename = this.tracerSuvrNamed('agi');
            agi.save;            
        end
        function this = buildOgi(this)
            assert(lexist(this.tracerSuvrNamed('ogi'), 'file'));
            this = this.packageProduct(this.tracerSuvrNamed('ogi'));
        end
        function this = buildAgi(this)
            assert(lexist(this.tracerSuvrNamed('agi'), 'file'));
            this = this.packageProduct(this.tracerSuvrNamed('agi'));
        end
        
        
        
        
        function this   = instanceConstructCompositeResolved__(this, varargin)
            %% INSTANCECONSTRUCTCOMPOSITERESOLVED
            %  @param named target is the filename of a target, recognizable by mlfourd.ImagingContext.ctor;
            %  the default target is this.tracerResolvedFinal('epoch', this.sessionData.epoch) for FDG;
            %  see also TracerDirector.tracerResolvedTarget.
            %  @param this.anatomy is char; it is the sessionData function-name for anatomy in the space of
            %  this.sessionData.T1; e.g., 'T1', 'T1001', 'brainmask'.
            %  @result ready-to-use t4 transformation files aligned to this.tracerResolvedTarget.
            
            bv = this.builder_.buildVisitor;
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'target', '', @ischar);
            parse(ip, varargin{:});
            [~,icTarg] = this.tracerResolvedTarget('target', ip.Results.target, 'tracer', 'FDG');   
            
            pwd0 = pushd(this.sessionData.vLocation);         
            bv.lns_4dfp(icTarg.fqfileprefix);
            icTarg.filepath = pwd;
            this.builder_ = this.builder_.packageProduct(icTarg); % build everything resolved to FDG
            bv.ensureLocalFourdfp(this.sessionData.T1001);
            bv.ensureLocalFourdfp(this.sessionData.(this.anatomy));  
            this.builder_ = this.builder_.resolveModalitiesToProduct( ...
                this.localTracerResolvedFinalSumt, varargin{:});            
            
            cRB = this.builder_.compositeResolveBuilder;
            this.localTracerResolvedFinal(cRB, icTarg);            
            deleteExisting('*_b15.4dfp.*');
            popd(pwd0);            
        end
        
        
        
        
        function [w,nn] = timeWindowIndices(this, nn)
            %  @param nn := NumericalNIfTId of dynamic data.
            %  @return w := [idx0 idxF] for sessd.tracer.
            %  @return nn := volumeSummed@NumericalNIfTId of dynamic data.
            
            sd = this.sessionData;
            nn = nn.volumeSummed * prod(nn.mmppix/10); % activity in Bq
            [~,idx0] = max(nn.img > 0.1*max(nn.img));
            
            % consider delay
            idxD = idx0;
            while (idxD < length(nn.img) && ...
                   sd.times(idxD) - sd.times(idx0) < sd.timeWindowDelaySuvr)
                idxD = idxD + 1; % per Blazey, unpublished
            end
            
            % consider duration
            idxF = idxD;
            while (idxF < length(nn.img) && ...
                   sd.times(idxF) - sd.times(idxD) < sd.timeWindowDurationSuvr)
                idxF = idxF + 1;
            end
            w = [idxD idxF];            
        end
        function obj    = tracerObj(this, varargin)
            obj = this.sessionData.(this.tracerKind)(varargin{:});
        end
        function obj   = tracerSuvr(this, varargin)
            obj = this.sessionData.tracerSuvr(varargin{:});
        end
        function obj   = tracerSuvrNamed(this, name, varargin)
            sd = this.sessionData;
            switch (upper(name))
                case {'FDG' 'OC' 'OO' 'HO'}
                    sd.tracer = upper(name);
                otherwise
                    sd.tracer = '';
            end
            obj = sd.tracerSuvrNamed(name, varargin{:});
        end
        function obj   = tracerTimeWindowed(this, varargin)
            obj = this.sessionData.tracerTimeWindowed(varargin{:});
        end
        function obj   = tracerTimeWindowedOnAtl(this, varargin)
            obj = this.sessionData.tracerTimeWindowedOnAtl(varargin{:});
        end
        function s      = volumeSum(~, obj)
            ic = mlfourd.ImagingContext(obj);
            nn = ic.numericalNiftid;
            vs = nn.volumeSummed;
            s  = double(vs.img);
            assert(isscalar(s));
        end
        function s      = volumeAverage(~, obj)
            import mlfourd.*;
            msk = NumericalNIfTId.load( ...
                fullfile(getenv('REFDIR'), 'glm_atlas_mask_333.4dfp.ifh'));
            msk.img = double(msk.img > 0);
            ic = ImagingContext(obj);
            nn = ic.numericalNiftid;
            expect = nn.volumeAveraged(msk);
            assert(isscalar(expect.img));
            s = double(expect.img);
        end
        
 		function this = TracerSuvrBuilder(varargin)
 			this = this@mlpipeline.AbstractSessionBuilder(varargin{:});
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

