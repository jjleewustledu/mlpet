classdef TracerSurferBuilder < mlpet.AbstractTracerBuilder
	%% TRACERSURFERBUILDER  
    %  @param this.sessionData makes sense.
    %  @param Freesurfer properly installed in getenv('FREESURFER_HOME').

	%  $Revision$
 	%  was created 02-Nov-2017 20:20:17 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.3.0.713579 (R2017b) for MACI64.  Copyright 2017 John Joowon Lee.
 	
	properties (Dependent)
 		legacySessionPath
 	end

	methods 
        
        %% GET
        
        function g = get.legacySessionPath(this)
            g = this.sessionData.freesurferLocation;
        end
        
        %%
        
        function this = findLegacySurfer001(this)
            %  @return ls001 in this.product as specified by mlpipeline.AbstractDataBuilder.packageProduct if found.
            %  @return this.product := [] otherwise.            
            
            ext = {'.mgz' '.nii.gz' '.nii'};
            for x = 1:length(ext)       
                ls001 = fullfile(this.legacySessionPath, 'mri', 'orig', ['001' ext{x}]);
                if (lexist(ls001, 'file'))
                    this = this.packageProduct(ls001);
                    return
                end
            end
            this = this.packageProduct([]);                
        end
        function this = linkLegacySurfer001(this)
            %  @param this.product previously found and nontrivial.
            %  @return previous this.product linked into this.sessionData.sessionPath; this.product := the new link.
            
            assert(lexist(this.product.fqfilename, 'file'));
            origp = fullfile(this.sessionData.sessionPath, 'mri', 'orig', '');
            if (~isdir(origp))
                mkdir(origp)
            end
            pwd0 = pushd(origp);
            mlbash(sprintf('ln -s %s', this.product.fqfilename));
            this = this.packageProduct(fullfile(orgp, this.product.filename));
            popd(pwd0);
        end
        function this = linkRawdataMPR(this)
            %  @param this.sessionData.sessionPath contains {'*mpr*' 't1*'} with suitable MP-RAGE.
            %  @return this.product := link to suitable MP-RAGE.
            %  @return this.product.view for inspecting MP-RAGE quality; must abort QC failures.
            %  @return this.product := [] if no MP-RAGE found.
            %  @throws mlfourdfp:fileNotFound, mfiles:unixException
            
            mpr001 = '';
            
            pwd0 = pushd(this.sessionData.sessionPath);            
            dtv = mlsystem.DirTool('V*');
            for v = 1:length(dtv.fqdns)
                
                pushd(dtv.fqdns{v});
                dtm = mlsystem.DirTools({'*mpr*' 't1*'});
                for m = 1:length(dtm.fqfns)
                    
                    [~,~,x] = myfileparts(dtm.fqfns{m});
                    switch (x)
                        case {'.mgz' '.nii.gz' '.nii'}
                            mpr001 = [dtm.fqfp{m} x];
                        case {'.4dfp.ifh' '.4dfp.hdr' '.4dfp.img' '.4dfp.img.rec'}
                            fv = mlfourdfp.FourdfpVisitor;
                            fv.nifti_4dfp_ng([dtm.fqfp{m} '.4dfp.ifh']);
                            mpr001 = [dtm.fqfp{m} '.nii.gz'];
                    end
                    if (~isempty(mpr001))
                        origp = fullfile(this.sessionData.sessionPath, 'mri', 'orig', '');
                        ensureDir(origp);
                        pushd(origp);                        
                        mlbash(sprintf('ln -s %s', mpr001));
                        this = this.packageProduct(fullfile(origp, basename(mpr001)));
                        this.product.view;
                        popd(pwd0);
                        return
                    end
                end
            end     
            this = this.pacakgeProduct([]);
            popd(pwd0);
        end
        function [s,r] = reconAllSurferObjects(this)
            %  @param this.product is valid.
            %  @return [status,result] for call to recon-all.
            %  @return results of recon-all.
            
            assert(~isempty(getenv('FREESURFER_HOME')));
            assert(~isempty(this.product), 'reconAllSurferObjects:  no valid MP-RAGE found');
            assert(lexist(this.product.fqfilename, 'file'));
            % mlbash(sprintf('source %s/SetUpFreeSurfer.sh', getenv('FREESURFER_HOME'))); 
            % % not persistent betweencalls to mlbash
            setenv('SUBJECTS_DIR', this.sessionData.subjectsDir);
            [s,r] = mlbash(sprintf('recon-all -i %s -s %s -all', this.product.fqfilename, this.sessionData.sessionFolder));
        end
        
        function partialVolumeCorrect(this)
            %  See also:  https://surfer.nmr.mgh.harvard.edu/fswiki/PetSurfer
        end
		  
 		function this = TracerSurferBuilder(varargin)
 			%% TRACERSURFERBUILDER
 			%  Usage:  this = TracerSurferBuilder()

 			this = this@mlpet.AbstractTracerBuilder(varargin{:});
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

