classdef AerobicGlycolysisKit < handle & mlpet.TracerKinetics & mlpet.IAerobicGlycolysisKit
	%% AEROBICGLYCOLYSISKIT  

	%  $Revision$
 	%  was created 01-Apr-2020 11:09:38 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.7.0.1319299 (R2019b) Update 5 for MACI64.  Copyright 2020 John Joowon Lee.
 	 	
    properties (Constant)
        LC = 0.81 % Wu, et al., Molecular Imaging and Biology, 5(1), 32-41, 2003.
        E_MIN = 0.7
        E_MAX = 0.93
        indices = [1:85 192:255 1000:1035 2000:2035 3000:3035 4000:4035 5001:5002 6000];
        indicesL = [14:16  1:13 17:20 25:39 21:24 72 73 77 78 80 81 83 85 192 193:196 201:255 1000:1035 3000:3035 5001 6000];
        indicesR = [14:16 40:71             21:24 72 74 77 79 80 82 84 85 192 197:200 201:255 2000:2035 4000:4035 5002 6000];
    end
    
	properties (Dependent)
        blurTag
        indicesToCheck
        regionTag
 	end

	methods (Static)
        function ic     = constructWmparc1OnAtlas(sesd)
            import mlfourd.ImagingContext2
            
            if isfile(sesd.wmparc1OnAtlas)
                ic = ImagingContext2(sesd.wmparc1OnAtlas);
                return
            end
            
            wmparc = sesd.wmparcOnAtlas('typ', 'mlfourd.ImagingFormatContext');
            wmparc1 = sesd.brainOnAtlas('typ', 'mlfourd.ImagingFormatContext');
            wmparc1.fileprefix = sesd.wmparc1OnAtlas('typ', 'fp');
            wmparc1.img(wmparc1.img > 0) = 1;
            wmparc1.img(wmparc.img > 0) = wmparc.img(wmparc.img > 0);
            ic = ImagingContext2(wmparc1);
            ic.save()
        end
        function this   = createFromSession(sesd)
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
        function ic     = iccrop(ic, toKeep)
            ifc = ic.fourdfp;
            ifc.img = ifc.img(:,:,:,toKeep);
            %ifc.fileprefix = sprintf('%s_iccrop%ito%i', ifc.fileprefix, toKeep(1), toKeep(end));
            ic = mlfourd.ImagingContext2(ifc);
        end
        function matfn  = ic2mat(ic)
            %% @param required ic is mlfourd.ImagingContext2 | cell
            
            if isempty(ic) % for unit testing
                matfn = '';
                return
            end
            
            if iscell(ic)
                matfn = {};
                for anic = ic
                    matfn = [matfn mlpet.AerobicGlycolysisKit.ic2mat(anic)]; %#ok<AGROW>
                end
                return
            end
            
            assert(isa(ic, 'mlfourd.ImagingContext2'))
            sz = size(ic);
            assert(length(sz) >= 3)
            if length(sz) == 3
                sz = [sz 1];
            end
            img = reshape(flip(ic.fourdfp.img, 2), [sz(1)*sz(2)*sz(3) sz(4)]);
            matfn = [ic.fqfileprefix '.mat'];
            save(matfn, 'img')
        end   
        function          jitOn222(fexp)
            %  @param fexp is char, e.g., 'subjects/sub-S58163/resampling_restricted/ocdt20190523122016_222.4dfp.hdr'
            
            mlnipet.ResolvingSessionData.jitOn222(fexp);
        end      
        function          jitOnT1001(fexp)
            %  @param fexp is char, e.g., 'subjects/sub-S58163/resampling_restricted/ocdt20190523122016_on_T1001.4dfp.hdr'
            
            mlnipet.ResolvingSessionData.jitOnT1001(fexp);
        end
        function chi    = ks2chi(ksobj)
            %  @param ksobj
            %  @return chi := k1 k3/(k2 + k3) in 1/s, without v1.
            
            ks = mlfourd.ImagingContext2(ksobj);
            ks = ks.fourdfp;            
            assert(contains(ks.fileprefix, 'ks'))
            img = ks.img(:,:,:,1).*ks.img(:,:,:,3)./(ks.img(:,:,:,2) + ks.img(:,:,:,3)); % 1/s
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
            
            import mlglucose.Huang1980
            
            chi = mlpet.AerobicGlycolysisKit.ks2chi(ksobj); % 1/s
            chifp = chi.fileprefix;
            chi = chi * 60; % 1/min
            
            v1 = mlfourd.ImagingContext2(cbvobj);
            v1 = v1 .* 0.0105;
            if ~contains(v1.fileprefix, '_b')
                v1 = v1.blurred(4.3);
            end % mL blood / mL tissue
            
            if isa(radmeas, 'mlpet.CCIRRadMeasurements')
                glc = Huang1980.glcFromRadMeasurements(radmeas);           
            elseif isnumeric(radmeas)
                glc = radmeas;
            else
                error('mlpet:ValueError', 'AerobicGlycolysisKit.ks2cmrglc.radmeas was %s', class(radmeas))
            end            
            glc = Huang1980.glcConversion(glc, 'mg/dL', 'umol/hg');
            
            cmrglc = v1 .* chi .* (glc/mlpet.AerobicGlycolysisKit.LC);
            cmrglc.fileprefix = strrep(chifp, 'chi', 'cmrglc');
        end         
        function msk    = ks2mask(ic)
            %% @param required ic is mlfourd.ImagingContext2 | cell
            
            if iscell(ic)
                msk = {};
                for anic = ic
                    msk = [msk mlpet.AerobicGlycolysisKit.ks2mask(anic)]; %#ok<AGROW>
                end
                return
            end
            
            assert(isa(ic, 'mlfourd.ImagingContext2'))            
            assert(length(size(ic)) == 4)
            cache = copy(ic.fourdfp);
            cache.fileprefix = strrep(ic.fileprefix, 'ks', 'mask');
            cache.img = single(cache.img(:,:,:,1) > 0);
            msk = mlfourd.ImagingContext2(cache);
        end    
        function E      = metric2E(mobj)
            %% @param required fsobj contains fs in R^3.
            
            import mloxygen.Raichle1983
            import mlpet.AerobicGlycolysisKit
            import mlpet.TracerKinetics.unitlessToLambda
            
            m = mlfourd.ImagingContext2(mobj);
            m = m.fourdfp;
            msk = m.img(:,:,:,1) > 0;
            img = 1 - exp(-m.img(:,:,:,2) ./ m.img(:,:,:,1));
            img(isnan(img)) = 0;
            img(img > AerobicGlycolysisKit.E_MAX) = AerobicGlycolysisKit.E_MAX;
            img(img < AerobicGlycolysisKit.E_MIN) = AerobicGlycolysisKit.E_MIN;
            img = img .* msk;
            
            E = copy(m);  
            re = regexp(m.fileprefix, '(?<metric>\w+)dt\d{14}_\S+', 'names');          
            E.fileprefix = strrep(m.fileprefix, re.metric, [re.metric '_E']);
            E.img = img;
            E = mlfourd.ImagingContext2(E);
        end
        function cbf    = metric2cbf(mobj)
            %% @param required fsobj contains fs in R^3.
            
            import mloxygen.Raichle1983
            import mlpet.TracerKinetics.f1ToCbf
            import mlpet.TracerKinetics.unitlessToLambda
            
            m = mlfourd.ImagingContext2(mobj);
            m = m.fourdfp;            
            img = zeros(size(m));
            for t = 1:2 % f, PS =: mL/min/hg
                img(:,:,:,t) = f1ToCbf(m.img(:,:,:,t));
            end
            img(:,:,:,3) = unitlessToLambda(m.img(:,:,:,3));
            img(isnan(img)) = 0;
            
            cbf = copy(m);
            re = regexp(m.fileprefix, '(?<metric>\w+)dt\d{14}_\S+', 'names');
            cbf.fileprefix = strrep(m.fileprefix, re.metric, [re.metric '_cbf']);
            cbf.img = img;
            cbf = mlfourd.ImagingContext2(cbf);
        end   
    end 
    
    methods
        
        %% GET
        
        function g = get.blurTag(this)
           blur = this.sessionData.petPointSpread; 
           g = sprintf('_b%i', round(blur*10));
        end   
        function g = get.indicesToCheck(this)
            if isdeployed()
                g = 0;
            else
                if ~isempty(getenv('NOPLOT'))
                    g = [];
                    return
                end
                if ~isempty(getenv('DEBUG'))
                    g = this.indices;
                    return
                end
                g = [1 7:13 16:20 24 26:28 1001 2001 3001 4001 5001 5002 6000];
            end
        end     
        function g = get.regionTag(this)
            g = this.sessionData.regionTag;
        end   
        
        %%
        
        function         buildAgi(this)
        end
        function cbf   = buildCbfByQuadModel(this)
            devkit = mlpet.ScannerKit.createFromSession(this.sessionData);
            raichle = mloxygen.Raichle1983.createFromDeviceKit(devkit);
            cbf = raichle.buildCbfByQuadModel( ...
                'roi', this.sessionData.wbrain1OnAtlas('typ', 'mlfourd.ImagingContext2'));
        end
        function cbv   = buildCbv(this, varargin)
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
                martin = mloxygen.Martin1987.createFromDeviceKit(devkit);
                roiset = this.roisExpr2roiSet(ipr.roisExpr);
                for roi = roiset
                    cbv = martin.buildCbv('roi', roi{1}, varargin{:});
                    martin.buildQC('roi', roi{1}, 'cbv', cbv, varargin{:});
                    cbv.save
                end                    
            end
        end
        function f     = buildFs(this, varargin)
            f = this.buildFsByWmparc1(varargin{:});
        end
        function fs    = buildFsByWmparc1(this, varargin)
            %% BUILDFBYWMPARC1
            %  @param sessionData is mlpipeline.ISessionData.
            %  @param indicesToCheck:  e.g., [6000 1 7:20 24].
            %  @return fs as mlfourd.ImagingContext2, without saving to filesystems.
            
            indices = [6000 1:85 251:255 1000:1035 2000:2035 3000:3035 4000:4035 5001:5002];
            if isdeployed()
                indicesToCheck = 0;
            else
                indicesToCheck = [6000 1 7:20 24 26:28];
            end
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', this.sessionData, @(x) isa(x, 'mlpipeline.ISessionData'))
            addParameter(ip, 'indicesToCheck', indicesToCheck, @(x) any(x == indices) || isempty(x))
            parse(ip, varargin{:})
            ipr = ip.Results;
            disp(ipr)
            
            sesd = ipr.sessionData;
            sesd.region = 'wmparc1';
            workdir = sesd.tracerResolvedOpSubject('typ', 'path');
            
            pwd0 = pushd(workdir);            
            this.buildDataAugmentation(sesd);            
            devkit = mlpet.ScannerKit.createFromSession(sesd);  
            wmparc1 = sesd.wmparc1OnAtlas('typ', 'mlfourd.ImagingContext2');
            wmparc1 = wmparc1.fourdfp;
            fs = copy(wmparc1);
            fs.fileprefix = sesd.fsOnAtlas('typ', 'fp', 'tags', [this.blurTag '_wmparc1']);
            lenKs = mloxygen.NumericRaichle1983.LENK + 1;
            fs.img = zeros([size(wmparc1) lenKs]);   

            for idx = indices % parcs

                % for parcs, build roibin as logical, roi as single                    
                fprintf('starting mlpet.AerobicGlycolysisKit.buildFsByWmparc1.idx -> %i\n', idx)
                tic
                roi = copy(wmparc1);
                roibin = wmparc1.img == idx;
                roi.img = single(roibin);  
                roi.fileprefix = sprintf('%s_index%i', roi.fileprefix, idx);
                if 0 == dipsum(roi.img)
                    continue
                end

                % solve Raichle
                raichle = mloxygen.NumericRaichle1983.createFromDeviceKit( ...
                    devkit, 'roi', mlfourd.ImagingContext2(roi));
                raichle = raichle.solve();
                toc

                % insert Raichle solutions on roibin(idx) into fs
                fscache = raichle.ks();
                fscache(raichle.LENK+1) = raichle.Dt;
                for ik = 1:raichle.LENK+1
                    rate = fs.img(:,:,:,ik);
                    rate(roibin) = fscache(ik);
                    fs.img(:,:,:,ik) = rate;
                end

                % Dx
                if any(idx == ipr.indicesToCheck)                        
                    h = raichle.plot();
                    title(sprintf('AerobicGlycolysisKit.buildFsByWmparc1:  idx == %i\n%s', idx, datestr(sesd.datetime)))
                    try
                        dtTag = lower(sesd.doseAdminDatetimeTag);
                        savefig(h, ...
                            fullfile(workdir, ...
                            sprintf('AerobicGlycolysisKit_buildFsByWmparc1_idx%i_%s.fig', idx, dtTag)))
                        figs = get(0, 'children');
                        saveas(figs(1), ...
                            fullfile(workdir, ...
                            sprintf('AerobicGlycolysisKit_buildFsByWmparc1_idx%i_%s.png', idx, dtTag)))
                        close(figs(1))
                    catch ME
                        handwarning(ME)
                    end
                end                    
            end                
            fs = mlfourd.ImagingContext2(fs);
            popd(pwd0)
        end
        function         buildCMRglc(this)
        end
        function         buildCMRO2(this)
        end 
        function kss   = buildKs(this, varargin)
            kss = this.buildKsByWmparc1(varargin{:});
        end
        function kss   = buildKsByWbrain(this, varargin)
            %% BUILDKSBYWBRAIN
            %  @param filesExpr
            %  @param foldersExpr in {'subjects' 'subjects/sub-S12345' 'subjects/sub-S12345/ses-E12345'}
            %  @return kss as mlfourd.ImagingContext2 or cell array, without saving to filesystems.
            
            len_ks = 5;
            
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
                sesd1.region = 'wbrain';
                pwd0 = pushd(sesd1.tracerResolvedOpSubject('typ', 'path'));                
                devkit = mlpet.ScannerKit.createFromSession(sesd1);                
                cbv = sesd1.cbvOnAtlas('typ', 'mlfourd.ImagingContext2', 'dateonly', true);
                cbv = cbv.fourdfp;
                wmparc1 = sesd1.wmparc1OnAtlas('typ', 'mlfourd.ImagingContext2');
                wmparc1 = wmparc1.fourdfp;
                ks = copy(wmparc1);
                ks.fileprefix = sesd1.ksOnAtlas('typ', 'fp', 'tags', [this.blurTag '_wbrain']);
                ks.img = zeros([size(wmparc1) len_ks]);   
                    
                % for parcs, build roibin as logical, roi as single                    
                tic
                roi = copy(wmparc1);
                roibin = wmparc1.img > 1;
                roi.img = single(roibin);  
                roi.fileprefix = sprintf('%s_indexgt1', roi.fileprefix);
                if 0 == dipsum(roi.img)
                    return
                end

                % solve Huang
                huang = mlglucose.NumericHuang1980.createFromDeviceKit( ...
                    devkit, 'cbv', mean(cbv.img(roibin)), 'roi', mlfourd.ImagingContext2(roi));
                huang = huang.solve();
                toc

                % insert Huang solutions on roibin(idx) into ks
                kscache = huang.ks();
                kscache(len_ks) = huang.Dt;
                for ik = 1:len_ks
                    rate = ks.img(:,:,:,ik);
                    rate(roibin) = kscache(ik);
                    ks.img(:,:,:,ik) = rate;
                end                
                ks = mlfourd.ImagingContext2(ks);
                kss = [kss ks]; %#ok<AGROW>
                popd(pwd0)
            end
        end
        function kss   = buildKsByWmparc1(this, varargin)
            %% BUILDKSBYWMPARC1
            %  @param filesExpr
            %  @param foldersExpr in {'subjects' 'subjects/sub-S12345' 'subjects/sub-S12345/ses-E12345'}
            %  @return kss as mlfourd.ImagingContext2 or cell array, without saving to filesystems.
            
            len_ks = 5;
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
                sesd1.region = 'wmparc1';
                pwd0 = pushd(sesd1.tracerResolvedOpSubject('typ', 'path'));                
                devkit = mlpet.ScannerKit.createFromSession(sesd1);                
                cbv = sesd1.cbvOnAtlas('typ', 'mlfourd.ImagingContext2', 'dateonly', true);
                cbv = cbv.fourdfp;
                wmparc1 = sesd1.wmparc1OnAtlas('typ', 'mlfourd.ImagingContext2');
                wmparc1 = wmparc1.fourdfp;
                ks = copy(wmparc1);
                ks.fileprefix = sesd1.ksOnAtlas('typ', 'fp', 'tags', [this.blurTag '_wmparc1']);
                ks.img = zeros([size(wmparc1) len_ks]);   

                for idx = indices % parcs
                    
                    % for parcs, build roibin as logical, roi as single                    
                    fprintf('starting mlpet.AerobicGlycolysisKit.buildKsByWmparc1.idx -> %i\n', idx)
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
                    kscache = huang.ks();
                    kscache(len_ks) = huang.Dt;
                    for ik = 1:len_ks
                        rate = ks.img(:,:,:,ik);
                        rate(roibin) = kscache(ik);
                        ks.img(:,:,:,ik) = rate;
                    end
                end                
                ks = mlfourd.ImagingContext2(ks);
                kss = [kss ks]; %#ok<AGROW>
                popd(pwd0)
            end
        end
        function         buildOef(this)
        end
        function         buildOgi(this)
        end
        function [roiset,ifc] = buildRoiset(this, rexp, varargin)
            %% e.g., this.buildRoiset('brain', 'cpuIndex', 1)
            
            [roiset,ifc] = this.roisExpr2roiSet(rexp, varargin{:});
        end
        function N     = estimateNumNodes(this, sesinfo, rexp)
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
        function sess  = filesExpr2sessions(~, varargin)
            sess = [];
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
        function ic    = metricOnAtlasTagged(this, varargin)
            sesd = this.sessionData;
            fqfp = sesd.([sesd.metric 'OnAtlas'])('typ', 'fqfp', 'tags', ['_b43' this.regionTag '_b43']);
            
            % 4dfp exists
            if isfile([fqfp '.4dfp.hdr'])
                ic = mlfourd.ImagingContext2([fqfp '.4dfp.hdr']);
                return
            end
            
            % Luckett-mat exists
            ifc = mlfourd.ImagingFormatContext(this.sessionData.hoOnAtlas);
            ifc.fileprefix = mybasename(fqfp);
            if isfile([fqfp '.mat'])
                fs = load([fqfp '.mat'], 'img');
                ifc.img = reshape(single(fs.img), [128 128 75 3]);
                ic = mlfourd.ImagingContext2(ifc);
                ic.save()
                return
            end
            
            error('mlraichle:RuntimeError', 'AerobicGlycolysis.metricOnAtlasTagged')
        end
        function Ks    = k1_to_K1(~, ks, cbv)
            %% multiplies k1 by dimensionless v1 without blurring.
            %  @param ks is 1/s.
            %  @param cbv is mL/hg.
            %  @return Ks is 1/s, with Ks(1) multiplied by dimensionless v1.
            
            cbv = mlfourd.ImagingContext2(cbv);
            ks = mlfourd.ImagingContext2(ks);
            Ks = copy(ks.fourdfp);
            Ks.img(:,:,:,1) = 0.0105 * cbv.fourdfp.img .* ks.fourdfp.img(:,:,:,1);
            Ks.fileprefix = strrep(ks.fileprefix, 'ks', 'Ks');
            Ks = mlfourd.ImagingContext2(Ks);
        end
        function h     = loadImagingHuang(this, varargin)
            %%
            %  @return mlglucose.ImagingHuang1980  
            
            this.devkit_ = mlpet.ScannerKit.createFromSession(this.sessionData);
            cbv = mlfourd.ImagingContext2(this.sessionData.cbvOnAtlas('dateonly', true));
            mask = this.maskOnAtlasTagged();
            ks = this.metricOnAtlasTagged();
            h = mlglucose.ImagingHuang1980.createFromDeviceKit(this.devkit_, 'cbv', cbv, 'roi', mask);
            h.ks = ks;
        end
        function r     = loadImagingRaichle(this, varargin)
            %%
            %  @return mloxygen.ImagingRaichle1983
            
            this.devkit_ = mlpet.ScannerKit.createFromSession(this.sessionData);
            mask = this.maskOnAtlasTagged();
            met = this.metricOnAtlasTagged();
            r = mlglucose.ImagingRaichle1983.createFromDeviceKit(this.devkit_, 'roi', mask);
            r.metric = met;
        end
        function h     = loadNumericHuang(this, roi, varargin)
            %%
            %  @param required roi is understood by mlfourd.ImagingContext2
            %  @return mlglucose.NumericHuang1980
            
            roi = mlfourd.ImagingContext2(roi);
            roi = roi.binarized();
            roibin = logical(roi.fourdfp.img);
            this.devkit_ = mlpet.ScannerKit.createFromSession(this.sessionData);
            cbv = mlfourd.ImagingContext2(this.sessionData.cbvOnAtlas('dateonly', true));
            mean_cbv = cbv.fourdfp.img(roibin);            
            h = mlglucose.NumericHuang1980.createFromDeviceKit(this.devkit_, 'cbv', mean_cbv, 'roi', roi);
        end
        function ic    = maskOnAtlasTagged(this, varargin)
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
    
    methods (Access = protected)
        function this = AerobicGlycolysisKit(varargin)
            this = this@mlpet.TracerKinetics(varargin{:});
        end
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
end

