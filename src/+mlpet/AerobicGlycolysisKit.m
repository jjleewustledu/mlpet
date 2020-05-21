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
        function jitOn222(fexp)
            %  @param fexp is char, e.g., 'subjects/sub-S58163/resampling_restricted/ocdt20190523122016_222.4dfp.hdr'
            
            mlnipet.ResolvingSessionData.jitOn222(fexp);
        end      
        function jitOnT1001(fexp)
            %  @param fexp is char, e.g., 'subjects/sub-S58163/resampling_restricted/ocdt20190523122016_on_T1001.4dfp.hdr'
            
            mlnipet.ResolvingSessionData.jitOnT1001(fexp);
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
                    cbvfn = sesd{1}.cbvOnAtlas('typ', 'fn', 'dateonly', true);
                    fprintf('mlpet.AerobicGlycolysisKit.buildKs():  cbvfn->%s\n', cbvfn)
                    fprintf('mlpet.AerobicGlycolysisKit.buildKs():  roi{1}.fileprefix->%s\n', roi{1}.fileprefix)
                    huang = mlglucose.ImagingHuang1980.createFromDeviceKit(devkit, 'cbv', cbvfn, 'roi', roi{1});
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
        function [roiset,ifc] = buildRoiset(this, rexp, varargin)
            %% e.g., this.buildRoiset('brain', 'cpuIndex', 1)
            
            [roiset,ifc] = this.roisExpr2roiSet(rexp, varargin{:});
        end
        function estimateNumNodes(this, sesinfo, rexp)
            %  @param sesinfo is char.
            %  @param rexp in {'brain' 'brainmask' 'wmparc'}
            
            [~,ifc] = this.buildRoiset(rexp);
            registry = this.sessionData.registry;
            N = ceil(dipsum(ifc.img)/(registry.wallClockLimit/registry.voxelTime));
            
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

