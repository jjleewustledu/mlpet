classdef AtlasBuilder < mlpipeline.AbstractSessionBuilder
	%% ATLASBUILDER  

	%  $Revision$
 	%  was created 29-Mar-2018 00:02:53 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.  Copyright 2018 John Joowon Lee.
 	
    properties
        refreshMprForReconall
        forceRebuildT1ToTracer
        forceRebuildTracerToT1
    end
    
    methods (Static)
        function buildAll(varargin)
            this = mlpet.AtlasBuilder(varargin{:});
            assert(lexist(this.tracer_to_atl_t4, 'file'));
        end
    end

	methods       
        function mpr = mprForReconall(this, varargin)  
            sd = this.sessionData;  
            pwd0 = pushd(sd.mprForReconall('typ','path'));   
            
            if (this.refreshMprForReconall)
                mpr_ = sd.mprForReconall('typ','fp');
                mpr__ = [mpr_ '_'];
                deleteExisting([mpr_ '.nii']);
                zzo = sd.zeroZeroOne;
                this.buildVisitor_.mri_convert(zzo.fqfilename, [mpr__ '.nii']);
                deleteExisting([mpr_ '.4dfp.*'])
                this.buildVisitor_.nifti_4dfp_4(mpr__);
                this.buildVisitor_.flip_4dfp('xz', mpr__, mpr_);
                deleteExisting([mpr__ '.4dfp.*'])                       
            end
            
            mpr = sd.mprForReconall(varargin{:});
            popd(pwd0);            
        end
        function s = mprSeriesNumber(this)
            [~,r] = mlbash(sprintf('head %s.4dfp.img.rec', this.sessionData.mprForReconall('typ','fqfp')));
            lbl = 't1_mprage_sag_series';
            foundt1 = strfind(r, lbl);
            found4dfp = strfind(r, '.4dfp');
            if (isempty(foundt1) || isempty(found4dfp))
                s = [];
                return
            end
            s = str2double(foundt1(1)+length(lbl):found4dfp(1)-1);
        end
        function refreshMpr(this)
            this.buildVisitor_.copyfile_4dfp( ...
                this.sessionData.t1MprageSagSeriesForReconall('typ','fqfp'), ...
                this.sessionData.mprForReconall('typ','fqfp'), 'f');
        end
		  
 		function this = AtlasBuilder(varargin)
 			%% ATLASBUILDER
 			%  Usage:  this = AtlasBuilder()

 			this = this@mlpipeline.AbstractSessionBuilder(varargin{:});
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'forceRebuildT1ToTracer', false, @islogical);
            addParameter(ip, 'forceRebuildTracerToT1', false, @islogical);
            addParameter(ip, 'refreshMprForReconall', false, @islogical);
            parse(ip, varargin{:});            
            this.forceRebuildT1ToTracer = ip.Results.forceRebuildT1ToTracer;
            this.forceRebuildTracerToT1 = ip.Results.forceRebuildTracerToT1;
            this.refreshMprForReconall = ip.Results.refreshMprForReconall;
            this.sessionData_.attenuationCorrected = true;
        end
         
        function t4 = brainmaskr0_to_op_tracer_t4(this, r)
            assert(isnumeric(r));
            sd = this.sessionData; 
            t4 = fullfile( ...
                sd.tracerLocation, ...
                sprintf('brainmaskr%i_to_op_%s_t4', r, sd.tracerResolvedFinalSumt('typ','fp')));
            if (~lexist(t4, 'file'))
                this.build_brainmaskr0_to_op_tracer_t4;
            end            
        end
        function t4 = T1_to_atl_t4(this)
            sd = this.sessionData;            
            t4 = fullfile( ...
                sd.subjectsDir, 'atlasTest', 'source', ...
                sprintf('%s_V%i_T1001_to_%s_t4', sd.sessionFolder, sd.vnumber, sd.studyAtlas('typ','fp')));
            assert(lexist(t4, 'file'))
        end   
        function t4 = T1_to_tracer_t4(this)
            if (this.forceRebuildT1ToTracer)
                t4 = this.build_T1_to_tracer_t4;
                return
            end      
            
            sd = this.sessionData;    
            sdr1 = sd;
            sdr1.rnumber = 1;            
            t4 = fullfile( ...
                sd.tracerLocation, ...
                sprintf('%sr1r2_to_op_%s_t4', sd.brainmask('typ','fp'), sdr1.tracerRevision('typ','fp')));
            if (~lexist(t4, 'file'))
                t4 = fullfile( ...
                sd.tracerLocation, ...
                sprintf('%sr2_to_%sr2_t4', sd.brainmask('typ','fp'), sd.tracerResolvedFinalSumt('typ','fp')));
            end          
        end   
        function t4 = tracer_to_atl_t4(this)
            sd = this.sessionData;            
            t4 = fullfile( ...
                sd.vLocation, ...
                sprintf('%s_to_%s_t4', sd.tracerResolvedFinalSumt('typ','fp'), sd.studyAtlas('typ','fp')));
            if (~lexist(t4, 'file'))
                this.build_tracer_to_atl_t4;
            end
        end
        function t4 = tracer_to_T1_t4(this)
            sd = this.sessionData;            
            t4 = fullfile( ...
                sd.tracerLocation, ...
                sprintf('%sr1_to_op_%s_t4', sd.tracerResolvedFinalSumt('typ','fp'), sd.T1001('typ','fp')));
            if (~lexist(t4, 'file') || this.forceRebuildTracerToT1)
                t4 = this.build_tracer_to_T1_t4;
            end            
        end  
    end
    
    %% PRIVATE
    
    methods (Access = private)
        function build_brainmaskr0_to_op_tracer_t4(this)
            mlraichle.TracerDirector.constructCompositeResolved('sessionData', this.sessionData)
        end
        function build_T1_to_atl_t4(this)
            sd = this.sessionData;            
            pwd0 = pushd(sd.vLocation);   
            this.mprForReconall;
            T1001_ = sd.T1001('typ','fp');
            this.buildVisitor_.mpr2atl_4dfp( ...
                T1001_, 'options', sprintf('-T%s -S711-2B', sd.atlas('typ','fqfp')));
            popd(pwd0);
        end
        function t4 = build_T1_to_tracer_t4(this)    
            sd = this.sessionData;            
            pwd0 = pushd(sd.vLocation);
            
            bv = this.buildVisitor;
            asssert(lexist(this.tracer_to_atl_t4, 'file'))
            bv.msktgen_4dfp(sd.tracerResolvedFinalSumt('typ','fqfp'), 'options', ['-T' sd.atlas.fqfileprefix]);
            bv.t4_resolve();            
            t4 = fullfile(sd.vLocation, [sd.T1001('typ','fp') '_to_op_' sd.tracerRevision('typ','fp')]);
            popd(pwd0);
        end
        function t4 = build_tracer_to_atl_t4(this)
            sd = this.sessionData;            
            pwd0 = pushd(sd.vLocation);  
            t4 = this.buildVisitor_.t4_mul( ...
                this.tracer_to_T1_t4, this.T1_to_atl_t4, ...
                sprintf('%s_to_%s_t4', sd.tracerResolvedFinalSumt('typ','fp'), sd.studyAtlas('typ','fp')));            
            popd(pwd0);
        end
        function t4 = build_tracer_to_T1_t4(this)
            sd = this.sessionData;
            sd.tracer = 'FDG';
            sd.attenuationCorrected = true;
            sd.resolveTag = 'op_T1001';
            pwd0 = pushd(sd.tracerLocation);      
            bldr = mlpet.TracerBuilder('sessionData', sd);
            bldr = bldr.packageProduct(sd.tracerResolvedFinalSumt);
            bldr.resolveProductToAnatomy;
            t4   = sprintf('%s_to_%s_t4', sd.tracerResolvedFinalSumt('typ','fqfp'), sd.resolveTag);
            popd(pwd0);
        end
    end
    
    %% HIDDEN
    
    methods (Hidden)
        function build_T1_to_atl_t4__(this)
            %  BROKEN
            
            sd = this.sessionData;            
            pwd0 = pushd(sd.vLocation);   
            % mpr2atl_4dfp for mpr is prerequisite for freesurfer2mpr_4dfp
            this.mprForReconall;
            mpr_   = sd.mprForReconall('typ','fp');
            T1001_ = sd.T1001('typ','fp');
            atl_   = sd.atlas('typ','fp');
            this.buildVisitor_.mpr2atl_4dfp( ...
                mpr_, 'options', sprintf('-T%s -S711-2B', sd.atlas('typ','fqfp')));
            this.buildVisitor_.freesurfer2mpr_4dfp( ...
                mpr_, T1001_, 'options', ['-T' sd.atlas('typ','fqfp')]);
            % writes T1001_to_mpr_t4
            this.buildVisitor_.t4_mul( ...
                sprintf('%s_to_%s_t4', T1001_,  mpr_), ...
                sprintf('%s_to_%s_t4', mpr_, atl_), ...
                sprintf('%s_to_%s_t4', T1001_,  atl_));
            popd(pwd0);
        end        
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

