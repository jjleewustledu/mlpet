classdef ResamplingRestrictedResolveBuilder < mlfourdfp.AbstractSessionBuilder
	%% RESAMPLINGRESTRICTEDRESOLVEBUILDER  

	%  $Revision$
 	%  was created 16-Jul-2019 21:40:18 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.6.0.1135713 (R2019a) Update 3 for MACI64.  Copyright 2019 John Joowon Lee.
 	
	properties
 		
 	end

	methods         
        function this = reconstituteFramesAC3(this)
            %% creates motion corrected frames using previously built t4_resolve t4s.
            %  Creates composition of t4s and creates motion correction with single resampling.
            %  TODO:  manage case in which: 
            %  - EN has only a single time frame and no t4s
            %  - Ei has no frames with significant counts
            
            import mlsystem.DirTool
            pthFdg = this.sessionData.scanPath;
            pthT4 = fullfile(pthFdg, 't4', '');
            ensuredir(pthT4);
            pwd0 = pushd(pthFdg); 
            mle = this.sessionData.maxLengthEpoch;
            Ne = this.sessionData.supEpoch;
            Nf = mle*ones(1,Ne);
            Nf(end) = length(this.sessionData.times)-(Ne-1)*mle;
            
            %% within folder for epoch Ei
            
            for e = 1:Ne
                pwd1 = pushd(sprintf('E%i', e));
                for f = 1:Nf(e)
                    try
                        assert(isfile(this.frame_to_op_frame_t4('epoch', e, 'frame', f, 'r', 1)))
                        assert(isfile(this.frame_to_op_frame_t4('epoch', e, 'frame', f, 'r', 2)))
                        this.buildVisitor.t4_mul( ...
                            this.frame_to_op_frame_t4('epoch', e, 'frame', f, 'r', 1), ...
                            this.frame_to_op_frame_t4('epoch', e, 'frame', f, 'r', 2), ...
                            this.frame_to_op_frame_t4('epoch', e, 'frame', f, 'r', [1 2]));
                    catch ME %#ok<NASGU>
                        dest_t4 = this.frame_to_op_frame_t4('epoch', e, 'frame', f, 'r', [1 2]);
                        warning('mlpet:EAFP', 'using trivial %s', dest_t4)
                        this.buildVisitor.t4_ident(dest_t4)
                    end
                end 
                popd(pwd1);
            end
            
            %% within folder for epoch E1toN
            
            cd(fullfile(pthFdg, sprintf('E1to%i', Ne), ''));
            for e = 1:Ne
                try
                    this.buildVisitor.t4_mul( ...
                        this.frame_to_op_frame_t4('epoch', 1:Ne, 'frame', e, 'r', 1), ...
                        this.frame_to_op_frame_t4('epoch', 1:Ne, 'frame', e, 'r', 2), ...
                        this.frame_to_op_frame_t4('epoch', 1:Ne, 'frame', e, 'r', [1 2]));
                catch ME %#ok<NASGU>
                    dest_t4 = this.frame_to_op_frame_t4('epoch', 1:Ne, 'frame', e, 'r', [1 2]);
                    warning('mlpet:EAFP', 'using trivial %s', dest_t4)
                    this.buildVisitor.t4_ident(dest_t4)
                end
            end 
            
            %% work inside pthT4, calling t4_mul and t4img_4dfp 
            %  to create motion corrections with restricted resampling
            
            cd(pthFdg);
            tra = lower(this.sessionData.tracer);
            ifc = mlfourd.ImagingFormatContext(sprintf('%sr1.4dfp.hdr', tra));
            ifc.fileprefix = sprintf('%sr2_op_%sr1_frame%i', tra, tra, size(ifc,4));
            
            cd(pthT4);
            fr = 0;
            for e = 1:Ne
                for f = 1:Nf(e)
                    try
                        fr = fr + 1;
                        comp_t4   = this.composite_t4(  'frame', fr);
                        comp_4dfp = this.composite_4dfp('frame', fr);
                        try
                            pthEi    = fullfile(pthFdg, sprintf('E%i', e), '');
                            pthE1toN = fullfile(pthFdg, sprintf('E1to%i', Ne), '');
                            this.buildVisitor.t4_mul( ...
                                this.frame_to_op_frame_t4('path', pthEi,    'epoch', e,    'frame', f, 'r', [1 2]), ...
                                this.frame_to_op_frame_t4('path', pthE1toN, 'epoch', 1:Ne, 'frame', e, 'r', [1 2]), ...
                                comp_t4);
                        catch ME %#ok<NASGU>
                            warning('mlpet:EAFP', 'ignoring %s', comp_t4)
                            this.buildVisitor.t4_ident(comp_t4)
                        end                    
                        this.buildVisitor.extract_frame_4dfp(sprintf('../%sr1', tra), fr);
                        this.buildVisitor.t4img_4dfp( ...
                            comp_t4, ...
                            sprintf('../%sr1_frame%i', tra, fr), ...
                            'out', comp_4dfp, ...
                            'options', sprintf('-O../%sr1_frame%i', tra, fr));
                        ifc_op = mlfourd.ImagingFormatContext([comp_4dfp '.4dfp.hdr']);
                        ifc.img(:,:,:,fr) = ifc_op.img;
                        deleteExisting([comp_4dfp '.4dfp.*'])
                    catch ME
                        handexcept(ME, ...
                            'mlpet:RuntimeError', ...
                            'TracerResolveBuilder.reconstituteFramesAC3 failed aufbau of %s at epoch->%i, frame->%i', ...
                            ifc.fqfilename, e, f)
                    end
                end                
            end
            ifc.save();
            ic2 = mlfourd.ImagingContext2(ifc);
            this = this.packageProduct(ic2);
            ic2 = ic2.timeAveraged();
            ic2.save();
            deleteExisting(sprintf('../%sr1_frame*.4dfp.*', tra))
            
            deleteExisting(sprintf('T1001*_op_%se*_frame*4dfp*', tra))
            
            popd(pwd0) 
        end
        function this = resolveToT1001(this)
            tra = lower(this.sessionData.tracer);
            resolvedTracer = glob(sprintf('%sr2_op_%sr1_frame*.4dfp.hdr', tra, tra));
            resolvedTracer = resolvedTracer{1};
            assert(isfile(resolvedTracer))
            assert(isfile('T1001.4dfp.hdr'))
            rb = mlfourdfp.CompositeT4ResolveBuilder( ...
                'sessionData', this.sessionData, ...                
                'theImages', {'T1001' resolvedTracer}, ...
                'blurArg', 2, ...
                'maskForImages', {'T1001' 'Msktgen'}, ...
                'NRevisions', 1);
            rb = rb.resolve;
            this = this.packageProduct(rb.product);
        end
        
        function fn = composite_4dfp(this, varargin)
            % e.g., sprintf('fdgr%i_frame%i_op_fdge1to%ir1_frame%i', 2, fr, Ne, Ne)
            
            Ne = this.sessionData.supEpoch;
            ip = inputParser;
            addParameter(ip, 'path', '', @isfolder)
            addParameter(ip, 'epoch', 1:Ne, @isnumeric)
            addParameter(ip, 'frame', [], @isnumeric)
            addParameter(ip, 'r', 2, @isnumeric)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            tra = lower(this.sessionData.tracer);
            fn = fullfile(ipr.path, ...
                 sprintf('%s%s_frame%i_op_%s%sr1_frame%i', ...
                         tra, this.r_label(ipr), ipr.frame, ...
                         tra, this.epoch_label(ipr), Ne));            
        end
        function fn = composite_t4(this, varargin)
            % e.g., sprintf('fdgr%ir%i_frame%i_to_op_fdge1to%ir1_frame%i_t4', 1, 2, fr, Ne, Ne)
            
            Ne = this.sessionData.supEpoch;
            ip = inputParser;
            addParameter(ip, 'path', '', @isfolder)
            addParameter(ip, 'epoch', 1:Ne, @isnumeric)
            addParameter(ip, 'frame', [], @isnumeric)
            addParameter(ip, 'r', [1 2], @isnumeric)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            tra = lower(this.sessionData.tracer);
            fn = fullfile(ipr.path, ...
                 sprintf('%s%s_frame%i_to_op_%s%sr1_frame%i_t4', ...
                         tra, this.r_label(ipr), ipr.frame, ...
                         tra, this.epoch_label(ipr), Ne));
        end
        function fn = frame_to_op_frame_t4(this, varargin)
            % e.g., this.buildVisitor.t4mul( ...
            % sprintf('fdge%ir%i_frame%i_to_op_fdge%ir1_frame%i_t4',    e, 1,    f, e, Nf(e)), ...
            % sprintf('fdge%ir%i_frame%i_to_op_fdge%ir1_frame%i_t4',    e, 2,    f, e, Nf(e)), ...
            % sprintf('fdge%ir%ir%i_frame%i_to_op_fdge%ir1_frame%i_t4', e, 1, 2, f, e, Nf(e)));
            %
            % e.g., this.buildVisitor.t4mul( ...
            % sprintf('fdge1to%ir%i_frame%i_to_op_fdge1to%ir1_frame%i_t4',    Ne, 1,    e, Ne, Ne), ...
            % sprintf('fdge1to%ir%i_frame%i_to_op_fdge1to%ir1_frame%i_t4',    Ne, 2,    e, Ne, Ne), ...
            % sprintf('fdge1to%ir%ir%i_frame%i_to_op_fdge1to%ir1_frame%i_t4', Ne, 1, 2, e, Ne, Ne));
                        
            ip = inputParser;
            addParameter(ip, 'path', '', @isfolder)
            addParameter(ip, 'epoch', [], @isnumeric)
            addParameter(ip, 'frame', [], @isnumeric)
            addParameter(ip, 'r', [], @isnumeric)
            parse(ip, varargin{:})
            ipr = ip.Results;

            tra = lower(this.sessionData.tracer); 
            fn = fullfile(ipr.path, ...
                 sprintf('%s%s%s_frame%i_to_op_%s%sr1_frame%i_t4', ...
                         tra, this.epoch_label(ipr), this.r_label(ipr), ipr.frame, ...
                         tra, this.dest_epoch_label(ipr), this.dest_frame(ipr)));
        end
        function ep = epoch_label(~, ipr)
            assert(isstruct(ipr))
            assert(isfield(ipr, 'epoch'))
            if 1 == length(ipr.epoch)
                ep = sprintf('e%i', ipr.epoch);
                return
            end
            if length(ipr.epoch) > 1
                ep = sprintf('e%ito%i', ipr.epoch(1), ipr.epoch(end));
                return
            end
            ep = '';
        end
        function de = dest_epoch_label(~, ipr)
            assert(isstruct(ipr))
            assert(isfield(ipr, 'epoch'))
            if 1 == length(ipr.epoch)
                de = sprintf('e%i', ipr.epoch);
                return
            end
            if length(ipr.epoch) > 1
                de = sprintf('e%ito%i', ipr.epoch(1), ipr.epoch(end));
                return
            end
            de = '';
        end

        function df = dest_frame(this, ipr)
            assert(isstruct(ipr))
            assert(isfield(ipr, 'epoch'))
            mle = this.sessionData.maxLengthEpoch;
            Ne = this.sessionData.supEpoch;
            Nf = mle*ones(1,Ne);
            Nf(end) = length(this.sessionData.times)-(Ne-1)*mle;

            if 1 == length(ipr.epoch)
                df = Nf(ipr.epoch);
                return
            end                
            if length(ipr.epoch) > 1
                df = Ne;
                return
            end
            df = this.sessionData.times;
        end

        function rl = r_label(~, ipr)
            assert(isstruct(ipr))
            assert(isfield(ipr, 'r'))
            if 1 == length(ipr.r)
                rl = sprintf('r%i', ipr.r);
                return
            end
            if length(ipr.r) > 1
                rl = sprintf('r%ir%i', ipr.r(1), ipr.r(2));
                return
            end
            rl = '';
        end
		  
 		function this = ResamplingRestrictedResolveBuilder(varargin)
 			%% RESAMPLINGRESTRICTEDRESOLVEBUILDER
 			%  @param .

 			this = this@mlfourdfp.AbstractSessionBuilder(varargin{:});
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

