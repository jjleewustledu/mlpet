classdef AerobicGlycolysisKit < handle & mlpet.IAerobicGlycolysisKit
	%% AEROBICGLYCOLYSISKIT  

	%  $Revision$
 	%  was created 01-Apr-2020 11:09:38 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.7.0.1319299 (R2019b) Update 5 for MACI64.  Copyright 2020 John Joowon Lee.
 	 	
    properties (Constant)
        LC = 0.81 % Wu, et al., Molecular Imaging and Biology, 5(1), 32-41, 2003.
    end
    
	properties (Dependent)
        blurTag
        sessionData
 	end

	methods (Static)
        function ic = constructWmparc1OnAtlas(sesd)
            import mlfourd.ImagingFormatContext
            import mlfourd.ImagingContext2
            
            if isfile(sesd.wmparc1OnAtlas)
                ic = ImagingContext2(sesd.wmparc1OnAtlas);
                return
            end
            
            wmparc = ImagingFormatContext(sesd.wmparcOnAtlas());
            wmparc1 = ImagingFormatContext(sesd.brainOnAtlas());
            wmparc1.fileprefix = sesd.wmparc1OnAtlas('typ', 'fp');
            wmparc1.img(wmparc1.img > 0) = 1;
            wmparc1.img(wmparc.img > 0) = wmparc.img(wmparc.img > 0);
            ic = ImagingContext2(wmparc1);
            ic.save()
        end
        function this = createFromSession(sesd)
            switch class(sesd)
                case 'mlraichle.SessionData'
                    this = mlraichle.AerobicGlycolysisKit.createFromSession(sesd);
                case 'mlan.SessionData'
                    this = mlan.AerobicGlycolysisKit.createFromSession(sesd);
                case 'mlvg.SessionData'
                    this = mlvg.AerobicGlycolysisKit.createFromSession(sesd);
                otherwise
                    error('mlpet:ValueError', ...
                        'AerobicGlycolysisKit does not support %s', class(study))
            end
        end  
        function jitOn222(fexp)
            %  @param fexp is char, e.g., 'subjects/sub-S58163/resampling_restricted/ocdt20190523122016_222.4dfp.hdr'
            
            mlnipet.ResolvingSessionData.jitOn222(fexp);
        end      
        function jitOnT1001(fexp)
            %  @param fexp is char, e.g., 'subjects/sub-S58163/resampling_restricted/ocdt20190523122016_on_T1001.4dfp.hdr'
            
            mlnipet.ResolvingSessionData.jitOnT1001(fexp);
        end
        function chi = ks2chi(ksobj, cbvobj)
            %  @param ksobj
            %  @param cbvobj
            %  @return chi := K1 k3/(k2 + k3) in 1/s            
            
            ks = mlfourd.ImagingContext2(ksobj);
            ks = ks.fourdfp;            
            cbv = mlfourd.ImagingContext2(cbvobj);
            cbv = cbv.fourdfp; % ml/hg
            
            assert(contains(ks.fileprefix, 'ks'))
            % brain density ~ 1.05
            img = 0.0105*cbv.img.*ks.img(:,:,:,1).*ks.img(:,:,:,3)./(ks.img(:,:,:,2) + ks.img(:,:,:,3)); % 1/s
            img(isnan(img)) = 0;
            chi = copy(ks);            
            chi.fileprefix = strrep(ks.fileprefix, 'ks', 'chi');
            chi.img = img;
            chi = mlfourd.ImagingContext2(chi);
        end
        function cmrglc = ks2cmrglc(ksobj, cbvobj, radmeas)
            %% @param required ksobj contians ks in R^4.
            %  @param required cbvobj contains cbv in R^3.
            %  @param required radmeas is mlpet.CCIRRadMeasurements of numeric (mg/dL).
            
            chi = mlpet.AerobicGlycolysisKit.ks2chi(ksobj, cbvobj); % 1/s
            chifp = chi.fileprefix;
            chi = chi * 60; % 1/min
            
            if isa(radmeas, 'mlpet.CCIRRadMeasurements')
                fdgglc = cellfun(@str2double, radmeas.fromPamStone.Var1(10:12)); % empty cell -> nan
                glc = mean(fdgglc, 'omitnan'); % mg/dL
                % brain density ~ 1.05
                glc = (1e3 * 0.0555 * 0.1 * 0.01 * 100 / 1.05) * glc; % [umol/mmol] [(mmol/L) / (mg/dL)] [L/dL] [dL/mL] [g/hg] [mL/g] == [umol/hg]            
            elseif isnumeric(radmeas)
                glc = (1e3 * 0.0555 * 0.1 * 0.01 * 100 / 1.05) * radmeas;
            else
                error('mlpet:ValueError', 'AerobicGlycolysisKit.ks2cmrglc.radmeas was %s', class(radmeas))
            end
            
            cmrglc = chi*(glc/mlpet.AerobicGlycolysisKit.LC);
            cmrglc.fileprefix = strrep(chifp, 'chi', 'cmrglc');
        end
    end 
    
    methods
        
        %% GET
        
        function g = get.blurTag(this)
           blur = this.sessionData.petPointSpread; 
           g = sprintf('_b%i', round(blur*10));
        end        
        function g = get.sessionData(this)
            g = this.sessionData_;
        end
        
        %%
        
        function buildAgi(this)
        end
        function cbv = buildCbv(this, varargin)
            %% BUILDCRV
            %  @param foldersExpr in {'subjects' 'subjects/sub-S12345' 'subjects/sub-S12345/ses-E12345'}
            %  @param roisExpr in {'brain' 'Desikan' 'Destrieux' 'wm'}; default := 'brain'
            %  @return mlfourd.ImagingContext2
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'filesExpr', '', @ischar)
            addParameter(ip, 'foldersExpr', '', @ischar)
            addParameter(ip, 'roisExpr', 'brain', @ischar)
            addParameter(ip, 'averageVoxels', true, @islogical)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            sesdSet = {};
            if ~isempty(ipr.filesExpr)   
                sesdSet = this.filesExpr2sessions(ipr.filesExpr);
            end
            if ~isempty(ipr.foldersExpr)
                sesdSet = this.foldersExpr2sessions(ipr.foldersExpr);
            end
            for sesd = sesdSet
                devkit = mlpet.ScannerKit.createFromSession(sesd{1});
                devkit.stageResamplingRestricted();
                martin = mloxygen.Martin1987.createFromDeviceKit(devkit);
                roiset = this.roisExpr2roiSet(ipr.roisExpr);
                for roi = roiset
                    cbv = martin.buildCbv('roi', roi{1}, varargin{:});
                    martin.buildQC('roi', roi{1}, 'cbv', cbv, varargin{:});
                    cbv.save
                end                    
            end
        end
        function buildCbf(this)
        end
        function buildCMRglc(this)
        end
        function buildCMRO2(this)
        end
        function buildKs(this, varargin)
            %% BUILDKS
            %  @param foldersExpr in {'subjects' 'subjects/sub-S12345' 'subjects/sub-S12345/ses-E12345'}
            %  @param roisExpr in {'brain' 'Desikan' 'Destrieux' 'wm'}; default := 'wmparc'
            %  @param cpuIndex is numeric
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'filesExpr', '', @ischar)
            addParameter(ip, 'foldersExpr', '', @ischar)
            addParameter(ip, 'roisExpr', 'brain', @ischar)
            addParameter(ip, 'cpuIndex', [], @(x) isnumeric(x) && ~isempty(x))
            addParameter(ip, 'averageVoxels', false, @islogical)
            parse(ip, varargin{:})
            ipr = ip.Results;
            disp(ipr)
            
            for sesd = this.filesExpr2sessions(ipr.filesExpr)
                sesd1 = sesd{1};
                pwd0 = pushd(sesd1.tracerResolvedOpSubject('typ', 'path'));
                disp(sesd1)
                devkit = mlpet.ScannerKit.createFromSession(sesd1);
                disp(devkit)
                devkit.stageResamplingRestricted()
                reg = sesd1.registry;
                if reg.useParfor
                    roiset = cell(1, reg.numberNodes);
                    for cpui = 1:reg.numberNodes
                        roiset{cpui} = this.roisExpr2roiSet(ipr.roisExpr, 'cpuIndex', cpui);
                    end
                    cbvfn = sesd1.cbvOnAtlas('typ', 'fn', 'dateonly', true);
                    fprintf('mlpet.AerobicGlycolysisKit.buildKs():  cbvfn->%s\n', cbvfn)                    
                    fqstem = sesd1.ksOnAtlas('typ', 'fqfp');
                    huangset = {};
                    petPointSpread = sesd1.petPointSpread;
                    blurTag_ = this.blurTag;
                    parfor iroi = 1:length(roiset)
                        if ~isfile(sprintf('%s%s_%s.4dfp.img', fqstem, blurTag_, roiset{iroi}{1}.fileprefix))
                            fprintf('mlpet.AerobicGlycolysisKit.buildKs():  roiset{iroi}.fileprefix->%s\n', roiset{iroi}{1}.fileprefix)
                            huang = mlglucose.ImagingHuang1980.createFromDeviceKit( ...
                                devkit, 'cbv', cbvfn, 'roi', roiset{iroi}{1}, 'blur', petPointSpread);
                            huang = huang.solve();
                            huangset{iroi} = huang;
                        end
                    end
                    for hi = 1:length(huangset)
                        if ~isempty(huangset{hi})
                            save(huangset{hi}.ks)
                        end
                    end
                else                    
                    roiset = this.roisExpr2roiSet(ipr.roisExpr, 'cpuIndex', ipr.cpuIndex);
                    for roi = roiset
                        cbvfn = sesd1.cbvOnAtlas('typ', 'fn', 'dateonly', true);
                        fprintf('mlpet.AerobicGlycolysisKit.buildKs():  cbvfn->%s\n', cbvfn)
                        fprintf('mlpet.AerobicGlycolysisKit.buildKs():  roi{1}.fileprefix->%s\n', roi{1}.fileprefix)
                        huang = mlglucose.ImagingHuang1980.createFromDeviceKit( ...
                            devkit, 'cbv', cbvfn, 'roi', roi{1}, 'blur', sesd1.petPointSpread);
                        huang = huang.solve();
                        save(huang.ks)
                    end
                end
                popd(pwd0)
            end
        end
        function kss = buildKsByWmparc1(this, varargin)
            %% BUILDKSBYWMPARC1
            %  @param foldersExpr in {'subjects' 'subjects/sub-S12345' 'subjects/sub-S12345/ses-E12345'}
            %  @param roisExpr in {'brain' 'Desikan' 'Destrieux' 'wm'}; default := 'wmparc'
            %  @param blur is numeric, default is 4.3.
            %  @return kss as mlfourd.ImagingContext2 or cell array, without saving to filesystems.
            
            indices = [1 1000:1035 2000:2035 3000:3035 4000:4035 5001:5002 2:85 251:255];
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'filesExpr', '', @ischar)
            addParameter(ip, 'foldersExpr', '', @ischar)
            parse(ip, varargin{:})
            ipr = ip.Results;
            disp(ipr)
            
            kss = {};
            for sesd = this.filesExpr2sessions(ipr.filesExpr)
                sesd1 = sesd{1};
                pwd0 = pushd(sesd1.tracerResolvedOpSubject('typ', 'path'));                
                devkit = mlpet.ScannerKit.createFromSession(sesd1);                
                cbv = sesd1.cbvOnAtlas('typ', 'mlfourd.ImagingContext2', 'dateonly', true);
                cbv = cbv.fourdfp;
                wmparc1 = sesd1.wmparc1OnAtlas('typ', 'mlfourd.ImagingContext2');
                wmparc1 = wmparc1.fourdfp;
                ks = copy(wmparc1);
                ks.fileprefix = [sesd1.ksOnAtlas('typ', 'fp') this.blurTag '_wmparc1'];
                ks.img = zeros([size(wmparc1) 5]);   

                for idx = indices % parcs
                    
                    % for parcs, build roibin as logical, roi as single                    
                    fprintf('starting mlpet.AerobicGlycolysisKit.buildKsByParc.idx -> %i\n', idx)
                    tic
                    roi = copy(wmparc1);
                    roibin = wmparc1.img == idx;
                    roi.img = single(roibin);  
                    roi.fileprefix = sprintf('%s_index%i', roi.fileprefix, idx);
                    if 0 == dipsum(roi.img)
                        continue
                    end

                    % solve Huang
                    huang = mlglucose.NumericHuang1980.createFromDeviceKit( ...
                        devkit, 'cbv', mean(cbv.img(roibin)), 'roi', mlfourd.ImagingContext2(roi));
                    huang = huang.solve();
                    toc

                    % insert Huang solutions on roibin(idx) into ks
                    for ik = 1:4
                        rate = ks.img(:,:,:,ik);
                        kscache = huang.ks();
                        rate(roibin) = kscache(ik);
                        ks.img(:,:,:,ik) = rate;
                    end
                    rate = ks.img(:,:,:,5);
                    rate(roibin) = huang.Dt;
                    ks.img(:,:,:,5) = rate;
                end
                
                ks = mlfourd.ImagingContext2(ks);
                kss = [kss ks]; %#ok<AGROW>
                popd(pwd0)
            end
        end
        function buildOef(this)
        end
        function buildOgi(this)
        end
        function [roiset,ifc] = buildRoiset(this, rexp, varargin)
            %% e.g., this.buildRoiset('brain', 'cpuIndex', 1)
            
            [roiset,ifc] = this.roisExpr2roiSet(rexp, varargin{:});
        end
        function N = estimateNumNodes(this, sesinfo, rexp)
            %  @param sesinfo is char.
            %  @param rexp in {'brain' 'brainmask' 'wmparc'}
            %  @return num nodes needed
            
            [~,ifc] = this.buildRoiset(rexp);
            registry = this.sessionData.registry;
            N = ceil(dipsum(ifc.img)/(registry.wallClockLimit/registry.voxelTime));
            registry.numberNodes = N;
            
            fprintf('##############################################################################################\n')
            disp(sesinfo)
            fprintf('mlpet.AerobicGlycolysisKit.estimateNumNodes.N -> %i\n', N)
            fprintf('##############################################################################################\n')
        end
        function sesds = filesExpr2sessions(this, fexp)
            % @param fexp is char, e.g., 'subjects/sub-S58163/resampling_restricted/ocdt20190523122016_on_T1001.4dfp.hdr'
            % @return instance from this.sessionData_.create()
            
            assert(ischar(fexp))
            sesds = {};
            ss = strsplit(fexp, filesep);
            assert(strcmp(ss{1}, 'subjects'))
            assert(strcmp(ss{3}, 'resampling_restricted'))
            this.jitOnT1001(fexp)

            pwd0 = pushd(fullfile(getenv('SINGULARITY_HOME'), ss{1}, ss{2}, ''));
            re = regexp(ss{4}, '(?<tracer>[a-z]{2,3})dt(?<datetime>\d{14})\w+', 'names');            
            for globTracer = globFoldersT( ...
                    fullfile('ses-E*', sprintf('%s_DT%s.000000-Converted-AC', upper(re.tracer), re.datetime)))
                for ccir = {'CCIR_00559' 'CCIR_00754'}
                    sesf = fullfile(ccir{1}, globTracer{1});
                    if isfolder(fullfile(getenv('SINGULARITY_HOME'), sesf))
                        sesds = [sesds {this.sessionData_.create(sesf)}]; %#ok<AGROW>
                    end
                end
            end            
            popd(pwd0)
        end
        function sesds = foldersExpr2sessions(this, fexp)
            % @param fexp is char
            % @return *.SessionData
            
            assert(ischar(fexp))
            sesds = {};
            ss = strsplit(fexp, filesep);
            pwd0 = pushd(getenv('SINGULARITY_HOME'));
            switch length(ss)
                case 1
                    for subpth = globFoldersT(fullfile(fexp, 'sub-S*'))
                        for sespth = globFoldersT(fullfile(subpth{1}, 'ses-E*'))
                            for trapth = globFoldersT( ...
                                    fullfile(sespth{1}, sprintf('%s_DT*.*-Converted-AC', upper(this.sessionData.tracer))))
                                sesds = [sesds {this.sessionData.create(trapth{1})}]; %#ok<AGROW>
                            end
                        end
                    end
                case 2
                    for sespth = globFoldersT(fullfile(fexp, 'ses-E*'))
                        for trapth = globFoldersT( ...
                                fullfile(sespth{1}, sprintf('%s_DT*.*-Converted-AC', upper(this.sessionData.tracer))))
                            sesds = [sesds {this.sessionData.create(trapth{1})}]; %#ok<AGROW>
                        end
                    end
                case 3
                    for trapth = globFoldersT( ...
                            fullfile(fexp, sprintf('%s_DT*.*-Converted-AC', upper(this.sessionData.tracer))))
                        sesds = [sesds {this.sessionData.create(trapth{1})}]; %#ok<AGROW>
                    end
                case 4
                    trapth = globFoldersT(fullfile(fexp));
                    sesds = {this.sessionData.create(trapth{1})};
                otherwise
                    error('mlpet:ValueError', ...
                        'AerobicGlycolysisKit.foldersExp2session(%) is not supported', fexp)
            end
            popd(pwd0)
        end        
        function ic = ksOnAtlasTagged(this, varargin)
            %% @param lasttag := {'' '_b43'}
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addOptional(ip, 'lastKsTag', '', @ischar)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            fqfp = [this.sessionData.ksOnAtlas('typ', 'fqfp') this.blurTag this.regionTag ipr.lastKsTag];
            
            % 4dfp exists
            if isfile([fqfp '.4dfp.hdr'])
                ic = mlfourd.ImagingContext2([fqfp '.4dfp.hdr']);
                return
            end
            
            % Luckett-mat exists
            ifc = mlfourd.ImagingFormatContext(this.sessionData.fdgOnAtlas);
            ifc.fileprefix = mybasename(fqfp);
            if isfile([fqfp '.mat'])
                ks = load([fqfp '.mat'], 'img');
                ifc.img = reshape(single(ks.img), [128 128 75 4]);
                ic = mlfourd.ImagingContext2(ifc);
                ic.save()
                return
            end
            
            error('mlraichle:RuntimeError', 'AerobicGlycolysis.ksOnAtlas')
        end
        function h  = loadImagingHuang(this)
            %%
            %  @return mlglucose.ImagingHuang1980
            
            devkit = mlpet.ScannerKit.createFromSession(this.sessionData);
            cbv = mlfourd.ImagingContext2(this.sessionData.cbvOnAtlas('dateonly', true));
            mask = this.maskOnAtlasTagged();
            ks = this.ksOnAtlasTagged('_b43');
            h = mlglucose.ImagingHuang1980.createFromDeviceKit( ...
                devkit, 'cbv', cbv, 'roi', mask, 'regionTag', this.regionTag);
            h.ks = ks;
        end
        function h  = loadNumericHuang(this, roi)
            %%
            %  @param roi is understood by mlfourd.ImagingContext2
            %  @return mlglucose.NumericHuang1980
            
            roi = mlfourd.ImagingContext2(roi);
            roi = roi.binarized();
            roibin = logical(roi.fourdfp.img);
            devkit = mlpet.ScannerKit.createFromSession(this.sessionData);
            cbv = mlfourd.ImagingContext2(this.sessionData.cbvOnAtlas('dateonly', true));
            mean_cbv = cbv.fourdfp.img(roibin);            
            h = mlglucose.NumericHuang1980.createFromDeviceKit( ...
                devkit, 'cbv', mean_cbv, 'roi', roi);
        end
        function ic = maskOnAtlasTagged(this, varargin)
            fqfp = [this.sessionData.wmparc1OnAtlas('typ', 'fqfp') '_binarized' this.blurTag '_binarized'];
            
            % 4dfp exists
            if isfile([fqfp '.4dfp.hdr'])
                ic = mlfourd.ImagingContext2([fqfp '.4dfp.hdr']);
                return
            end
            
            % Luckett-mat exists
            ifc = mlfourd.ImagingFormatContext(this.sessionData.fdgOnAtlas);
            ifc.fileprefix = mybasename(fqfp);
            if isfile([fqfp '.mat'])
                msk = load([fqfp '.mat'], 'img');
                ifc.img = reshape(single(msk.img), [128 128 75]);
                ic = mlfourd.ImagingContext2(ifc);
                ic.save()
                return
            end
            
            error('mlraichle:RuntimeError', 'AerobicGlycolysis.maskOnAtlasTagged')
        end
        function [roiset,ifc] = roisExpr2roiSet(this, rexp, varargin)
            sesd = this.sessionData;
            rois = mlpet.Rois.createFromSession(sesd);
            switch rexp
                case {'brain' 'brainmask' 'wholebrain' 'wb'}
                    [roiset,ifc] = rois.constructBrainSet(varargin{:});
                case {'Desikan' 'aparc+aseg'}
                    [roiset,ifc] = rois.constructDesikanSet(varargin{:});
                case {'Destrieux' 'aparc.a2009s+aseg'}
                    [roiset,ifc] = rois.constructDestrieuxSet(varargin{:});
                case {'wm' 'wmparc'}
                    [roiset,ifc] = rois.constructWmSet(varargin{:});
                otherwise 
                    error('mlpet:ValueError', ...
                        'AerobicClycolysisKit.roisExpr2roiSet.rexp -> %s', rexp)
            end
        end
    end

    %% PROTECTED
    
    properties (Access = protected)
        sessionData_
    end
    
    methods (Access = protected)
        function this = AerobicGlycolysisKit(varargin)
            ip = inputParser;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlpipeline.ISessionData'))
            parse(ip, varargin{:})
            this.sessionData_ = ip.Results.sessionData;
        end
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
end

