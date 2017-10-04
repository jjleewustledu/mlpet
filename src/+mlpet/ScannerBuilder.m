classdef ScannerBuilder < mlpipeline.AbstractDataBuilder
	%% SCANNERBUILDER  

	%  $Revision$
 	%  was created 01-Feb-2017 17:31:38
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.
 	
    
	methods 
		  
 		function this = ScannerBuilder(varargin)
 			%% SCANNERBUILDER
 			%  Usage:  this = ScannerBuilder()

            this = this@mlpipeline.AbstractDataBuilder(varargin{:});
            
            sessd = this.sessionData;
            if (isa(sessd.studyData, 'mlderdeyn.StudyDataSingleton'))
                this.scanner_ = mlpet.EcatExactHRPlus.loadSession(sessd, sessd.ho('typ', 'nii.gz'));
                return
            end
            if (isa(sessd.studyData, 'mlraichle.StudyData'))
                this.scanner_ = mlsiemens.BiographMMR();
                return
            end
        end
        
        function obs = buildPetObsMap(this, varargin)
            ip = inputParser;
            addParameter(ip, 'sessionData', this.sessionData, @(x) isa(x, 'mlpipeline.ISessionData'));
            parse(ip, varargin{:}); 
            this.sessionData_ = ip.Results.sessionData;
            
            obs = mlfourd.NIfTId.load(this.sessionData.ho('typ', 'nii.gz'));
        end
    end
    
    %% PRIVATE
    
    properties (Access = private)
        scanner_        
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

