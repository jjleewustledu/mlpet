classdef Msktgen < mlpipeline.AbstractBuilder
	%% MSKTGEN 

	%  $Revision$
 	%  was created 14-Apr-2018 20:06:44 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties
 		source
        intermediaryForMask
        sourceOfMask
        blurForMask = 33
        blurArg % this.sessionData_.compositeT4ResolveBuilderBlurArg
        threshp = 0
        doConstructResolved
        NRevisions = 1
    end
    
    properties (Dependent)
        t4
    end

	methods 
        
        %% GET
        
        function g = get.t4(this)
            g = this.t4_;
        end
        
        %%
        
        function obj = constructForTracerRevision(this)
            obj  = this.constructMskt( ...
                'source', this.sessionData.tracerRevision, ...
                'intermediaryForMask', this.sessionData.T1001, ...
                'sourceOfMask', fullfile(this.sessionData.vLocation, 'brainmask.4dfp.hdr'));
        end
        function obj = constructMskt(this, varargin)
            %  @param source may be dynamic.   For doConstructResolved == true, resolving work is performed on
            %  time-summed dynamic data.
            %  @param doConstructResolved == true =: resolving mask to source making use of CompositeT4ResolveBuilder to
            %  place the masking intermediary (e.g., T1001) on the source, then binarizing and blurring the masking
            %  source (e.g., brainmask).  
            %  @param blurForMask applies the specified blur, in mm fwhh, to a binary mask for operational use similar
            %  to that of mlfourdfp.FourdfpVisitor.msktgen_4dfp.
            %  @param threshp is the percentile, [0..100], for thresholding a blurred mask, setting values below the
            %  threshp to zero.
            %  @param blurArg is used by CompositeT4ResolvedBuilder.   
            
            ip = inputParser;
            addParameter(ip, 'source', '');
            addParameter(ip, 'intermediaryForMask', '');
            addParameter(ip, 'sourceOfMask', '');
            addParameter(ip, 'blurForMask', this.blurForMask, @isnumeric);
            addParameter(ip, 'blurArg', this.blurArg, @isnumeric);
            addParameter(ip, 'threshp', 0, @isnumeric);
            addParameter(ip, 'doConstructResolved', true, @islogical);
            addParameter(ip, 'NRevisions', 1, @isnumeric);
            parse(ip, varargin{:});
            import mlfourd.*;
            this.source              = ImagingContext(ip.Results.source);
            this.intermediaryForMask = ImagingContext(ip.Results.intermediaryForMask);
            this.sourceOfMask        = ImagingContext(ip.Results.sourceOfMask);
            this.blurForMask         = ip.Results.blurForMask;
            this.blurArg             = ip.Results.blurArg;
            this.threshp             = ip.Results.threshp;
            this.doConstructResolved = ip.Results.doConstructResolved;
            this.NRevisions          = ip.Results.NRevisions;
            
            if (this.doConstructResolved)
                this = this.constructResolvedMask;
            end
            fqfn              = [this.sourceOfMask.fqfileprefix '.4dfp.hdr'];
            this.sourceOfMask =  this.sourceOfMask.binarized;
            this.sourceOfMask =  this.sourceOfMask.blurred(this.blurForMask);
            this.sourceOfMask =  this.normalizeTo1000(this.sourceOfMask);
            this.sourceOfMask =  this.sourceOfMask.threshp(this.threshp);
            this.sourceOfMask.fqfilename = fqfn;
            this.sourceOfMask.save;
            obj = this.sourceOfMask;
        end
        function ic  = ensure4dfp(~, ic)
            assert(isa(ic, 'mlfourd.ImagingContext'));
            if (~strcmp(ic.filesuffix, '.4dfp.hdr'))
                ic.filesuffix = '.4dfp.hdr';
            end
        end
        function out = t4img_4dfp(this, varargin)
            assert(this.NRevisions == 1);
            fv = mlfourdfp.FourdfpVisitor;
            out = fv.t4img_4dfp(varargin{:});
        end
		  
 		function this = Msktgen(varargin)
 			this = this@mlpipeline.AbstractBuilder(varargin{:});
            this.blurArg = this.sessionData_.compositeT4ResolveBuilderBlurArg;
            this.sessionData_.compAlignMethod = 'align_crossModal7';
 		end
    end 
    
    %% PRIVATE
    
    properties (Access = private)
        t4_
    end
    
    methods (Access = private)
        function this = constructResolvedMask(this)
            
            pwd0 = pushd(this.source.filepath);  

            this.sessionData_.rnumber = 1;
            theImages = [{this.source.fileprefix} this.intermediaryForMask.fqfileprefix];
            cRB_ = mlfourdfp.CompositeT4ResolveBuilder( ...
                'sessionData', this.sessionData_, ...
                'theImages', theImages, ...
                'blurArg', this.blurArg, ...
                'maskForImages', {'none' 'T1001'}, ...
                'NRevisions', this.NRevisions);                        
            cRB_.ignoreFinishfile = true;
            cRB_.neverTouchFinishfile = true;
            cRB_ = cRB_.resolve;
            t4err = mean(cRB_.t4_resolve_err, 'omitnan');
            if (t4err > this.blurForMask)
                %popd(pwd0); % clients to Msktgen will likely catch the error; prepare pwd.
                warning('mlpet:maskFailure', ...
                      'Msktgen.constructResolvedMask.cRB_.t4_resolve_err->%s, tol->%g', ...
                      mat2str(t4err), this.blurForMask);
            end
            this.t4_ = cRB_.t4_to_resolveTag(length(theImages));
            this.sourceOfMask = ...
                this.buildVisitor.t4img_4dfp( ...
                    this.t4, this.sourceOfMask.fqfileprefix, ...
                    'out', [this.source.fileprefix '_mskt'], ...
                    'options', ['-O' cRB_.product{1}.fileprefix]);
            this.sourceOfMask = ...
                mlfourd.ImagingContext([this.sourceOfMask '.4dfp.hdr']); 
                
            popd(pwd0);
        end
        function this = constructMask(this)
        end
        function ic = normalizeTo1000(~, ic)
            nn = ic.numericalNiftid;
            nn = nn*(1000/nn.dipmax);
            ic = mlfourd.ImagingContext(nn);
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

