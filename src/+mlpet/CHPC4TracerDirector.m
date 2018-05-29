classdef CHPC4TracerDirector < mldistcomp.CHPC
	%% CHPC4FDGDIRECTOR  

	%  $Revision$
 	%  was created 13-Mar-2017 18:04:08 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.  Copyright 2017 John Joowon Lee.
 	
    
    methods
        function this = pushData(this, varargin)
            ip = inputParser;   
            ip.KeepUnmatched = true;
            addParameter(ip, 'includeListmode', true, @islogical);
            parse(ip, varargin{:});
            csd = this.chpcSessionData;
            sd  = this.sessionData;
            
            try
                this.sshMkdir(                           csd.freesurferLocation);
                this.rsync([sd.freesurferLocation '/'], [csd.freesurferLocation '/'], varargin{:});

                this.sshMkdir(                              csd.T1('typ','path'));
                this.rsync( sd.brainmask('typ','mgz'),      csd.T1('typ','path'), varargin{:});
                this.rsync( sd.aparcAseg('typ','mgz'),      csd.T1('typ','path'), varargin{:});
                this.rsync([sd.T1('typ','fqfp') '.4dfp.*'], csd.T1('typ','path'), varargin{:});

                this.sshMkdir(                                         csd.sessionPath);
                this.rsync(fullfile(sd.sessionPath, 'AC_CT_*.4dfp.*'), csd.sessionPath, varargin{:});
                this.rsync(fullfile(sd.sessionPath, 'ct*.4dfp.*'),     csd.sessionPath, varargin{:});

                this.sshMkdir(                                   csd.vLocation);
                this.rsync(fullfile(sd.vLocation, 'ct*'),        csd.vLocation, varargin{:});
                this.rsync(fullfile(sd.vLocation, 'T1001*'),     csd.vLocation, varargin{:});
                this.rsync(fullfile(sd.vLocation, 'umapSynth*'), csd.vLocation, varargin{:});

                this.sshMkdir(                           csd.tracerLocation);
                if (isdir(sd.tracerLocation))
                    this.rsync([sd.tracerLocation '/'], [csd.tracerLocation '/'], varargin{:});
                end

                if (ip.Results.includeListmode)
                    this.sshMkdir(                                   csd.tracerListmodeLocation);
                    if (isdir(sd.tracerListmodeLocation))
                        this.rsync([sd.tracerListmodeLocation '/'], [csd.tracerListmodeLocation '/'], varargin{:});
                    end
                    sd.frame  = 0;
                    csd.frame = 0;
                    while (isdir(sd.tracerListmodeLocation))
                        this.rsync( ...
                            [fileparts(sd.tracerListmodeLocation) '/'], [fileparts(csd.tracerListmodeLocation) '/'], ...
                            varargin{:});
                        this.rsync( ...
                            [sd.tracerListmodeLocation '/'], [csd.tracerListmodeLocation '/'], ...
                            varargin{:});
                        sd.frame  = sd.frame + 1;
                        csd.frame = csd.frame + 1;
                    end
                end
            catch ME
                dispwarning(ME);
            end
        end
        function this = pushMinimalData(this)
            if (this.sessionData.attenuationCorrected)
                this = this.pushMinimalForAC;
            else
                this = this.pushMinimalForNAC;
            end
        end
        function this = pullData(this, varargin)
            csd = this.chpcSessionData;
            sd  = this.sessionData;            
            
            try
                this.rsync([csd.vLocation '/'], [sd.vLocation '/'], 'chpcIsSource', true, varargin{:});
            catch ME
                handerror(ME);
            end
        end
        function        cleanEpochs(this)
            csd = this.chpcSessionData;
            this.sshRm(fullfile(csd.tracerLocation, 'E*'));
        end
        function        cleanTracer(this)
            csd = this.chpcSessionData;
            this.sshRm(fullfile(csd.vLocation, [upper(csd.tracer) '_V*']));
        end
        
        function this = CHPC4TracerDirector(varargin)
            this = this@mldistcomp.CHPC(varargin{:});
        end
    end
    
    %% PRIVATE
    
    methods (Access = private)
        function this = pushMinimalForAC(this)
            import mlraichle.*;
            csd = this.chpcSessionData;
            sd  = this.sessionData;
            
            try
                this.sshMkdir(                           csd.freesurferLocation);
                this.rsync([sd.freesurferLocation '/'], [csd.freesurferLocation '/']);
            catch ME
                dispwarning(ME);
            end
            
%             sdNac = sd; sdNac.attenuationCorrected = false;
%             csdNac = csd; csdNac.attenuationCorrected = false;
%             this.sshMkdir(                                      csdNac.tracerListmodeLocation);            
%             if (isdir(sdNac.tracerListmodeLocation))
%                 this.rsync([sdNac.tracerListmodeLocation '/'], [csdNac.tracerListmodeLocation '/']);
%             end
%             this.sshMkdir(                                      csdNac.tracerLocation);            
%             if (isdir(sdNac.tracerLocation))
%                 this.rsync([sdNac.tracerLocation         '/'], [csdNac.tracerLocation '/']);
%             end
            this.sshMkdir(                                      csd.tracerListmodeLocation); 
            if (isdir(sd.tracerListmodeLocation))
                this.rsync([sd.tracerListmodeLocation    '/'], [csd.tracerListmodeLocation '/']);
            end
            sd.frame  = 0;
            csd.frame = 0;
            while (isdir(sd.tracerListmodeLocation))
                this.rsync([fileparts(sd.tracerListmodeLocation) '/'], [fileparts(csd.tracerListmodeLocation) '/']);
                this.rsync([sd.tracerListmodeLocation '/'], [csd.tracerListmodeLocation '/']);
                sd.frame  = sd.frame + 1;
                csd.frame = csd.frame + 1;
            end
        end
        function this = pushMinimalForNAC(this)
            import mlraichle.*;
            csd = this.chpcSessionData;
            sd  = this.sessionData;
            
            try
                this.sshMkdir(                           csd.freesurferLocation);
                this.rsync([sd.freesurferLocation '/'], [csd.freesurferLocation '/']);
            catch ME
                dispwarning(ME);
            end
            
            this.sshMkdir(                                         csd.sessionPath);
            this.rsync(fullfile(sd.sessionPath, 'AC_CT_*.4dfp.*'), csd.sessionPath);
            this.rsync(fullfile(sd.sessionPath, 'ct*.4dfp.*'),     csd.sessionPath);
            
            this.sshMkdir(                                   csd.tracerListmodeLocation);
            if (isdir(sd.tracerListmodeLocation))
                this.rsync([sd.tracerListmodeLocation '/'], [csd.tracerListmodeLocation '/']);
            end
        end
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

