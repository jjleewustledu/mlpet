classdef (Abstract) AbstractCalibration < handle & matlab.mixin.Heterogeneous & matlab.mixin.Copyable
	%% ABSTRACTCALIBRATION  

	%  $Revision$
 	%  was created 23-Feb-2020 21:44:02 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.7.0.1296695 (R2019b) Update 4 for MACI64.  Copyright 2020 John Joowon Lee.
 	
	properties (Abstract)
        calibrationAvailable % logical scalar
        invEfficiency
 	end

	methods (Abstract, Static)
        buildCalibration()
        createFromSession()
        invEfficiencyf()
    end 
    
	properties (Constant)
        WATER_DENSITY = 0.9982 % pure water at 20 C := 0.9982 mL/g; tap := 0.99823
        BLOOD_DENSITY = 1.06 % https://hypertextbook.com/facts/2004/MichaelShmukler.shtml; human whole blood 37 C
        BRAIN_DENSITY = 1.05 % Torack et al., 1976
        PLASMA_DENSITY = 1.03
    end
    
    properties (Dependent)
        branchingRatio
        radionuclide
        radMeasurements
    end
    
    methods (Static)
        function [prj,ses] = findProximalExperiment(sesd0, ordinal)
            %% FINDPROXIMALEXPERIMENT finds alternative, temporally proximal session information that is separated by the
            %  requested ordinality.
            %  @param sesd0 is an mlpipeline.ISessionData.
            %  @param ordinal is numeric, specifying the separation.
            %  @return prj is a project name (char).
            %  @return ses is a session name (char).
            
            dt0 = datetime(sesd0);
            J = sesd0.studyData.subjectsJson;
            dts = [];
            prjs = {};
            sess = {};
            
            % traverse, e.g., J.HYGLY50
            for sid = asrow(fields(J))
                sid1 = sid{1};
                prj1 = J.(sid1).project;
            
                % traverse, e.g., J.HYGLY50.dates
                for experiment = asrow(fields(J.(sid1).dates))
                    experiment1 = experiment{1};
                    [~,remain] = strtok(experiment1, 'E');
                    ses1 = ['ses-' remain];                    
                    dt1 = datetime(J.(sid1).dates.(experiment1), 'InputFormat', 'yyyyMMdd', 'TimeZone', dt0.TimeZone);
                    dts = [dts; dt1]; %#ok<AGROW>
                    prjs = [prjs; prj1]; %#ok<AGROW>
                    sess = [sess; ses1]; %#ok<AGROW>
                end

                % traverse. e.g., J.HYGLY50.aliases.NP995_25
                if isfield(J.(sid1), 'aliases')
                    for alias = asrow(fields(J.(sid1).aliases))
                        alias1 = alias{1};
                        prj1 = J.(sid1).aliases.(alias1).project;

                        % traverse, e.g., J.HYGLY50.aliases.NP995_25.dates
                        for aliasExperiment = asrow(fields(J.(sid1).aliases.(alias1).dates))
                            aliasExperiment1 = aliasExperiment{1};
                            [~,remain] = strtok(aliasExperiment1, 'E');
                            ses1 = ['ses-' remain];
                            dt1 = datetime(J.(sid1).aliases.(alias1).dates.(aliasExperiment1), 'InputFormat', 'yyyyMMdd', 'TimeZone', dt0.TimeZone);
                            dts = [dts; dt1]; %#ok<AGROW>
                            prjs = [prjs; prj1]; %#ok<AGROW>
                            sess = [sess; ses1]; %#ok<AGROW>
                        end
                    end
                end
            end
            
            % sort and select ordinal separated
            dtsep = abs(dts - dt0);
            T = table(dtsep, prjs, sess);
            T = sortrows(T, 1);
            prj = T{1+ordinal, 2}; prj = prj{1};
            ses = T{1+ordinal, 3}; ses = ses{1};
        end
        function sesd = findProximalSession(sesd0, varargin)
            %% FINDPROXIMALSESSION finds alternative, temporally proximal session data that is separated by the
            %  requested ordinality.  Ordinality increases recursively until valid session data is found.
            %  @param required sesd0 is an mlpipeline.ISessionData.
            %  @param optional ordinal is numeric, specifying the separation.  Default := 1.
            %  @return sesd is an alternative mlpipeline.ISessionData that is temporally proximal.
            
            ip = inputParser;
            addRequired(ip, 'sesd0', @(x) isa(x, 'mlpipeline.ISessionData'))
            addOptional(ip, 'ordinal', 1, @isnumeric)
            parse(ip, sesd0, varargin{:})
            ipr = ip.Results;
            
            home = getenv('SINGULARITY_HOME');
            [prj,ses] = mlpet.AbstractCalibration.findProximalExperiment(sesd0, ipr.ordinal);
            tra = globFolders(fullfile(home, prj, ses, 'FDG_DT*-Converted-AC'));
            try
                sesd = sesd0.create(fullfile(prj, ses, basename(tra{end})));
            catch ME
                handwarning(ME)
                warning('mlpet:RuntimeWarning', ...
                    'AbstractCalibration.findProximalSession:  recursing with ordinal->%g', ipr.ordinal+1)
                sesd = mlpet.AbstractCalibration.findProximalSession(sesd0, ipr.ordinal+1);
            end
        end
        function arr = shiftWorldLines(arr, shift, halflife)
            %% SHIFTWORLDLINES 
            %  @param arr is numeric, undergoing radiodecay
            %  @param shift is numeric, seconds of shift; 
            %         shift < 0 shifts backward in time; shift > 0 shifts forward in time
            %  @param halflife of radionuclide in seconds
            
            assert(isnumeric(arr)) % activities
            assert(isnumeric(shift)) % time-shift
            assert(isscalar(halflife)) 
            arr = asrow(arr);
            shift = asrow(shift);            
            
            arr = arr .* 2.^(-shift/halflife);
        end
    end
        
    methods 
        
        %% GET
        
        function g = get.branchingRatio(this)
            g = this.radionuclide.branchingRatio;
        end
        function g = get.radionuclide(this)
            g = this.radionuclide_;
        end
        function g = get.radMeasurements(this)
            g = this.radMeasurements_;
        end
        
        %% 
        
        function [trainedModel, validationRMSE] = trainRegressionModel(~, trainingData)
            assert(istable(trainingData));
            trainedModel = [];
            validationRMSE = [];
        end
        
    end
    
    %% PROTECTED
    
    properties (Access = protected)
        radionuclide_
        radMeasurements_
    end
    
    methods (Access = protected)
 		function this = AbstractCalibration(varargin)
 			%% ABSTRACTCALIBRATION
            %  @param required radMeas is mlpet.RadMeasurements.
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'radMeas', [], @(x) isa(x, 'mlpet.RadMeasurements') || isempty(x));
            addParameter(ip, 'radMeasurements', [], @(x) isa(x, 'mlpet.RadMeasurements') || isempty(x));
            addParameter(ip, 'isotope', '18F', @(x) ismember(x, mlpet.Radionuclides.SUPPORTED_ISOTOPES));
            parse(ip, varargin{:});   
            ipr = ip.Results;
            
            if ~isempty(ipr.radMeas)
                this.radMeasurements_ = ipr.radMeas;
            end
            if ~isempty(ipr.radMeasurements)
                this.radMeasurements_ = ipr.radMeasurements;
            end 
            this.radionuclide_ = mlpet.Radionuclides(ipr.isotope);
        end
        
        function that = copyElement(this)
            %%  See also web(fullfile(docroot, 'matlab/ref/matlab.mixin.copyable-class.html'))
            
            that = copyElement@matlab.mixin.Copyable(this);
        end
        function tf = isotopeSelection(this)
            rm = this.radMeasurements;
            tf = logical(cell2mat(strfind(rm.wellCounter.TRACER, this.radionuclide.isotope)));
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

