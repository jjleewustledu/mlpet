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
        atlasVoxelSize = 333;
        rebuild = true;
        tracerKind = 'tracerResolvedFinalOpFdg' % method@SessionData
    end

	methods   
        function obj = atlas(this, varargin)
            fqfn = fullfile(this.sessionData.subjectsDir, 'jjlee2', 'atlasTest', 'source', 'HYGLY_atlas.4dfp.ifh');
            obj  = this.sessionData.fqfilenameObject(fqfn, varargin{:});
        end
        function p = buildAll(this)
            for tr = 1:length(this.SUPPORTED_TRACERS)
                tracers_ = {};
                for sc = 1:3
                    warning('off', 'MATLAB:InputParser:ArgumentFailedValidation');
                    if (strcmpi(this.SUPPORTED_TRACERS{tr}, 'FDG') && sc ~= 1)
                        break
                    end
                    try
                        this.snumber = sc;
                        this.tracer = this.SUPPORTED_TRACERS{tr};
                        this = this.buildTimeContraction;
                        this = this.buildOnAtl;
                        this = this.buildTracer;
                        tracers_ = [tracers_ {this.product}]; %#ok<AGROW> % accumulate scans of OC, OO, HO
                        fprintf('mlpet.TracerSuvrBuilder.buildAll:  %s, s%i\n', ...
                            this.SUPPORTED_TRACERS{tr}, sc);
                    catch ME
                        dispwarning(ME);
                    end
                    warning('on', 'MATLAB:InputParser:ArgumentFailedValidation');
                end                
                this = this.buildTracerSuvrAveraged(tracers_{:});
            end
            p    = {};
            this = this.buildCbf;
            p    = [p {this.product}];
            this = this.buildCbv;
            p    = [p {this.product}];
            this = this.buildCmrglc;
            p    = [p {this.product}];
            this = this.buildBetas;
            p    = [p this.product]; % cmro2, oef
            this = this.buildGlcMetab;
            p    = [p {this.product}];
        end
        function [this,tw] = buildTimeContraction(this)
            try
                if (lexist(this.tracerTimeWindowed, 'file') && ~this.rebuild)
                    this = this.packageProduct(this.tracerTimeWindowed);
                    return
                end            
                
                if (~lexist(this.tracerObj, 'file'))
                    tw = [];
                    this.product_ = [];
                    return
                end
                nn = mlfourd.NumericalNIfTId.load(this.tracerObj);
                [w,nn1] = this.timeWindowIndices(nn);
                this.product_ = nn.timeContracted(w);
                this.product_.fqfilename = this.tracerTimeWindowed;
                this.product_.save;
            catch ME
                handwarning(ME);
            end
            this.product_ = mlfourd.ImagingContext(this.product_);
            tw = nn1.img; % xlabel('frame indices'); ylabel(sprintf('\\Sigma_{x} activity(%s(x)) in Bq', tracer));
        end
        function this = buildOnAtl(this)
            if (lexist(this.tracerTimeWindowedOnAtl, 'file') && ~this.rebuild)
                this = this.packageProduct(this.tracerTimeWindowedOnAtl);
                return
            end
            sdFdg = this.sessionData;
            sdFdg.tracer = 'FDG';
            t4 = this.atlBuilder_.tracer_to_atl_t4;
            assert(lexist(t4, 'file'));
            this.buildVisitor_.t4img_4dfp( ...
                t4, this.tracerTimeWindowed,...
                'out', this.tracerTimeWindowedOnAtl('typ','fqfp'), ...
                'options', sprintf('-O%s_%i', this.sessionData.studyAtlas('typ','fqfp'), this.atlasVoxelSize));
            this = this.packageProduct(this.tracerTimeWindowedOnAtl);
        end
        function this = buildTracer(this)
            if (lexist(this.tracerSuvr, 'file') && ~this.rebuild)
                this = this.packageProduct(this.tracerSuvr);
                return
            end
            import mlfourd.*;
            msk = NumericalNIfTId.load( ...
                fullfile(getenv('REFDIR'), sprintf('glm_atlas_mask_%i.4dfp.ifh', this.atlasVoxelSize)));
            msk.img = double(msk.img > 0);
            tracerTW = NumericalNIfTId.load(this.tracerTimeWindowedOnAtl);
            expect = tracerTW.volumeAveraged(msk);
            assert(isscalar(expect.img));
            tracerTW = tracerTW / expect.img;
            tracerTW.fqfilename = this.tracerSuvr;
            tracerTW.save;
            this.product_ = mlfourd.ImagingContext(tracerTW);
        end
        function this = buildTracerSuvrAveraged(this, varargin)
            varargin_ = varargin;
            assert(~isempty(varargin_));
            argin_ = varargin_{1};
            assert(isa(argin_, 'mlfourd.ImagingContext'));
            
            if (strcmpi(this.tracer, 'FDG'))
                this = this.packageProduct(this.tracerSuvrAveraged);
                return
            end

            try
                if (1 == length(varargin_))
                    argin_.saveas(this.tracerSuvrAveraged);
                    this = this.packageProduct(this.tracerSuvrAveraged);
                    return
                end

                img = zeros(size(argin_.niftid));
                v = 1;
                while (v <= length(varargin_))
                    nii = varargin_{v}.niftid;
                    img = img + nii.img;
                    v = v + 1;
                end
                img = img/length(varargin_);
                nii.img = img;
                nii.fqfileprefix = this.tracerSuvrAveraged('typ','fqfp');
                nii.save;
                this = this.packageProduct(nii);
            catch ME
                dispexcept(ME);
            end
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
        function [this,cmro2,oef,msk,mdl] = buildBetas(this)
            import mlfourd.*;
            msk = NumericalNIfTId.load( ...
                fullfile(getenv('REFDIR'), 'glm_atlas_mask_333.4dfp.ifh'));
            msk_ = logical(msk.img > 0);
            msk  = mlfourd.ImagingContext(msk);
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
                   
            this.product_ = {mlfourd.ImagingContext(cmro2) mlfourd.ImagingContext(oef)};
        end        
        function this = buildOef(this)
            assert(lexist(this.tracerSuvrNamed('oef'), 'file'));
            this = this.packageProduct(this.tracerSuvrNamed('oef'));
        end
        function this = buildCmro2(this)
            assert(lexist(this.tracerSuvrNamed('cmro2'), 'file'));
            this = this.packageProduct(this.tracerSuvrNamed('cmro2'));
        end
        function [this,ogi] = buildGlcMetab(this)
            assert(lexist(this.tracerSuvrNamed('cmro2'), 'file'));            
            assert(lexist(this.tracerSuvrNamed('fdg'),   'file'));
            cmro2  = this.tracerSuvrNamed('cmro2', 'typ', 'numericalNiftid');
            cmrglc = this.tracerSuvrNamed('fdg',   'typ', 'numericalNiftid');
            
            ogi = (cmro2 ./ cmrglc) * 5.4;
            ogi.fqfilename = this.tracerSuvrNamed('ogi');
            ogi.save;
            ogi = mlfourd.ImagingContext(ogi);
            
            this.product_ = ogi;
        end
        function this = buildOgi(this)
            assert(lexist(this.tracerSuvrNamed('ogi'), 'file'));
            this = this.packageProduct(this.tracerSuvrNamed('ogi'));
        end
        function this = buildAgi(this)
            assert(lexist(this.tracerSuvrNamed('agi'), 'file'));
            this = this.packageProduct(this.tracerSuvrNamed('agi'));
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
        function obj    = tracerSuvr(this, varargin)
            obj = this.sessionData.tracerSuvr(varargin{:});
        end
        function obj    = tracerSuvrAveraged(this, varargin)
            if (strcmpi(this.tracer, 'FDG'))
                obj = this.tracerSuvrNamed('fdg', varargin{:});
                return
            end
            obj = this.sessionData.tracerSuvrAveraged(varargin{:});
        end
        function obj    = tracerSuvrNamed(this, name, varargin)
            sd = this.sessionData;
            switch (upper(name))
                case {'FDG' 'OC' 'OO' 'HO'}
                    sd.tracer = upper(name);
                otherwise
                    sd.tracer = '';
            end
            obj = sd.tracerSuvrNamed(name, varargin{:});
        end
        function obj    = tracerTimeWindowed(this, varargin)
            obj = this.sessionData.tracerTimeWindowed(varargin{:});
        end
        function obj    = tracerTimeWindowedOnAtl(this, varargin)
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
            this.atlBuilder_ = mlpet.AtlasBuilder( ...
                'sessionData', this.sessionData);
 		end
    end 
    
    %% PRIVATE
    
    properties (Access = private)
        atlBuilder_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

