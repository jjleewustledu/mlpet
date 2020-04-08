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
    end 
    
    methods
        
        %% GET
        
        function g = get.sessionData(this)
            g = this.sessionData_;
        end
        
        %%
        
        function buildAGI(this)
        end
        function buildCBV(this, varargin)
            %% BUILDCRV
            %  @param foldersExpr in {'subjects' 'subjects/sub-S12345' 'subjects/sub-S12345/ses-E12345'}
            
            ip = inputParser;
            addRequired(ip, 'foldersExpr', @ischar)
            addRequired(ip, 'roisExpr', @ischar)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            for sesd = this.foldersExpr2sessions(ipr.foldersExpr)
                devkit = mlpet.ScannerKit.createFromSession(sesd);
                martin = mloxygen.Martin1987.createFromDeviceKit(devkit);
                roiset = this.roisExpr2roiSet(ipr.roisExpr);
                for roi = roiset
                    martin.buildQC('roi', roi{1});
                    martin.buildCBV('roi', roi{1});
                end
            end
        end
        function buildCBF(this)
        end
        function buildCMRglc(this)
        end
        function buildCMRO2(this)
        end
        function buildKs(this)
        end
        function buildOEF(this)
        end
        function buildOGI(this)
        end
        function sesds = foldersExp2sessions(this, fexp)
            assert(ischar(fexp))
            sesds = {};
            ss = strsplit(fexp, filesep);
            home = getenv('SINGULARITY_HOME');
            switch length(ss)
                case 1
                    for subpth = globFoldersT(fullfile(home, fexp, 'sub-S*'))
                        for sespth = globFoldersT(fullfile(subpth{1}, 'ses-E*'))
                            for trapth = globFoldersT(fullfile(sespth{1}, '*_DT*.*-Converted-AC'))
                                sesds = [sesds this.sessionData.create(trapth{1})]; %#ok<AGROW>
                            end
                        end
                    end
                case 2
                    for sespth = globFoldersT(fullfile(home, fexp, 'ses-E*'))
                        for trapth = globFoldersT(fullfile(sespth{1}, '*_DT*.*-Converted-AC'))
                            sesds = [sesds this.sessionData.create(trapth{1})]; %#ok<AGROW>
                        end
                    end
                case 3
                    for trapth = globFoldersT(fullfile(home, fexp, '*_DT*.*-Converted-AC'))
                        sesds = [sesds this.sessionData.create(trapth{1})]; %#ok<AGROW>
                    end
                otherwise
                    error('mlpet:ValueError', ...
                        'AerobicGlycolysisKit.foldersExp2session(%) is not supported', fexp)
            end
        end
        function roiset = roisExpr2roiSet(this, rexp)
            sesd = this.sessionData;
            switch rexp
                case {'brain' 'brainmask' 'wholebrain' 'wb'}
                case {'Desikan' 'aparc+aseg'}
                case {'Destrieux' 'aparc.a2009s+aseg'}
                case {'wm' 'wmparc'}
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

