classdef TreeAlignmentBuilder < mlpet.AlignmentBuilder
	%% TREEALIGNMENTBUILDER  

	%  $Revision$
 	%  was created 03-May-2018 23:09:21 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties
 		
 	end

	methods 
		  
        function this = alignAllT1001OpStudyAtlas(this)
            
            sd = this.sessionData;
            
            ensuredir(sd.opAtlasLocation);
            cwd = pushd(sd.opAtlasLocation);
            assert(lexist_4dfp(sd.studyAtlas('typ','fqfp')));
            this.buildVisitor_.lns_4dfp(sd.studyAtlas('typ','fqfp'));
            imgs = [sd.studyAtlas('typ','fp') this.allT1001(sd.opAtlasLocation)];
            this = this.resolve(imgs);
            popd(cwd);
        end
        function this = t4imgAllT1001OnStudyAtlas(this)
            
            sd = this.sessionData;
            
            ensuredir(sd.onAtlasLocation);
            cwd = pushd(sd.onAtlasLocation);
            all = this.allT1001(sd.onAtlasLocation);
            prodOnAtl = cell(size(all));
            for a = 1:length(all)
                prodOnAtl{a} = sprintf('%s_on_HYGLY_atlas', all{a});
                this.buildVisitor_.t4img_4dfp( ...
                    sprintf('%s_to_HYGLY_atlas_t4', all{a}), ...
                    all{a}, ...
                    'out', prodOnAtl{a}, ...
                    'options', sprintf('-O%s', sd.studyAtlas('typ','fqfp')));
            end
            this = this.packageProduct(all);
            popd(cwd);            
        end
        function all  = allT1001(this, varargin)
            
            sd = this.sessionData;
            ip = inputParser;
            addOptional(ip, 'atlasLocation', sd.onAtlasLocation, @ischar);
            parse(ip, varargin{:});
            
            ensuredir(ip.Results.atlasLocation);
            cwd = pushd(ip.Results.atlasLocation);
            stbl = this.subcensus_;
            subjs = {};
            all = {};
            for s = 1:length(stbl.subjectID)
                sid = stbl.subjectID{s};
                if (~lstrfind(subjs, sid))
                    subjs = [subjs sid]; %#ok<AGROW>
                    all   = [all sprintf('%s_T1001', sid)]; %#ok<AGROW>
                    this.buildVisitor_.lns_4dfp(this.aT1001(s), [sid '_T1001']);
                end
            end
            popd(cwd);
        end
        function fqfp = aT1001(this, idx)
            stbl = this.subcensus_;
            fqfp = fullfile(this.sessionData.subjectsDir, ...
                            stbl.subjectID{idx}, ...
                            sprintf('V%i', stbl.v_(idx)), 'T1001');
        end
        function this = resolve(this, imgs, varargin)
            %  @param imgs = cell(Nvisits, Nscans) of char fqfp.
            
            ip = inputParser;
            addRequired( ip, 'imgs', @iscell);
            addParameter(ip, 'NRevisions', 2, @isnumeric);
            addParameter(ip, 'maskForImages', 'msktgen_4dfp');
            addParameter(ip, 'resolveTag', 'op_HYGLY_atlas', @ischar);
            addParameter(ip, 'blurArg', 5.5, @isnumeric);
            parse(ip, imgs, varargin{:});
            
            assert(iscell(imgs));
            cwd = pushd(this.sessionData.opAtlasLocation);
            res = mlpipeline.ResourcesRegistry.instance();
            cRB = mlfourdfp.CompositeT4ResolveBuilder( ...
                'sessionData', this.sessionData, ...
                'theImages', imgs, ...
                'maskForImages', ip.Results.maskForImages, ...
                'resolveTag', ip.Results.resolveTag, ...
                'NRevisions', ip.Results.NRevisions, ...
                'blurArg', ip.Results.blurArg);
            cRB.neverMarkFinished = res.neverMarkFinished;
            cRB.ignoreFinishMark = res.neverMarkFinished;
            this.cRB_ = cRB.resolve;
            this.product_ = this.cRB_.product;
            popd(cwd);
            
            this.areAligned_ = true;
        end
        function view(this)
            mlfourdfp.Viewer.view(this.product);
        end
        
 		function this = TreeAlignmentBuilder(varargin)
 			%% TREEALIGNMENTBUILDER
 			%  @param .

 			this = this@mlpet.AlignmentBuilder(varargin{:});
            this.subcensus_ = this.censusSubtable(this.census);
 		end
 	end 

    %% PRIVATE
    
    properties (Access = private)
        areAligned_ = false;
        cRB_
        subcensus_
    end
    
    methods (Access = private)
        function stbl = censusSubtable(~, census)
            assert(isa(census, 'mlpipeline.IStudyCensus'));
            ctbl = census.censusTable;
            stbl = ctbl(1 == ctbl.ready, :);
        end
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

