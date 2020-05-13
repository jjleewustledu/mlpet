classdef AerobicGlycolysisKit < handle & mlpet.IAerobicGlycolysisKit
	%% AEROBICGLYCOLYSISKIT  

	%  $Revision$
 	%  was created 01-Apr-2020 11:09:38 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.7.0.1319299 (R2019b) Update 5 for MACI64.  Copyright 2020 John Joowon Lee.
 	
	properties (Dependent)
        sessionData
 	end

	methods (Static)
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
        function jitOnT1001(fexp)
            %  @param fexp is char, e.g., 'subjects/sub-S58163/resampling_restricted/ocdt20190523122016_on_T1001.4dfp.hdr'
            
            if ~lstrfind(fexp, '_on_T1001')
                return
            end
            for globFolder = globT(fullfile(getenv('SINGULARITY_HOME'), myfileparts(fexp)))
                pwd0 = pushd(globFolder{1});
                ss = strsplit(basename(fexp), '_on_T1001.4dfp');
                fexpNoT1 = [ss{1} '.4dfp.hdr'];            
                for globNoT1 = globT(fexpNoT1)
                    if regexp(globNoT1{1}, '[a-z]{4,5}\d{8,14}\.4dfp\.hdr')
                        fpNoT1 = myfileprefix(globNoT1{1});
                        fnOnT1 = [mybasename(fpNoT1) '_on_T1001.4dfp.hdr'];
                        if ~isfile(fnOnT1)                    
                            fv = mlfourdfp.FourdfpVisitor();
                            t4 = [fpNoT1 '_to_T1001_t4'];
                            fv.t4img_4dfp(t4, fpNoT1, 'options', '-OT1001')
                        end
                    end
                end
                popd(pwd0) 
            end
        end
    end 
    
    methods
        
        %% GET
        
        function g = get.sessionData(this)
            g = this.sessionData_;
        end
        
        %%
        
        function buildAgi(this)
        end
        function buildCbv(this, varargin)
            %% BUILDCRV
            %  @param foldersExpr in {'subjects' 'subjects/sub-S12345' 'subjects/sub-S12345/ses-E12345'}
            %  @param roisExpr in {'brain' 'Desikan' 'Destrieux' 'wm'}; default := 'brain'
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'filesExpr', '', @ischar)
            addParameter(ip, 'foldersExpr', '', @ischar)
            addParameter(ip, 'roisExpr', 'brain', @ischar)
            addParameter(ip, 'averageVoxels', true, @islogical)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            if ~isempty(ipr.filesExpr)                
                for sesd = this.filesExpr2sessions(ipr.filesExpr)
                    devkit = mlpet.ScannerKit.createFromSession(sesd{1});
                    devkit.stageResamplingRestricted()
                    martin = mloxygen.Martin1987.createFromDeviceKit(devkit);
                    roiset = this.roisExpr2roiSet(ipr.roisExpr);
                    for roi = roiset
                        cbv = martin.buildCbv('roi', roi{1}, varargin{:});
                        martin.buildQC('roi', roi{1}, 'cbv', cbv, varargin{:});
                        cbv.save
                    end                    
                end                
            end
            
            if ~isempty(ipr.foldersExpr)
                for sesd = this.foldersExpr2sessions(ipr.foldersExpr)
                    devkit = mlpet.ScannerKit.createFromSession(sesd{1});
                    devkit.stageResamplingRestricted()
                    martin = mloxygen.Martin1987.createFromDeviceKit(devkit);
                    roiset = this.roisExpr2roiSet(ipr.roisExpr);
                    for roi = roiset
                        cbv = martin.buildCbv('roi', roi{1}, varargin{:});
                        martin.buildQC('roi', roi{1}, 'cbv', cbv, varargin{:});
                        cbv.save
                    end
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
            addParameter(ip, 'roisExpr', 'wmparc', @ischar)
            addParameter(ip, 'cpuIndex', [], @(x) isnumeric(x) && ~isempty(x))
            addParameter(ip, 'averageVoxels', false, @islogical)
            parse(ip, varargin{:})
            ipr = ip.Results;
            disp(ipr)
            
            for sesd = this.filesExpr2sessions(ipr.filesExpr)
                pwd0 = pushd(sesd{1}.tracerResolvedOpSubject('typ', 'path'));
                disp(sesd{1})
                devkit = mlpet.ScannerKit.createFromSession(sesd{1});
                disp(devkit)
                devkit.stageResamplingRestricted()
                roiset = this.roisExpr2roiSet(ipr.roisExpr, 'cpuIndex', ipr.cpuIndex);
                for roi = roiset
                    cbvfn = this.cbvFilename();
                    roi_ = roi{1};
                    fprintf('mlpet.AerobicGlycolysisKit.buildKs():  cbvg_->%s\n', cbvfn)
                    fprintf('mlpet.AerobicGlycolysisKit.buildKs():  roi.fileprefix->%s\n', roi_.fileprefix)
                    huang = mlglucose.ImagingHuang1980.createFromDeviceKit(devkit, 'cbv', cbvfn, 'roi', roi_);
                    huang = huang.solve();
                    save(huang.ks)
                end
                popd(pwd0)
            end
        end
        function buildOef(this)
        end
        function buildOgi(this)
        end
        function roiset = buildRoiset(this, rexp, varargin)
            roiset = this.roisExpr2roiSet(rexp, varargin{:});
        end
        function fn = cbvFilename(this)
            re = regexp(this.sessionData.scanFolder, '[A-Z]+_DT(?<dt>\d{8})\d{6}.000000\-Converted\-AC', 'names');
            fn = sprintf('cbvdt%s000000_on_T1001_decayUncorrect0.4dfp.hdr', re.dt);
            assert(isfile(fn))
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
        function roiset = roisExpr2roiSet(this, rexp, varargin)
            sesd = this.sessionData;
            rois = mlpet.Rois.createFromSession(sesd);
            switch rexp
                case {'brain' 'brainmask' 'wholebrain' 'wb'}
                    roiset = rois.constructBrainSet();
                case {'Desikan' 'aparc+aseg'}
                    roiset = rois.constructDesikanSet(varargin{:});
                case {'Destrieux' 'aparc.a2009s+aseg'}
                    roiset = rois.constructDestrieuxSet(varargin{:});
                case {'wm' 'wmparc'}
                    roiset = rois.constructWmSet(varargin{:});
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

