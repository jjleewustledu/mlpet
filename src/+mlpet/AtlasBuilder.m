classdef AtlasBuilder < mlpipeline.AbstractSessionBuilder
	%% ATLASBUILDER  

	%  $Revision$
 	%  was created 29-Mar-2018 00:02:53 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties (Dependent)
 	end

	methods 
        
        %% GET
        
        %%
        
        function t4 = tracer_to_atl_t4(this)
            sd = this.sessionData;            
            t4 = fullfile( ...
                sd.vLocation, ...
                sprintf('%s_to_%s_t4', sd.tracerRevision('typ','fp'), sd.atlas('typ','fp')));
            if (~lexist(t4, 'file'))
                this.build_tracer_to_atl_t4;
            end
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
 		end
    end 
    
    %% PROTECTED
    
    methods (Access = protected)
        function t4 = tracer_to_T1_t4(this)
            sd = this.sessionData;            
            t4 = fullfile( ...
                sd.vLocation, ...
                sprintf('%s_to_%s_t4', sd.tracerRevision('typ','fp'), sd.T1001('typ','fp')));
            if (~lexist(t4, 'file'))
                this.build_tracer_to_T1_t4;
            end            
        end
        function t4 = T1_to_tracer_t4(this)
            sd = this.sessionData;            
            t4 = fullfile( ...
                sd.tracerLocation, ...
                sprintf('%s_to_%s_t4', sd.T1001('typ','fp'), sd.tracerRevision('typ','fp')));
            if (~lexist(t4, 'file'))
                this.build_T1_to_tracer_t4;
            end             
        end
        function t4 = brainmaskr0_to_op_tracer_t4(this, r)
            assert(isnumeric(r));
            sd = this.sessionData;            
            t4 = fullfile( ...
                sd.tracerLocation, ...
                sprintf('brainmaskr%i_to_op_%s_t4', r, sd.tracerRevision('typ','fp')));
            if (~lexist(t4, 'file'))
                this.build_brainmaskr0_to_op_tracer_t4;
            end            
        end
        function t4 = T1_to_atl_t4(this)
            sd = this.sessionData;            
            t4 = fullfile( ...
                sd.vLocation, ...
                sprintf('%s_to_%s_t4', sd.T1001('typ','fp'), sd.atlas('typ','fp')));
            if (~lexist(t4, 'file'))
                this.build_T1_to_atl_t4;
            end
        end        
    end
    
    %% PRIVATE
    
    methods (Access = private)
        function build_tracer_to_atl_t4(this)
            sd = this.sessionData;            
            pwd0 = pushd(sd.vLocation);  
            this.buildVisitor_.t4_mul( ...
                this.tracer_to_T1_t4, this.T1_to_atl_t4, ...
                sprintf('%s_to_%s_t4', sd.tracerRevision('typ','fp'), sd.atlas('typ','fp')));            
            popd(pwd0);
        end
        function build_tracer_to_T1_t4(this)
            sd = this.sessionData;            
            pwd0 = pushd(sd.vLocation);
            this.buildVisitor_.t4_inv( ...
                this.T1_to_tracer_t4, ...
                'out', sprintf('%s_to_%s_t4', sd.tracerRevision('typ','fp'), sd.T1001('typ','fp')));
            popd(pwd0);
        end
        function build_T1_to_tracer_t4(this)
            sd = this.sessionData;            
            pwd0 = pushd(sd.tracerLocation);    
            % using results from mlraichle.TracerDirector.constructCompositeResolved
            this.buildVisitor_.t4_mul( ...
                this.brainmaskr0_to_op_tracer_t4(1), ...
                this.brainmaskr0_to_op_tracer_t4(2), ...
                sprintf('brainmaskr1r2_to_op_%s_t4', sdFdg.tracerRevision('typ','fp'))); 
            popd(pwd0);
        end
        function build_brainmaskr2_to_op_tracer_t4(this)
            mlraichle.TracerDirector.constructCompositeResolved('sessionData', this.sessionData)
        end
        function build_T1_to_atl_t4(this)
            sd = this.sessionData;            
            pwd0 = pushd(sd.vLocation);   
            % mpr2atl_4dfp is prerequisite for freesurfer2mpr_4dfp
            this.buildVisitor_.mpr2atl_4dfp(sd.mprForReconall, 'options', sprintf('-T%s -S711-2B', sd.atlas('typ','fqfp')));         
            this.buildVisitor_.freesurfer2mpr_4dfp(sd.mprForReconall, sd.T1001, 'options', ['-T' sd.atlas('typ','fqfp')]);            
            popd(pwd0);
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

