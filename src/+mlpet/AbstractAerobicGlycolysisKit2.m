classdef (Abstract) AbstractAerobicGlycolysisKit2 < handle
	%% ABSTRACTAEROBICGLYCOLYSISKIT2 is an abstract factory pattern.

	%  $Revision$
 	%  was created 10-Feb-2021 15:59:15 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.9.0.1570001 (R2020b) Update 4 for MACI64.  Copyright 2021 John Joowon Lee.
 	    
    methods (Static)
        function ic = constructPhysiologyDateOnly(varargin)
            %% e.g., constructPhysiologyDateOnly('cbv', 'immediator', obj) % pwd includes sub-108293            
            %  e.g., constructPhysiologyDateOnly('cbv', 'immediator', obj, ...
            %                                    'workpath', '/path/to/sub-108293/resampling_restricted')
            %  e.g., constructPhysiologyDateOnly('cbv', 'immediator', obj, ...
            %                                    'workpath', '/path/to/sub-108293/resampling_restricted', ...
            %                                    'filepatt', 'ocdt2021*_111_voxels.4dfp.hdr')
            
            import mlvg.QuadraticAerobicGlycolysisKit
            
            reg = mlvg.Ccir1211Registry.instance();
            ip = inputParser;
            addRequired(ip, 'physiology', @istext)
            addParameter(ip, 'immediator', [], @(x) isa(x, 'mlpipeline.ImagingData') || isa(x, 'mlpipeline.ImagingMediator'))
            addParameter(ip, 'workpath', pwd, @isfolder)
            addParameter(ip, 'subjectFolder', '', @istext) 
            addParameter(ip, 'filepatt', '', @istext)
            addParameter(ip, 'atlTag', reg.atlasTag, @istext)
            addParameter(ip, 'blurTag', reg.blurTag, @istext)
            addParameter(ip, 'region', 'voxels', @istext)
            parse(ip, varargin{:})
            ipr = ip.Results;
            if isempty(ipr.subjectFolder)
                ipr.subjectFolder = reg.workpath2subject(ipr.workpath);
            end
            if isempty(ipr.filepatt)
                ipr.filepatt = sprintf('%sdt*%s%s_%s.4dfp.hdr', ipr.physiology, ipr.atlTag, ipr.blurTag, ipr.region);
                %ipr.filepatt = sprintf('%s_ses-*_trac-*_proc-%s_pet%s_%s.4dfp.hdr', ...
                %    ipr.subjectFolder, ipr.physiology, ipr.atlTag, ipr.region);
            end
            
            pwd0 = pushd(ipr.workpath);
            g = globT(ipr.filepatt);
            if isempty(g); return; end
            
            %% segregate by dates
            
            m = containers.Map;            
            for ig = 1:length(g)
                if contains(g{ig}, ipr.immediator.defects)
                    continue
                end
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
                    QuadraticAerobicGlycolysisKit.physiologyObjToDatetimeStr(fns{1}), ...
                    QuadraticAerobicGlycolysisKit.physiologyObjToDatetimeStr(fns{1}, 'dateonly', true));
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
        function ic = constructWmparc1OnAtlas(sesd)
            %% idx == 40:  venuos voxels
            %  idx == 1:   extraparenchymal CSF, not ventricles

            import mlfourd.ImagingFormatContext2
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
            wmparc = ImagingFormatContext2(sesd.wmparcOnAtlas());
            wmparc.selectFourdfpTool();
            wmparc1 = ImagingFormatContext2(sesd.brainOnAtlas());
            wmparc1.selectFourdfpTool();
            wmparc1.fileprefix = sesd.wmparc1OnAtlas('typ', 'fp');
            wmparc1.img(wmparc1.img > 0) = 1; % use brainOnAtlas to establish CSF + parenchyma
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
            selected = logical(ven.imagingFormat.img) & wmparc1.img < 2;
            wmparc1.img(selected) = 40; % co-opting right cerebral exterior
            
            % construct wmparc1
            ic = ImagingContext2(wmparc1);
            ic.save()
            
            popd(pwd0);
        end    
        function this = create(immediator)
            arguments
                immediator mlpipeline.ImagingMediator
            end
            
            switch class(immediator)
                case 'mlvg.Ccir1211Mediator'
                    this = mlvg.QuadraticAerobicGlycolysisKit(immediator);
                otherwise
                    error('mlpet:ValueError', stackstr())
            end
        end
        function cbf = fs2cbf(fs)
            %% FS2CBF
            %  @param fs is ImagingContext2.
            %  @return cbf in mL/min/hg
            
            assert(isa(fs, 'mlfourd.ImagingContext2'))
            f1 = fs.imagingFormat;
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
            bin = msk.imagingFormat.img > 0;
            bin = flip(bin, 2);
            
            sz = size(ic);
            img = ic.imagingFormat.img;            
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
                case {40 6000}
                    h = 'v'; % venous
                case {1 4 5 43 44}
                    h = 'c'; % csf
                otherwise
            end
        end
        function chi = ks2chi(ks)
            %% KS2CHI
            %  @param ks is ImagingContext2.
            %  @return chi := k1 k3/(k2 + k3) in 1/s, without v1.
            
            ks = ks.nifti;            
            img = ks.img(:,:,:,1).*ks.img(:,:,:,3)./(ks.img(:,:,:,2) + ks.img(:,:,:,3)); % 1/s
            img(isnan(img)) = 0;
            
            chi = copy(ks);            
            chi.fileprefix = strrep(ks.fileprefix, 'ks', 'chi');
            chi.img = img * 60;
            chi = mlfourd.ImagingContext2(chi);
            chi.save()
        end
        function cmrglc = ks2cmrglc(ks, cbv, model)
            %% KS2CMRGLC
            %  @param ks is ImagingContext2.
            %  @param cbv is ImagingContext2.
            %  @param model is mlglucose.Huang1980Model.
            %  @return cmrglc is ImagingContext2.
            
            if isempty(cbv)
                chi = mlpet.AbstractAerobicGlycolysisKit2.ks2chi(ks); % 1/s
                glc = mlglucose.Huang1980.glcConversion(model.glc, 'mg/dL', 'umol/hg');                
                cmrglc = chi .* (glc/mlpet.AbstractAerobicGlycolysisKit2.LC);
                cmrglc.fileprefix = strrep(ks.fileprefix, 'ks', 'cmrglc-no-v1');
                return
            end

            v1 = cbv * 0.0105;
            chi = mlpet.AbstractAerobicGlycolysisKit2.ks2chi(ks); % 1/s
            glc = mlglucose.Huang1980.glcConversion(model.glc, 'mg/dL', 'umol/hg');            
            cmrglc = v1 .* chi .* (glc/mlpet.AbstractAerobicGlycolysisKit2.LC);
            cmrglc.fileprefix = strrep(ks.fileprefix, 'ks', 'cmrglc-umol');
        end
        function t = metric2tracer(m)
            %% Returns:
            %      t: lower case tracer code

            assert(istext(m))
            switch char(lower(m))
                case {'cbf' 'fs'}
                    t = 'ho';
                case {'cbv' 'vs'}
                    t = 'oc';
                case {'cmrglc' 'ks'}
                    t = 'fdg';
                case {'cmro2' 'oef' 'os'}
                    t = 'oo';
                otherwise
                    error('mlvg:ValueError', 'QuadraticAerobicGlycolysisKit.metric2tracer.m -> %s', m)
            end
        end
        function oef = os2oef(os)
            %% OS2CHI
            %  @param os is ImagingContext2.
            %  @return oef := k2
            
            os_ = os.nifti;
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
            
            oef = mlpet.AbstractAerobicGlycolysisKit2.os2oef(os);
            o2content = model.NOMINAL_O2_CONTENT;
            cmro2 = oef .* cbf .* o2content;
            cmro2.fileprefix = strrep(os.fileprefix, 'os', 'cmro2');
        end
        function dt = physiologyObjToDatetime(obj)
            ic = mlfourd.ImagingContext2(obj);            
            ss = split(ic.fileprefix, '_');
            re = regexp(ss{2}, 'ses-(?<datetime>\d{14})\w*', 'names');
            dt = datetime(re.datetime, 'InputFormat', 'yyyyMMddHHmmss');
        end
        function dtstr = physiologyObjToDatetimeStr(varargin)
            import mlpet.AbstractAerobicGlycolysisKit2 
            ip = inputParser;
            addRequired(ip, 'obj', @(x) ~isempty(x))
            addParameter(ip, 'dateonly', false, @islogical)
            parse(ip, varargin{:})
            ipr = ip.Results;  
            if ipr.dateonly
                dtstr = [datestr(AbstractAerobicGlycolysisKit2.physiologyObjToDatetime(ipr.obj), 'yyyymmdd') '000000'];
            else
                dtstr = datestr(AbstractAerobicGlycolysisKit2.physiologyObjToDatetime(ipr.obj), 'yyyymmddHHMMSS') ;
            end
        end
        function metricOut = reshapeOnWmparc1(wmparc1, metric, wmparc1Out)
            %% Cf. semantics of pchip or makima.
            
            wmparc1 = mlfourd.ImagingContext2(wmparc1);
            wmparc1 = wmparc1.imagingFormat;
            metric = mlfourd.ImagingContext2(metric);
            metric = metric.imagingFormat;
            wmparc1Out = mlfourd.ImagingContext2(wmparc1Out);
            wmparc1Out = wmparc1Out.imagingFormat;
            metricOut = copy(metric);
            metricOut.img = zeros(size(metric));
            
            for idx = mlpet.AbstractAerobicGlycolysisKit2.indices % parcs
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
            vs_ = vs.imagingFormat;
            if 4 == ndims(vs_)
                vs_.img = vs_.img(:,:,:,1);
            end
            vs_ = mlfourd.ImagingContext2(vs_);
            cbv = mlpet.TracerKinetics.v1ToCbv(vs_);
            cbv.fileprefix = strrep(vs_.fileprefix, 'vs', 'cbv');
        end
    end

    properties
        aifMethods
        aifSuffixedMat
        immediator
        indexCliff
        model
    end
    
	properties (Constant)
        indices = [6000 1:85 213 251:255 1000:1035 2000:2035 3000:3035 4000:4035 5001:5002]
        indices_bilateral = [6000 4 14:16 21:24 43 72 77 80 85 251:255]
        indices_left = [     1:13 17:20 25:39 73 78 81 83 1000:1035 3000:3035 5001]
        indices_right = [   40:52 53:56 57:71 74 79 82 84 2000:2035 4000:4035 5002]

        LC = 0.81 % Wu, et al., Molecular Imaging and Biology, 5(1), 32-41, 2003.
    end
    
	properties (Dependent)
        bids
        indicesToCheck
    end

	methods % GET   
        function g = get.bids(this)
            g = this.immediator.bids;
        end
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
    end

    methods
        function obj = aifsOnAtlas(this, varargin)
            tr = lower(this.immediator.tracer);
            obj = this.metricOnAtlas(['aif_' tr], varargin{:});
        end        
        function obj = applyBrainMask(this, obj)
            msk = this.dlicv();
            fp = obj.fileprefix;
            obj = obj .* msk;
            obj.fileprefix = strrep(fp, '_pet', '-dlicv_pet');            
        end
        function arterial = buildAif(this, devkit, scanner, tac)
            assert(isa(devkit, 'mlsiemens.BiographKit'))
            assert(isa(scanner, 'mlsiemens.BiographDevice'))
            assert(isa(tac, 'mlsiemens.BiographDevice'))
            assert(isa(this.aifMethods, 'containers.Map'))

            TR = upper(scanner.tracer);
            suff = this.aifSuffixedMat;
            if contains(this.aifMethods(TR), 'twilite+caprac', 'IgnoreCase', true)
                arterial1 = devkit.buildArterialSamplingDevice(tac, 'sameWorldline', false);
                arterial1.radialArteryKit.saveas(strcat(scanner.imagingContext.fqfp, suff('twilite')));
                h = plot(arterial1.radialArteryKit);
                try
                    this.savefig(h, 0, 'tags', strcat(scanner.tracer, ' radial artery twilite'), ...
                        'fqfp', strcat(scanner.imagingContext.fqfp, '_', clientname(true), '_twilite'))
                catch ME
                    handwarning(ME)
                end
               
                arterial2 = devkit.buildCountingDevice(tac);
                arterial2.saveas(strcat(scanner.imagingContext.fqfp, suff('caprac')));
                h = plot(arterial2, 'this.times');
                try
                    this.savefig(h, 0, 'tags', strcat(scanner.tracer, ' radial artery caprac'), ...
                        'fqfp', strcat(scanner.imagingContext.fqfp, '_', clientname(true), '_caprac'))
                catch ME
                    handwarning(ME)
                end

                arterial = {arterial1, arterial2};

                % combine
                %dt2 = seconds(arterial2.times) + arterial2.datetime0;
                %dt2 = dt2(arterial2.isWholeBlood');
                %activityDensity2 = arterial2.activityDensity();
                %activityDensity2 = activityDensity2(arterial2.isWholeBlood');
                %arterial.appendActivityDensity(dt2, activityDensity2);
                return
            end
            if contains(this.aifMethods(TR), 'idif',  'IgnoreCase', true)
                arterial = devkit.buildIdif(scanner);
                arterial.saveas(strcat(scanner.imagingContext.fqfp, suff('idif')));
                h = plot(arterial);
                this.savefig(h, 0, 'tags', strcat(scanner.tracer, ' radial artery'))
                return
            end
            if contains(this.aifMethods(TR), 'twilite', 'IgnoreCase', true)
                arterial = devkit.buildArterialSamplingDevice(tac, 'sameWorldline', false);
                arterial.radialArteryKit.saveas(strcat(scanner.imagingContext.fqfp, suff('twilite')));
                h = plot(arterial.radialArteryKit);
                this.savefig(h, 0, 'tags', strcat(scanner.tracer, ' radial artery'), ...
                    'fqfp', strcat(scanner.imagingContext.fqfp, '_', clientname(true)))
                return
            end
            if contains(this.aifMethods(TR), 'twilite_osvd', 'IgnoreCase', true)
                arterial = devkit.buildArterialSamplingDevice(tac, 'sameWorldline', false);
                arterial.radialArteryKit.saveas(strcat(scanner.imagingContext.fqfp, suff('twilite-osvd')));
                h = plot(arterial.radialArteryKit);
                this.savefig(h, 0, 'tags', strcat(scanner.tracer, ' radial artery'), ...
                    'fqfp', strcat(scanner.imagingContext.fqfp, '_', clientname(true)))
                return
            end
            if contains(this.aifMethods(TR), 'caprac', 'IgnoreCase', true)
                arterial = devkit.buildCountingDevice(tac);
                arterial.saveas(strcat(scanner.imagingContext.fqfp, suff('caprac')));
                h = plot(arterial);
                this.savefig(h, 0, 'tags', strcat(scanner.tracer, ' radial artery'))
                return
            end
            error('mlpet:RuntimeError', 'AbstractAerobicGlycolysisKit2.buildAif')
        end

        function obj = cbfOnAtlas(this, varargin)
            obj = this.metricOnAtlas('cbf', varargin{:});
        end
        function obj = cbvOnAtlas(this, varargin)
            obj = this.metricOnAtlas('cbv', varargin{:});
        end
        function obj = cmrgclOnAtlas(this, varargin)
            obj = this.metricOnAtlas('cmrglc', varargin{:});            
        end
        function obj = cmro2OnAtlas(this, varargin)
            obj = this.metricOnAtlas('cmro2', varargin{:});            
        end
        function obj = dlicv(this, varargin)
            obj = this.bids.dlicv_ic(varargin{:});
        end
        function obj = fsOnAtlas(this, varargin)
            obj = this.metricOnAtlas('fs', varargin{:});
        end
        function obj = ksOnAtlas(this, varargin)
            obj = this.metricOnAtlas('ks', varargin{:});
        end
        function obj = metricOnAtlas(this, metric, varargin)
            %% METRICONATLAS appends fileprefixes with information from this.dataAugmentation
            %  @param required metric is char.
            %  @param datetime is datetime or char, .e.g., '20200101000000' | ''.
            %  @param dateonly is logical.
            %  @param tags is char, e.g., 'b43_wmparc1', default ''.
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired(ip, 'metric', @ischar)
            addParameter(ip, 'datetime', this.immediator.datetime, @(x) isdatetime(x) || ischar(x))
            addParameter(ip, 'dateonly', false, @islogical)
            addParameter(ip, 'tags', '', @ischar)
            parse(ip, metric, varargin{:})
            ipr = ip.Results;

            try
                g = glob(fullfile(this.immediator.scanPath, ...
                    sprintf('*_%s_*%s*.nii.gz', metric, ipr.tags)));
                if ~isempty(g)
                    obj = mlfourd.ImagingContext2(g{1});
                    return
                end
            catch ME
                handexcept(ME)
            end
            
            if ~isempty(ipr.tags)
                ipr.tags = strip(ipr.tags, "_");
            end   
            if ischar(ipr.datetime)
                adatestr = ipr.datetime;
            end
            if isdatetime(ipr.datetime)
                if ipr.dateonly
                    adatestr = ['ses-' datestr(ipr.datetime, 'yyyymmdd') '000000'];
                else
                    adatestr = ['ses-' datestr(ipr.datetime, 'yyyymmddHHMMSS')];
                end
            end
            
            s = this.bids.filename2struct(this.immediator.imagingContext.fqfn);
            s.ses = adatestr;
            s.modal = ipr.metric;
            s.tag = ipr.tags;
            fqfn = this.bids.struct2filename(s);
            obj = mlfourd.ImagingContext2(fqfn);
        end	
        function obj = osOnAtlas(this, varargin)
            obj = this.metricOnAtlas('os', varargin{:});
        end
        function resetModelInternal(~)
            mlpet.TracerKineticsModel.solutionOnScannerFrames([], [])
        end 
        function obj = roiOnAtlas(this, idx, varargin)
            obj = this.metricOnAtlas(sprintf('index%g', idx), varargin{:});
        end
        function setScatterFraction(this, scanner, varargin)
            ip = inputParser;
            addRequired(ip, 'scanner', @(x) isa(x, 'mlpet.AbstractDevice'))
            addParameter(ip, 'times', [], @isnumeric)
            parse(ip, scanner, varargin{:})
            ipr = ip.Results;
            
            g = globT(fullfile(this.immediator.scanPath, 'T1001*222*hdr'));
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
                ifc = ic.imagingFormat;
                ifc.img = ifc.img(:,:,:,idxWindow);
                ic = mlfourd.ImagingContext2(ifc);
            end
            suv = ic.timeAveraged();
            scatter = suv.volumeAveraged(ambientMask);
            prompts = suv.volumeAveraged(headMask);
            
            sr = mlraichle.StudyRegistry.instance();
            sr.scatterFraction = scatter.imagingFormat.img/prompts.imagingFormat.img;
        end
        function savefig(this, varargin)
            ip = inputParser;
            addRequired(ip, 'handle', @ishandle) % fig handle
            addOptional(ip, 'idx', 0, @isscalar)
            addParameter(ip, 'tags', '', @istext) % for fig title
            addParameter(ip, 'fqfp', '', @istext)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            if ~isempty(ipr.tags)
                ipr.tags = strcat("_", strip(ipr.tags, "_"));
            end            
            if isempty(ipr.fqfp) % legacy
                ipr.tags = strrep(ipr.tags, " ", "_");
                dtTag = strcat("_", lower(string(this.immediator.datetime(Format='yyyyMMddHHmmss'))));
                client_ = clientname(true);
                ipr.fqfp = fullfile(this.immediator.scanPath, ...
                    sprintf('%s_idx%i%s%s', client_, ipr.idx, ipr.tags, dtTag));
            end
            dtStr = char(this.immediator.datetime());
            title(sprintf('%s.idx == %i\n%s %s', clientname(), ipr.idx, ipr.tags, dtStr))
            savemyfig(ipr.handle, ipr.fqfp)
        end
        function obj = venousOnAtlas(this, varargin)
            obj = this.metricOnAtlas('venous', varargin{:});
        end
        function obj = vsOnAtlas(this, varargin)
            obj = this.metricOnAtlas('vs', varargin{:});
        end
        function obj = wmparc1OnAtlas(this, varargin)
            %% idx == 40:  venuos voxels
            %  idx == 1:   extraparenchymal CSF, not ventricles

            import mlfourd.ImagingFormatContext2
            import mlfourd.ImagingContext2

            if ~isempty(this.wmparc1OnAtlas_)
                obj = this.wmparc1OnAtlas_;
                return
            end

            obj = this.metricOnAtlas('wmparc1', varargin{:});
            fqfn = obj.fqfn;
            if isfile(fqfn)
                this.wmparc1OnAtlas_ = obj;
                return
            end
            
            pwd0 = pushd(myfileparts(fqfn));
            
            % constructWmparcOnAtlas
            bids_ = this.bids;
            out_ = fullfile(bids_.t1w_ic.filepath, 'T1_on_T1w.nii.gz');
            omat_ = strrep(out_, '.nii.gz', '.mat');
            flirting = mlfsl.Flirt( ...
                'in', bids_.T1_ic.fqfn, ...
                'ref', bids_.t1w_ic.fqfn, ...
                'out', out_, ...
                'omat', omat_, ...
                'bins', 256, ...
                'cost', 'corratio', ...
                'dof', 6, ...
                'interp', 'nearestneighbour');
            flirting.flirt();
            flirting.in = bids_.wmparc_ic.fqfn;
            flirting.out = this.metricOnAtlas('wmparc', varargin{:}).fqfn;
            flirting.applyXfm();
            
            % define CSF; idx := 1
            wmparc = flirting.out.imagingFormat;
            %wmparc.selectNiftiTool();
            wmparc1 = this.dlicv.imagingFormat; % establish ICV := CSF + parenchyma
            %wmparc1.selectNiftiTool();
            
            % define venous; idx := 40
            ven = this.cbvOnAtlas();
            ven = ven.blurred(this.immediator.petPointSpread);
            ven = ven.thresh(dipmax(ven)/2);
            ven = ven.binarized();
            ven.fqfn = this.venousOnAtlas().fqfn;
            try
                ven.save();
            catch ME
                handwarning(ME)
            end
            selected = logical(ven.imagingFormat.img) & 1 == wmparc1.img;
            wmparc1.img(selected) = 40; % co-opting right cerebral exterior            

            % assign wmparc indices
            wmparc1.img = int32(wmparc1.img);
            wmparc1.img(wmparc.img > 0) = wmparc.img(wmparc.img > 0);

            % construct wmparc1
            obj = ImagingContext2(wmparc1);
            obj.fqfn = fqfn;
            obj.save();
            this.wmparc1OnAtlas_ = obj;

            popd(pwd0);
        end
    end
    
    %% PROTECTED

    properties (Access = protected)
        wmparc1OnAtlas_
    end
    
    methods (Access = protected)
 		function this = AbstractAerobicGlycolysisKit2(varargin)
            am = containers.Map;
            am('CO') = 'twilite';
            am('OC') = 'twilite';
            am('OO') = 'twilite';
            am('HO') = 'twilite';
            am('FDG') = 'twilite+caprac';

            ip = inputParser;
            ip.KeepUnmatched = true;
            ip.PartialMatching = false;
            addRequired(ip, 'immediator', @(x) isa(x, 'mlpipeline.ImagingMediator'))
            addParameter(ip, 'indexCliff', [], @isnumeric)
            addParameter(ip, 'aifMethods', am, @(x) isa(x, 'containers.Map'))
            parse(ip, varargin{:})
            ipr = ip.Results;

            this.immediator = ipr.immediator;
            this.indexCliff = ipr.indexCliff;
            this.aifMethods = ipr.aifMethods;

            this.aifSuffixedMat = containers.Map;
            this.aifSuffixedMat('idif') = '_buildAif-idif.mat';
            this.aifSuffixedMat('twilite') = '_buildAif-twilite.mat';
            this.aifSuffixedMat('twilite_osvd') = '_buildAif-twilite-osvd.mat';
            this.aifSuffixedMat('caprac') = '_buildAif-caprac.mat';
            this.aifSuffixedMat('twilite+caprac') = '_buildAif-twilite-caprac.mat';

            this.resetModelInternal()
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

