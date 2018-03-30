classdef SessionData < mlpipeline.SessionData
	%% SESSIONDATA  

	%  $Revision$
 	%  was created 02-Apr-2016 19:52:11
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.0.0.341360 (R2016a) for MACI64.


	properties (Dependent)
        petTarget
    end
    
    methods %% GET/SET
        function g = get.petTarget(this)
            g = this.petTarget_;
        end
        function this = set.petTarget(this, s)
            assert(ischar(s));
            [~,this.petTarget_] = fileparts(lower(s));
        end
    end
    
	methods 		  
 		function this = SessionData(varargin)
 			%% SESSIONDATA
 			%  Usage:  this = SessionData()

 			this = this@mlpipeline.SessionData(varargin{:});
        end
        function this = fslmerge_t(this)
            pwd0 = pwd;
            cd(this.petPath);
            import mlsystem.*;
            frames = DirTool('*_frames');
            s = 0; r = '';
            for f = 1:frames.length
                cd(frames.fqdns{f});
                hdrs = DirTool('*.hdr');
                if (hdrs.length > 0)
                    fp = this.analyzeFileprefix(hdrs.fns{1});
                    if (~lexist(fullfile(frames.fqdns{f}, [fp '.nii.gz']), 'file') && ...
                        ~lexist(fullfile(this.petPath,    [fp '.nii.gz']), 'file'))
                        try
                            [s,r] = mlbash(sprintf('fslmerge -t %s %s_*.hdr', fp, fp));
                            [s,r] = mlbash(sprintf('mv -f %s.nii.gz  %s', fp, this.petPath));
                            [s,r] = mlbash(sprintf('mv -f %s.img.rec %s', fp, this.petPath));
                        catch ME
                            handwarning(ME);
                            fprintf('mlpet.SessionData.fslmerge_t:  s->%i, r->%s\n', s, r);
                        end
                    end
                end
                
            end
            cd(pwd0);
        end
        function fp = analyzeFileprefix(~, fn)
            [~,fp] = myfileparts(fn);
            names = regexp(fp, '(?<fp>[\w-]+)_\d\d', 'names');
            fp = names.fp;
        end
    end

    %% PRIVATE
    
    properties (Access = 'private')
        petTarget_
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

