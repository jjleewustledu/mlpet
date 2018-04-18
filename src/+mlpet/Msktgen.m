classdef Msktgen < mlpipeline.AbstractDataBuilder
	%% MSKTGEN  

	%  $Revision$
 	%  was created 14-Apr-2018 20:06:44 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties
 		source
        intermediaryForMask
        sourceOfMask
        blurForMask = 5.5
        blurArg = 1.5
        threshp
        doConstructResolved
        NRevisions = 1
 	end

	methods 
        function obj = constructMskt(this, varargin)
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
            this.sourceOfMask = this.sourceOfMask.binarized;
            this.sourceOfMask = this.sourceOfMask.blurred(this.blurForMask);
            this.sourceOfMask = this.normalizeTo1000(this.sourceOfMask);
            obj               = this.sourceOfMask.threshp(this.threshp);
            obj.filesuffix    = '.4dfp.ifh';
        end
		  
 		function this = Msktgen(varargin)
 			this = this@mlpipeline.AbstractDataBuilder(varargin{:});
 		end
    end 
    
    %% PRIVATE
    
    methods (Access = private)
        function this = constructResolvedMask(this)
            
            pwd0 = pushd(this.source.filepath);            
            this.sessionData_.rnumber = 1;
            theImages = [{this.source.fileprefix} this.intermediaryForMask.fqfileprefix];
            cRB_ = mlfourdfp.CompositeT4ResolveBuilder( ...
                'sessionData', this.sessionData_, ...
                'theImages', theImages, ...
                'blurArg', this.blurArg, ...
                'maskForImages', 'none', ...
                'NRevisions', this.NRevisions);                        
            cRB_.ignoreFinishfile = true;
            cRB_.neverTouchFinishfile = true;
            cRB_ = cRB_.updateFinished;                         
            cRB_ = cRB_.resolve;
            this.sourceOfMask = ...
                this.buildVisitor.t4img_4dfp( ...
                    cRB_.t4_to_resolveTag(length(theImages)), this.sourceOfMask.fqfileprefix, ...
                    'out', [this.source.fileprefix '_mskt'], ...
                    'options', ['-O' this.source.fileprefix]);
            this.sourceOfMask = ...
                mlfourd.ImagingContext([this.sourceOfMask '.4dfp.ifh']);                    
            popd(pwd0);
        end
        function ic = normalizeTo1000(~, ic)
            nn = ic.numericalNiftid;
            nn = nn*(1000/nn.dipmax);
            ic = mlfourd.ImagingContext(nn);
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

