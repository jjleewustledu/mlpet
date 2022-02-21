classdef (Abstract) AbstractAerobicGlycolysisKit < handle & mlpet.IAerobicGlycolysisKit
	%% ABSTRACTAEROBICGLYCOLYSISKIT is an abstract factory pattern

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
        indices = [6000 1:85 251:255 1000:1035 2000:2035 3000:3035 4000:4035 5001:5002]
        indices_bilateral = [6000 14:16 21:24 72 77 80 85 251:255]
        indices_left = [     1:13 17:20 25:39 73 78 81 83 1000:1035 3000:3035 5001]
        indices_right = [   40:52 53:56 57:71 74 79 82 84 2000:2035 4000:4035 5002]
    end
    
	properties (Dependent)
        indicesToCheck
    end
    
    properties
    end
    
    methods (Static)
        function ic = constructPhysiologyDateOnly(varargin)
            %% e.g., constructPhysiologyDateOnly('cbv', 'subjectFolder', 'sub-S58163')
            
            import mlpet.AbstractAerobicGlycolysisKit
            
            ip = inputParser;
            addRequired(ip, 'physiology', @ischar)
            addParameter(ip, 'subjectFolder', '', @ischar)
            addParameter(ip, 'atlTag', '_111', @ischar)
            addParameter(ip, 'blurTag', '', @ischar)
            addParameter(ip, 'region', 'wmparc1', @ischar)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            pwd0 = pushd(fullfile(getenv('SINGULARITY_HOME'), 'subjects', ipr.subjectFolder, 'resampling_restricted')); 
            fnPatt = sprintf('%sdt*%s%s_%s.4dfp.hdr', ipr.physiology, ipr.atlTag, ipr.blurTag, ipr.region);
            g = globT(fnPatt);
            if isempty(g); return; end
            
            %% segregate by dates
            
            m = containers.Map;            
            for ig = 1:length(g)
                dstr = AbstractAerobicGlycolysisKit.physiologyObjToDatetimeStr(g{ig}, 'dateonly', true);
                if ~lstrfind(m.keys, dstr)
                    m(dstr) = g(ig); % cell
                else
                    m(dstr) = [m(dstr) g{ig}];
                end
            end 
            
            %% average scans by dates
            
            for k = asrow(m.keys)
                fns = m(k{1});
                ic = mlfourd.ImagingContext2(fns{1});
                ic = ic.zeros();
                icfp = strrep(ic.fileprefix, ...
                    AbstractAerobicGlycolysisKit.physiologyObjToDatetimeStr(fns{1}), ...
                    AbstractAerobicGlycolysisKit.physiologyObjToDatetimeStr(fns{1}, 'dateonly', true));
                if isfile([icfp '.4dfp.hdr'])
                    continue
                end
                ic_count = 0;
                for fn = fns
                    incr = mlfourd.ImagingContext2(fn{1});
                    if dipsum(incr) > 0
                        ic = ic + incr;
                        ic_count = ic_count + 1;
                    end
                end
                ic = ic / ic_count;
                ic.fileprefix = icfp;
                ic.save()
            end
            
            %%
            
            popd(pwd0);
        end 
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
                            if ~isfile(sesd.wmparc1OnAtlas)
                                mlpet.AbstractAerobicGlycolysisKit.constructWmparc1OnAtlas(sesd);
                            end
                            tracerfn = sesd.([lower(sesd.tracer) 'OnAtlas']);
                            if ~isfile(tracerfn)
                                sesd.jitOnAtlas(tracerfn)
                            end
                            theSD(idx) = sesd; %#ok<AGROW>
                            idx = idx + 1;
                        catch ME
                            if strcmpi('mlnipet:ValueError:getScanFolder', ME.identifier)
                                continue
                            end
                            handwarning(ME)
                        end
                    end
                end
                popd(pwd0);
            end
            popd(pwd1);
        end    
        function ic = constructWmparc1OnAtlas(sesd)
            import mlfourd.ImagingFormatContext
            import mlfourd.ImagingContext2
            
            pwd0 = pushd(sesd.wmparc1OnAtlas('typ', 'filepath'));            
            deleteExisting([sesd.wmparc1OnAtlas('typ', 'fqfileprefix') '.4dfp.*'])
            
            % constructWmparcOnAtlas            
            if ~isfile(sesd.brainOnAtlas)
                sesd.jitOnAtlas(sesd.brainOnAtlas)
            end
            if ~isfile(sesd.wmparcOnAtlas)
                sesd.jitOnAtlas(sesd.wmparcOnAtlas)
            end
            
            % define CSF; idx := 1
            wmparc = ImagingFormatContext(sesd.wmparcOnAtlas());
            wmparc1 = ImagingFormatContext(sesd.brainOnAtlas());
            wmparc1.fileprefix = sesd.wmparc1OnAtlas('typ', 'fp');
            wmparc1.img(wmparc1.img > 0) = 1; % co-opting left cerebral exterior
            wmparc1.img(wmparc.img > 0) = wmparc.img(wmparc.img > 0);
            
            % define venous; idx := 40
            globbed_ven = glob('ocdt*_avgt.4dfp.hdr');
            assert(~isempty(globbed_ven))
            venfn = fullfile(pwd, [myfileprefix(globbed_ven{end}) '_111.4dfp.hdr']);
            sesd.jitOnAtlas(venfn)
            ven = mlfourd.ImagingContext2(venfn);
            ven = ven.thresh(dipmax(ven)/2);
            ven = ven.binarized();
            ven.fileprefix = 'venous_111';
            try
                ven.save();
            catch ME
                handwarning(ME)
            end
            selected = logical(ven.fourdfp.img) & wmparc1.img < 2;
            wmparc1.img(selected) = 40; % co-opting right cerebral exterior
            
            % construct wmparc1
            ic = ImagingContext2(wmparc1);
            ic.save()
            
            popd(pwd0)
        end    
        function cbf = fs2cbf(fs)
            %% FS2CBF
            %  @param fs is ImagingContext2.
            %  @return cbf in mL/min/hg
            
            assert(isa(fs, 'mlfourd.ImagingContext2'))
            f1 = fs.fourdfp;
            if 4 == ndims(f1)
                f1.img = f1.img(:,:,:,1);
            end
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
                case num2cell([170:179 5001:5002 7100:7101])
                    h = 'w';
                case num2cell([9:13 16 18 48:52 54 101 102 104 105 107 110 111 113 114 116])
                    h = 's'; % subcortical
                case {6000}
                    h = 'v'; % venous
                case {1 4 5 43 44}
                    h = 'c'; % csf
                otherwise
            end
        end
        function initialize()
            mlraichle.StudyRegistry.instance('initialize');
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
            
            chi = mlpet.AbstractAerobicGlycolysisKit.ks2chi(ks); % 1/s
            chi = chi * 60; % 1/min
            v1 = cbv * 0.0105;
            glc = mlglucose.Huang1980.glcConversion(model.glc, 'mg/dL', 'umol/hg');
            
            cmrglc = v1 .* chi .* (glc/mlpet.AerobicGlycolysisKit.LC);
            cmrglc.fileprefix = strrep(ks.fileprefix, 'ks', 'cmrglc');
        end
        function [scanList,subList] = listSessionData(varargin)
            
            ip = inputParser;
            addParameter(ip, 'subjectsExpr', 'sub-S*', @ischar)
            addParameter(ip, 'metric', 'cbv', @ischar)
            addParameter(ip, 'tracer', 'oc', @ischar)
            parse(ip, varargin{:})
            ipr = ip.Results;  
            
            % global
            registry = MatlabRegistry.instance(); %#ok<NASGU>
            subjectsDir = fullfile(getenv('SINGULARITY_HOME'), 'subjects');
            setenv('SUBJECTS_DIR', subjectsDir)
            setenv('PROJECTS_DIR', fileparts(subjectsDir)) 
            warning('off', 'MATLAB:table:UnrecognizedVarNameCase')
            warning('off', 'mlnipet:ValueError:getScanFolder')
            
            % subjects, sessions            
            pwd0 = pushd(subjectsDir);
            theSessionData = mlpet.AbstractAerobicGlycolysisKit.constructSessionData( ...
                ipr.metric, ...
                'subjectsExpr', ipr.subjectsExpr, ...
                'tracer', ipr.tracer); % length(theSessionData) ~ 60
            popd(pwd0)
            
            % form list
            scanList = {};
            scanList = [scanList theSessionData.scanFolder];            
            subList = {};
            subList = [subList theSessionData.subjectFolder];
        end
        function oef = os2oef(os)
            %% OS2CHI
            %  @param os is ImagingContext2.
            %  @return oef := k2
            
            os_ = os.fourdfp;
            if 4 == ndims(os_)
                os_.img = os_.img(:,:,:,1);
            end
            img = os_.img;
            img(isnan(img)) = 0;
            img(img < 0) = 0;
            img(img > 1) = 1;            
            oef = copy(os_);
            oef.fileprefix = strrep(os_.fileprefix, 'os', 'oef');
            oef.img = img;
            oef = mlfourd.ImagingContext2(oef);
        end
        function [cmro2,oef] = os2cmro2(os, cbf, model)
            %% OS2CMRGLC
            %  @param os is ImagingContext2.
            %  @param cbf is ImagingContext2.
            %  @param model is mlglucose.Huang1980Model.
            %  @return cmro2 is ImagingContext2.
            %  @return oef is ImagingContext2.
            
            oef = mlpet.AbstractAerobicGlycolysisKit.os2oef(os);
            o2content = model.NOMINAL_O2_CONTENT;
            cmro2 = oef .* cbf .* o2content;
            cmro2.fileprefix = strrep(os.fileprefix, 'os', 'cmro2');
        end
        function dt = physiologyObjToDatetime(obj)
            ic = mlfourd.ImagingContext2(obj);            
            ss = split(ic.fileprefix, '_');
            re = regexp(ss{1}, '\w+dt(?<datetime>\d{14})\w*', 'names');
            dt = datetime(re.datetime, 'InputFormat', 'yyyyMMddHHmmss');
        end
        function dtstr = physiologyObjToDatetimeStr(varargin)
            import mlpet.AbstractAerobicGlycolysisKit 
            ip = inputParser;
            addRequired(ip, 'obj', @(x) ~isempty(x))
            addParameter(ip, 'dateonly', false, @islogical)
            parse(ip, varargin{:})
            ipr = ip.Results;  
            if ipr.dateonly
                dtstr = [datestr(AbstractAerobicGlycolysisKit.physiologyObjToDatetime(ipr.obj), 'yyyymmdd') '000000'];
            else
                dtstr = datestr(AbstractAerobicGlycolysisKit.physiologyObjToDatetime(ipr.obj), 'yyyymmddHHMMSS') ;
            end
        end
        function metricOut = reshapeOnWmparc1(wmparc1, metric, wmparc1Out)
            %% Cf. semantics of pchip or makima.
            
            wmparc1 = mlfourd.ImagingContext2(wmparc1);
            wmparc1 = wmparc1.fourdfp;
            metric = mlfourd.ImagingContext2(metric);
            metric = metric.fourdfp;
            wmparc1Out = mlfourd.ImagingContext2(wmparc1Out);
            wmparc1Out = wmparc1Out.fourdfp;
            metricOut = copy(metric);
            metricOut.img = zeros(size(metric));
            
            for idx = mlpet.AbstractAerobicGlycolysisKit.indices % parcs
                if 6000 == idx % venous structures
                    continue
                end
                roibin = wmparc1.img == idx;
                if 0 == dipsum(roibin) 
                    continue
                end
                try
                    m = dipsum(metric.img(roibin))/dipsum(roibin);
                    roibinOut = wmparc1Out.img == idx;
                    metricOut.img(roibinOut) = m;
                catch ME
                    handwarning(ME)
                    continue
                end
            end
            metricOut = mlfourd.ImagingContext2(metricOut);
        end    
        function cbv = vs2cbv(vs)
            %% FS2CBF
            %  @param fs is ImagingContext2.
            %  @return cbf in mL/min/hg
            
            assert(isa(vs, 'mlfourd.ImagingContext2'))
            vs_ = vs.fourdfp;
            if 4 == ndims(vs_)
                vs_.img = vs_.img(:,:,:,1);
            end
            vs_ = mlfourd.ImagingContext2(vs_);
            cbv = mlpet.TracerKinetics.v1ToCbv(vs_);
            cbv.fileprefix = strrep(vs_.fileprefix, 'vs', 'cbv');
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
            g = [1 7:13 16:20 24 26:28 1000:1009 2000:2009 3000:3009 4000:4009 5001 5002 6000];
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
            RR = mlraichle.StudyRegistry.instance();
            if isa(scanner, 'mlsiemens.BiographMMRDevice')
                RR.normalizationFactor = 1; % 3.8/4.0259; % (Ito mean(cbv)) / (PPG mean(cbv))
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
            
            RR = mlraichle.StudyRegistry.instance();
            RR.scatterFraction = scatter.fourdfp.img/prompts.fourdfp.img;
        end
        function savefig(this, varargin)
            ip = inputParser;
            addRequired(ip, 'handle', @ishandle) % fig handle
            addOptional(ip, 'idx', 0, @isscalar)
            addParameter(ip, 'tags', '', @ischar) % for filenames
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            tags = ipr.tags;
            if ~isempty(tags)
                tags_ = ['_' strrep(tags, ' ', '_')];
            else
                tags_ = '';
            end            
            dbs = dbstack;
            client = dbs(2).name;
            client_ = strrep(dbs(2).name, '.', '_');
            dtStr = datestr(this.sessionData.datetime);
            title(sprintf('%s.idx == %i\n%s %s', client, ipr.idx, tags, dtStr))
            try
                dtTag = lower(this.sessionData.doseAdminDatetimeTag);
                savefig(ipr.handle, ...
                    fullfile(this.dataPath, ...
                    sprintf('%s_idx%i%s_%s.fig', client_, ipr.idx, tags_, dtTag)))
                figs = get(0, 'children');
                saveas(figs(1), ...
                    fullfile(this.dataPath, ...
                    sprintf('%s_idx%i%s_%s.png', client_, ipr.idx, tags_, dtTag)))
                close(figs(1))
            catch ME
                handwarning(ME)
            end
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

