classdef (Abstract) AbstractAerobicGlycolysisKit < handle & mlpet.IAerobicGlycolysisKit
	%% ABSTRACTAEROBICGLYCOLYSISKIT  

	%  $Revision$
 	%  was created 10-Feb-2021 15:59:15 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.9.0.1570001 (R2020b) Update 4 for MACI64.  Copyright 2021 John Joowon Lee.
 	
    properties (Abstract)
        dataFolder
        sessionData
    end
    
    methods (Abstract)
        metricOnAtlas(this)
    end
    
	properties (Constant) 		
        indices = [1 7:85 251:255 1000:1035 2000:2035 3000:3035 4000:4035 5001:5002 6000 2:6];
        %indicesL = [14:16  1:13 17:20 25:39 21:24 72 73 77 78 80 81 83 85 192 193:196 201:255 1000:1035 3000:3035 5001 6000];
        %indicesR = [14:16 40:71             21:24 72 74 77 79 80 82 84 85 192 197:200 201:255 2000:2035 4000:4035 5002 6000];
    end
    
	properties (Dependent)
        indicesToCheck
    end
    
    properties
    end
    
    methods (Static)
        function theSD = constructSessionData(varargin)
            
            import mlraichle.*
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired( ip, 'metric', @ischar)
            addParameter(ip, 'subjectsExpr', 'sub-S*', @ischar)
            addParameter(ip, 'tracer', '', @ischar)
            addParameter(ip, 'debug', ~isempty(getenv('DEBUG')), @islogical)
            addParameter(ip, 'region', 'wmparc1', @ischar)
            addParameter(ip, 'scanIndex', 1:4, @isnumeric)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            idx = 1;
            subPath = fullfile(getenv('SINGULARITY_HOME'), 'subjects');
            pwd1 = pushd(subPath);
            subjects = globFoldersT(ipr.subjectsExpr); % e.g., 'sub-S3*'
            for sub = subjects
                pwd0 = pushd(fullfile(subPath, sub{1}));
                subd = SubjectData('subjectFolder', sub{1});
                sesfs = subd.subFolder2sesFolders(sub{1});

                for ses = sesfs
                    for scan_idx = ipr.scanIndex
                        try
                            sesd = SessionData( ...
                                'studyData', StudyData(), ...
                                'projectData', ProjectData('sessionStr', ses{1}), ...
                                'subjectData', subd, ...
                                'sessionFolder', ses{1}, ...
                                'scanIndex', scan_idx, ...
                                'tracer', upper(ipr.tracer), ...
                                'ac', true, ...
                                'region', ipr.region, ...
                                'metric', ipr.metric);            
                            if sesd.datetime < mlraichle.StudyRegistry.instance.earliestCalibrationDatetime
                                continue
                            end
                            tracerfn = sesd.([lower(sesd.tracer) 'OnAtlas']);
                            if ~isfile(tracerfn)
                                sesd.jitOn222(tracerfn)
                            end
                            theSD(idx) = sesd; %#ok<AGROW>
                            idx = idx + 1;
                        catch ME
                            handwarning(ME)
                        end
                    end
                end
                popd(pwd0);
            end
            popd(pwd1);
        end        
        function cbf = fs2cbf(fs)
            %% FS2CBF
            %  @param fs is ImagingContext2.
            %  @return cbf in mL/min/hg
            
            assert(isa(fs, 'mlfourd.ImagingContext2'))
            f1 = fs.fourdfp;
            f1.img = f1.img(:,:,:,1);
            f1 = mlfourd.ImagingContext2(f1);
            cbf = mlpet.TracerKinetics.f1ToCbf(f1);
            cbf.fileprefix = strrep(fs.fileprefix, 'fs', 'cbf');
        end
        function matfn = ic2mat(ic)
            %% creates mat files with img(binary_msk) with multi-arrays always flipped on 2
            %  for consistency with luckett_to_4dfp, luckett_to_nii.
            
            msk = mlfourd.ImagingContext2(fullfile(getenv('REFDIR'), '711-2B_222_brain.4dfp.hdr'));
            msk = msk.binarized();
            bin = msk.fourdfp.img > 0;
            bin = flip(bin, 2);
            
            sz = size(ic);
            img = ic.fourdfp.img;            
            if length(sz) < 3
                dat = img;
                matfn = [ic.fqfileprefix '.mat'];
                save(matfn, 'dat')
                return
            end
            img = flip(img, 2);
            if 4 == length(sz)
                dat = zeros(dipsum(msk), sz(4));
                for t = 1:sz(4)
                    img_ = img(:,:,:,t);
                    dat(:,t) = img_(bin);
                end
                matfn = [ic.fqfileprefix '.mat'];
                save(matfn, 'dat')
                return
            end
            if 3 == length(sz)
                dat = img(bin);
                matfn = [ic.fqfileprefix '.mat'];
                save(matfn, 'dat')
                return
            end
            error('mlraichle:ValueError', 'AugmentedAerobicGlycolysisKit.ic2mat.sz of %g is not supported', sz)
        end  
        function h = index2histology(idx)
            h = '';
            if (1000 <= idx && idx < 3000) || (11000 <= idx && idx < 13000)
                h = 'g';
                return
            end
            if (3000 <= idx && idx <= 5217) || (13000 <= idx && idx < 15000)
                h = 'w';
                return
            end
            if 8000 <= idx && idx <= 9999
                h = 's';
                return
            end
            switch idx
                case {3 42}
                    h = 'g';
                case {2 7 27 28 41 46 59 60}
                    h = 'w';
                case num2cell([170:179 7100:7101])
                    h = 'w';
                case num2cell([9:13 16 18 48:52 54 101 102 104 105 107 110 111 113 114 116])
                    h = 's';
                otherwise
            end
        end
        function initialize()
            mlraichle.RaichleRegistry.instance('initialize');
        end
        function chi = ks2chi(ks)
            %% KS2CHI
            %  @param ks is ImagingContext2.
            %  @return chi := k1 k3/(k2 + k3) in 1/s, without v1.
            
            ks = ks.fourdfp;            
            img = ks.img(:,:,:,1).*ks.img(:,:,:,3)./(ks.img(:,:,:,2) + ks.img(:,:,:,3)); % 1/s
            img(isnan(img)) = 0;
            
            chi = copy(ks);            
            chi.fileprefix = strrep(ks.fileprefix, 'ks', 'chi');
            chi.img = img;
            chi = mlfourd.ImagingContext2(chi);
        end
        function cmrglc = ks2cmrglc(ks, cbv, model)
            %% KS2CMRGLC
            %  @param ks is ImagingContext2.
            %  @param cbv is ImagingContext2.
            %  @param model is mlglucose.Huang1980Model.
            %  @return cmrglc is ImagingContext2.
            
            chi = mlraichle.AbstractAerobicGlycolysisKit.ks2chi(ks); % 1/s
            chi = chi * 60; % 1/min
            v1 = cbv * 0.0105;
            glc = mlglucose.Huang1980.glcConversion(model.glc, 'mg/dL', 'umol/hg');
            
            cmrglc = v1 .* chi .* (glc/mlpet.AerobicGlycolysisKit.LC);
            cmrglc.fileprefix = strrep(ks.fileprefix, 'ks', 'cmrglc');
        end
        function oef = os2oef(os)
            %% OS2CHI
            %  @param os is ImagingContext2.
            %  @return oef := k2
            
            os = os.fourdfp;
            img = os.img(:,:,:,2);
            img(isnan(img)) = 0;
            img(img < 0) = 0;
            img(img > 1) = 1;
            
            oef = copy(os);
            oef.fileprefix = strrep(os.fileprefix, 'os', 'oef');
            oef.img = img;
            oef = mlfourd.ImagingContext2(oef);
        end
        function cmro2 = os2cmro2(os, cbf, model)
            %% OS2CMRGLC
            %  @param os is ImagingContext2.
            %  @param cbf is ImagingContext2.
            %  @param model is mlglucose.Huang1980Model.
            %  @return cmro2 is ImagingContext2.
            
            oef = os2oef(os);
            o2content = model.NOMINAL_O2_CONTENT;
            cmro2 = oef .* cbf .* o2content;
            cmro2.fileprefix = strrep(os.fileprefix, 'os', 'cmro2');
        end
        function cbv = vs2cbv(vs)
            %% FS2CBF
            %  @param fs is ImagingContext2.
            %  @return cbf in mL/min/hg
            
            assert(isa(vs, 'mlfourd.ImagingContext2'))
            vs = vs.fourdfp;
            vs.img = vs.img(:,:,:,1);
            vs = mlfourd.ImagingContext2(vs);
            cbv = mlpet.TracerKinetics.v1ToCbv(vs);
            cbv.fileprefix = strrep(vs.fileprefix, 'vs', 'cbv');
        end
    end

	methods 
        
        %% GET
        
        function g = get.indicesToCheck(this)
            if ~isempty(getenv('DEBUG'))
                g = this.indices;
                return
            end
            if isdeployed() || ~isempty(getenv('NOPLOT'))
                g = 0;
                return
            end
            
            % limited indices for checking
            g = [1 7:13 16:20 24 26:28 1001 2001 3001 4001 5001 5002 6000];
        end
        
        %%
		  
        function obj = aifsOnAtlas(this, varargin)
            tr = lower(this.sessionData.tracer);
            obj = this.metricOnAtlas(['aif_' tr], varargin{:});
        end
        function obj = cbvOnAtlas(this, varargin)
            obj = this.metricOnAtlas('cbv', varargin{:});
        end
        function obj = fsOnAtlas(this, varargin)
            obj = this.metricOnAtlas('fs', varargin{:});
        end
        function obj = ksOnAtlas(this, varargin)
            obj = this.metricOnAtlas('ks', varargin{:});
        end
        function obj = osOnAtlas(this, varargin)
            obj = this.metricOnAtlas('os', varargin{:});
        end
        function ic = maskOnAtlasTagged(this, varargin)
            fqfp = this.sessionData.wmparc1OnAtlas('typ', 'fqfp');
            fqfp_bin = [fqfp '_binarized'];
            
            % 4dfp exists
            if isfile([fqfp_bin '.4dfp.hdr'])
                ic = mlfourd.ImagingContext2([fqfp_bin '.4dfp.hdr']);
                return
            end
            if isfile([fqfp '.4dfp.hdr'])
                ic = mlfourd.ImagingContext2([fqfp '.4dfp.hdr']);
                ic = ic.binarized();
                ic.save()
                return
            end
        end
        function resetModelSampler(~)
            mlpet.TracerKineticsModel.solutionOnScannerFrames([], [])
        end 
        function setNormalizationFactor(~, scanner)
            assert(isa(scanner, 'mlpet.AbstractDevice'))
            RR = mlraichle.RaichleRegistry.instance();
            
            if isa(scanner, 'mlsiemens.BiographMMRDevice')
                if strcmpi('15o', scanner.isotope)
                    RR.normalizationFactor = 1;
                end
            end
        end
        function setScatterFraction(this, scanner, varargin)
            ip = inputParser;
            addRequired(ip, 'scanner', @(x) isa(x, 'mlpet.AbstractDevice'))
            addParameter(ip, 'times', [], @isnumeric)
            parse(ip, scanner, varargin{:})
            ipr = ip.Results;
            
            g = globT(fullfile(this.sessionData.subjectPath, 'resampling_restricted', 'T1001*222*hdr'));
            assert(~isempty(g))
            T1001 = mlfourd.ImagingContext2(g{1});
            ambientMask = T1001.numlt(1);
            headMask = T1001.numgt(1);
            
            ic = scanner.imagingContext;
            if ~isempty(ipr.times) 
                if ipr.times(1) < 0
                    ipr.times = ipr.times + abs(ipr.times(1)) + 1;
                end               
                idxWindow = ipr.times(1) <= scanner.timesMid & scanner.timesMid <= ipr.times(end);
                ifc = ic.fourdfp;
                ifc.img = ifc.img(:,:,:,idxWindow);
                ic = mlfourd.ImagingContext2(ifc);
            end
            suv = ic.timeAveraged();
            scatter = suv.volumeAveraged(ambientMask);
            prompts = suv.volumeAveraged(headMask);
            
            RR = mlraichle.RaichleRegistry.instance();
            RR.scatterFraction = scatter.fourdfp.img/prompts.fourdfp.img;
        end
        function obj = vsOnAtlas(this, varargin)
            obj = this.metricOnAtlas('vs', varargin{:});
        end       
    end
    
    %% PROTECTED
    
    methods (Access = protected)
 		function this = AbstractAerobicGlycolysisKit(varargin)
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

