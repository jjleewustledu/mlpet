classdef NiftyPETyBuilder < mlpet.TracerBuilder
	%% NIFTYPETYBUILDER  

	%  $Revision$
 	%  was created 17-Nov-2017 18:34:21 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.3.0.713579 (R2017b) for MACI64.  Copyright 2017 John Joowon Lee.
 	
    
    properties (Constant)
        TMP_FILEPREFIX_LENGTH = 8
    end
    
	properties 		
        fdgIrregSegs_   = [30,30,30,30,30,30,30,30,30,30,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60]
        fdgSegs_        = [30,30,30,30,30,30,30,30,30,30,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60]
        hoSegs_         = [30,30,30,30,30,30,30,30,30,30]
        ocSegs_         = [30,30,30,30,30,30,30,30,30,30,30,30,30,30]
        fdgIrregFrames_ = [10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60]
        fdgFrames_      = [10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60]
        hoFrames_       = [3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10]
        ocFrames_       = [3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10]
        niftyIterations = 10
        geometryNiigz   = fullfile(getenv('HOME'), 'Local', 'JSRecon12', 'hardwareumaps', 'hardware_umap.nii.gz');
    end
    
    properties (Dependent)
        tmpFileprefix
    end

	methods 
        
        %% GET
        
        function g = get.tmpFileprefix(this)
            g = this.rawdataDt_.fns{1};
            g = g(1:this.TMP_FILEPREFIX_LENGTH);
        end
        
        %% 
        
        function this = setupTracerRawdataLocation(this)
            pwd0 = pushd(this.sessionData.tracerRawdataLocation);
            for d = 1:this.rawdataDt_.length
                fqdcm =               this.rawdataDt_.fqfns{d};
                fqbf  = [myfileprefix(this.rawdataDt_.fqfns{d}) '.bf'];
                info = dicominfo(fqdcm);
                switch (info.ImageComments)
                    case 'PET Normalization data'
                        norm = fullfile(this.sessionData.tracerRawdataLocation, 'norm', '');
                        ensuredir(norm);
                        pwd1 = pushd(norm);
                        this.buildVisitor.lns(fqdcm);
                        this.buildVisitor.lns(fqbf);
                        popd(pwd1);
                    case 'Listmode'                       
                        LM = fullfile(this.sessionData.tracerRawdataLocation, 'LM', '');
                        ensuredir(LM);
                        pwd1 = pushd(LM);
                        this.buildVisitor.lns(fqdcm);
                        this.buildVisitor.lns(fqbf);
                        popd(pwd1);
                    case {'Sinogram' 'Physio'}
                    otherwise
                        error('mlpet:unsupportedSwitchcase', 'NiftyPETyBuilder.setupTracerRawdataLocation');
                end
            end
            deleteExisting('mumap_hdw');
            mlbash('ln -s /home/usr/jjlee/Local/JSRecon12/hardwareumaps mumap_hdw');
            popd(pwd0);
        end
        function this = extractUmapSynthFullFrames(this)
            sessdNac = this.sessionData; 
            sessdNac.attenuationCorrected = false;
            ic = mlfourd.ImagingContext(fullfile(sessdNac.tracerLocation, 'umapSynth.4dfp.hdr' ));
            nn = ic.numericalNiftid;
            for t = 1:size(nn, 4)
                nn_ = nn;
                nn_.img = nn.img(:,:,:,t);
                nn_ = nn_.zoomed([2 2 1]);
                nn_.filepath = this.sessionData.tracerRawdataLocation;
                nn_.fileprefix = sprintf('%s_full_frame%i', nn.fileprefix, t-1);
                nn_.save;
                this.fslcpgeom(nn_.fqfilename);
            end            
        end
        function [s,r] = fslcpgeom(this, fqfn)
            assert(lexist(fqfn, 'file'));
            [s,r] = mlbash(sprintf('fslcpgeom %s %s', this.geometryNiigz, fqfn));
        end
        function this = constructTracer(this)
            switch (this.sessionData.tracer)
                case 'FDG'
                    segs = this.fdgSegs_;
                    frames = this.fdgFrames_;
                case 'OC'
                    segs = this.ocSegs_;
                    frames = this.ocFrames_;
                case {'HO' 'OO'}
                    segs = this.hoSegs_;
                    frames = this.hoFrames_;
                otherwise
                    error('mlpet:unsupportedSwitchcase', 'NiftyPETyBuilder.constructTracer');
            end
            tsegs = this.accumTaus(segs);
            
            iframe = 0;
            iseg = 0; 
            t1 = 0;
            while (iframe < length(frames))
                t0 = t1;
                t1 = t1 + frames(iframe+1);
                if (t1 > tsegs(iseg+1))
                    iseg = iseg + 1;
                end
                try
                    this = this.constructFrame( ...
                        this.sessionData.tracerRawdataLocation, t0, t1, iframe, iseg);
                catch ME
                    handerror(ME);
                end
                iframe = iframe + 1;
            end
            this = this.concatFrames;
        end
        function this = constructFrame(this, varargin)
            % @param <tracer_rawdata_location> <t0> <t1> <frame#> <umap_index>
            % @return system('godo.py <tracer_rawdata_location> <t0> <t1> <frame#> <umap_index>')
            
            ip = inputParser;
            addRequired(ip, 'tracerRawdataLocation', @ischar);
            addRequired(ip, 't0', @isnumeric);
            addRequired(ip, 't1', @isnumeric);
            addRequired(ip, 'frame', @isnumeric);
            addRequired(ip, 'umapIndex', @isnumeric);
            parse(ip, varargin{:});
            
            system(sprintf('godo.py %s %i %i %i %i', ...
                ip.Results.tracerRawdataLocation, ip.Results.t0, ip.Results.t1, ip.Results.frame, ip.Results.umapIndex));
        end
        function this = concatFrames(this)
            import mlfourd.*;
            pwd0 = pushd(fullfile(this.sessionData.tracerRawdataLocation, 'img', ''));
            
            % concat
            dt = mlsystem.DirTool(sprintf('%s_itr%i_frame*.nii.gz', this.tmpFileprefix, this.niftyIterations));
            assert(~isempty(dt.fns))
            nn = NumericalNIfTId.load(dt.fns{1});
            nn = nn.zoomed([0.5 0.5 1]);
            nn.fqfileprefix = this.sessionData.tracerRevision('typ', 'fqfileprefix');            
            for fr = 2:dt.length
                nn_ = NumericalNIfTId.load(dt.fns{fr});
                nn_ = nn_.zoomed([0.5 0.5 1]);
                nn.img(:,:,:,fr) = nn_.img;
            end
            
            % and save
            ensuredir(this.sessionData.tracerRevision('typ', 'path'));
            ic = ImagingContext(nn);
            ic.fourdfp;
            ic.save;
            
            popd(pwd0);
        end
        
 		function this = NiftyPETyBuilder(varargin)
 			%% NIFTYPETYBUILDER
 			%  Usage:  this = NiftyPETyBuilder()

 			this = this@mlpet.TracerBuilder(varargin{:});
            this.rawdataDt_ = mlsystem.DirTools(fullfile(this.sessionData.tracerRawdataLocation, '*.dcm'));
 		end
    end 
    
    %% PRIVATE
    
    properties (Access = private)
        rawdataDt_
    end
    
    methods (Access = private)
        function tsegs = accumTaus(~, segs)
            tsegs = segs;
            for s = 1:length(segs)-1
                tsegs(s+1) = tsegs(s) + segs(s+1);
            end
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

