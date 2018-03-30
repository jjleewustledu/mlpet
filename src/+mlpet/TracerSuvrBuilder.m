classdef TracerSuvrBuilder < mlpipeline.AbstractSessionBuilder
	%% TRACERSUVRBUILDER  

	%  $Revision$
 	%  was created 28-Mar-2018 22:00:52 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties
 		
 	end

	methods		
        function buildSuvr(this)
        end
        function this  = instanceConstructCompositeResolved(this, varargin)
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
        function c    = localTracerSuvr(this)  
            %  @return c := cell-array of fileprefixes for SUVR in pwd.
            
            sd = this.sessionData;
            tr = {'FDG' 'OC' 'OO' 'HO'};
            
            c = {};
            for itr = 1:length(tr)                
                if (lexist(sd.tracerSuvr('typ','filename'), 'file'))
                    continue
                end     
                accnn = 0;
                acc   = 0;
                for isl = sd.supScanList
                    sd.tracer = tr{itr};
                    sd.snumber = isl;
                    if (~lexist(sd.tracerResolvedFinal, 'file'))
                        continue
                    end
                    nn    = mlfourd.NumericalNIfTId.load(sd.tracerResolvedFinal);
                    nn    = nn.timeContracted(this.timeWindowIndicesSuvr(sd, nn));
                    accnn = nn + accnn;
                    acc   = 1  + acc;
                end
                accnn = accnn/acc; % arithmetic mean
                accnn.fqfilename = fullfile(pwd, sd.tracerSuvr('typ','filename'));
                accnn.save;
                
                c = [c {sd.tracerSuvr('typ','fp')}]; %#ok<AGROW>
                
            end
            assert(~isempty(c));
        end
        function w    = timeWindowIndicesSuvr(~, sessd, nn)
            %  @param sessd is an mlpipeline.SessionData.
            %  @param nn := NumericalNIfTId of dynamic data.
            %  @return w := [idx0 idxF] for sessd.tracer.
            
            assert(isa(sessd, 'mlpipeline.SessionData'));
            nn = nn.volumeSummed;
            [~,idx0] = max(nn.img > 0.1*max(nn.img));
            idxF = idx0;
            while (idxF < length(nn.img))
                if (sessd.times(idxF) - sessd.times(idx0) >= sessd.timeWindowDurationSuvr)
                    break
                end
                idxF = idxF + 1;
            end
            w = [idx0 idxF];
            
            if (strcmpi(sessd.tracer, 'OC') || strcmpi(sessd.tracer, 'CO'))
                w = w + 120; % per Martin et al. JCBFM 1987
            end
        end
        
 		function this = TracerSuvrBuilder(varargin)
 			this = this@mlpipeline.AbstractSessionBuilder(varargin{:});
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

