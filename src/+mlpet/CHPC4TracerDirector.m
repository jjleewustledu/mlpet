classdef CHPC4TracerDirector < mldistcomp.CHPC
	%% CHPC4FDGDIRECTOR  

	%  $Revision$
 	%  was created 13-Mar-2017 18:04:08 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.  Copyright 2017 John Joowon Lee.
 	
    
    methods
        function this = pushData(this)
            import mlraichle.*;
            csd = this.chpcSessionData;
            sd  = this.sessionData;
            
            this.sshMkdir(                           csd.freesurferLocation);
            this.rsync([sd.freesurferLocation '/'], [csd.freesurferLocation '/']);
            
            this.sshMkdir(                              csd.T1('typ','path'));
            this.rsync( sd.brainmask('typ','mgz'),      csd.T1('typ','path'));
            this.rsync( sd.aparcAseg('typ','mgz'),      csd.T1('typ','path'));
            this.rsync([sd.T1('typ','fqfp') '.4dfp.*'], csd.T1('typ','path'));
            
            this.sshMkdir(                                         csd.sessionPath);
            this.rsync(fullfile(sd.sessionPath, 'AC_CT_*.4dfp.*'), csd.sessionPath);
            this.rsync(fullfile(sd.sessionPath, 'ct*.4dfp.*'),     csd.sessionPath);
            
            this.sshMkdir(                                   csd.vLocation);
            this.rsync(fullfile(sd.vLocation, 'ct*'),        csd.vLocation);
            this.rsync(fullfile(sd.vLocation, 'T1001*'),     csd.vLocation);
            this.rsync(fullfile(sd.vLocation, 'umapSynth*'), csd.vLocation);
            this.rsync(fullfile(sd.vLocation, 't2*'),        csd.vLocation, 'options', '-rav --no-l --copy-links -e ssh');
            this.rsync(fullfile(sd.vLocation, 'mpr*'),       csd.vLocation, 'options', '-rav --no-l --copy-links -e ssh');
            
            this.sshMkdir(                                   csd.tracerLocation);
            this.rsync([sd.tracerLocation '/'],             [csd.tracerLocation '/']);
            this.sshMkdir(                                   csd.tracerListmodeLocation);
            if (isdir(sd.tracerListmodeLocation))
                this.rsync([sd.tracerListmodeLocation '/'], [csd.tracerListmodeLocation '/']);
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
        function this = pullData(this)
            import mlraichle.*;
            csd = this.chpcSessionData;
            sd  = this.sessionData;
            
            try
                this.rsync([csd.vLocation '/'], [sd.vLocation '/'], 'chpcIsSource', true);
            catch ME
                handerror(ME);
            end
        end
        function        cleanSinograms(~)
            pwd0 = pushd(mlraichle.RaichleRegistry.instance.subjectsDir);
            fprintf('mlraichle.HyperglycemiaDirector.cleanFilesystem:  is cleaning %s\n', pwd);
            import mlsystem.*;
            
            dtsess = DirTools({'HYGLY*' 'NP995*' 'TW0*' 'DT*'});
            for idtsess = 1:length(dtsess.fqdns)
                pwds = pushd(dtsess.fqdns{idtsess});
                fprintf('mlraichle.HyperglycemiaDirector.cleanFilesystem:  is cleaning %s\n', pwd); 
                
                dtv = DirTool('V*');
                for idtv = 1:length(dtv.fqdns)
                    pwdv = pushd(dtv.fqdns{idtv});
                    fprintf('mlraichle.HyperglycemiaDirector.cleanFilesystem:  is cleaning %s\n', pwd); 

                    dtconv = DirTool('*-Converted*');
                    for idtconv = 1:length(dtconv.fqdns)
                        pwdc = pushd(dtconv.fqdns{idtconv});
                        fprintf('mlraichle.HyperglycemiaDirector.cleanFilesystem:  is cleaning %s\n', pwd); 

                        dt00 = DirTool('*-00');
                        for idt00 = 1:length(dt00.fqdns)
                            pwd00 = pushd(dt00.fqdns{idt00});
                            fprintf('mlraichle.HyperglycemiaDirector.cleanFilesystem:  is cleaning %s\n', pwd);   
                            deleteExisting('*-00-sino*');  
                            popd(pwd00);
                        end
                        popd(pwdc);

                    end
                    popd(pwdv);
                end
                popd(pwds);
            end
            popd(pwd0);
        end
        function        cleanTracer(this)
            csd = this.chpcSessionData;
            this.sshRm(fullfile(csd.vLocation, [upper(csd.tracer) '_V*']));
        end
        
        function this = CHPC4TracerDirector(varargin)
            this = this@mldistcomp.CHPC(varargin{:});
        end
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

