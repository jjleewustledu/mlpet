classdef AutoradiographyWorker  
	%% AUTORADIOGRAPHYWORKER   

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.5.0.197613 (R2015a) 
 	%  $Id$ 
 	 

	properties 
 		 
 	end 

	methods (Static)
        function aparc2mask(fn)
            fn = mlpet.AutoradiographyWorker.removeAparcDot(fn);
            assert(lstrfind(fn, 'a2009s') && lstrfind(fn, 'aseg'));
            toremove = [16 7 8 46 47 14 15 4 43 31 63 24]; % brainstem cerebellumx4 ventriclesx4 choroidplexus csf
            
            import mlfourd.*;
            niid = NIfTId.load(fn);
            for r = 1:length(toremove)
                niid.img(niid.img == toremove(r)) = 0;
            end
            niid.img = double(niid.img > 0);
            niid = niid.append_fileprefix('_mask');
            niid.save;
        end
        function flirtOrigOnTr(origfn, trfn)
            import mlpet.AutoradiographyWorker.*;
            if (lstrfind(origfn, '.mgz'))
                origfn = convert2niigz(origfn); end
            [~,origfp] = filepartsx(origfn, '.nii.gz');
            [pth,trfp] = filepartsx(trfn,   '.nii.gz');
            outfn = fullfile(pth, [origfp '_on_' trfp '.nii.gz']);
            matfn = fullfile(pth, [origfp '_on_' trfp '.mat']);
            mlbash(sprintf( ...
                'flirt -in %s -ref %s -out %s -omat %s -bins 256 -cost normmi -dof 6 -interp trilinear', ...
                origfn, trfn, outfn, matfn));
        end
        function applyxfmToAparcmask(matfn)
            pth    = filepartsx(matfn, '.nii.gz');
            pnum   = str2pnum(pth);
            maskfp = 'aparc_a2009+aseg_mask';
            maskfn = fullfile(pth, [maskfp '.nii.gz']);
            outfn  = fullfile(pth, [maskfp '_on_' pnum 'tr1.nii.gz' ]);
            reffn  = fullfile(pth, [pnum 'tr1.nii.gz']);
            mlbash(sprintf( ...
                'flirt -in %s -applyxfm -init %s -out %s -interp nearestneighbour -ref %s', ...
                maskfn, matfn, outfn, reffn));
        end
        function tvec = prepareHo
            import mlfourd.*;
            pnum = str2pnum(pwd);
            hofn = fullfile(pwd, [pnum 'ho1.nii.gz']);
            maskfn = fullfile(pwd, ['aparc_a2009s+aseg_mask_on_' pnum 'tr1.nii.gz']);
            dyn  = DynamicNIfTId.load(hofn);
            dyn  = dyn.mcflirtedAfterBlur([16 16 16]);
            dyn  = dyn.withRevertedFrames(NIfTId.load(hofn), 1:7);
            dyn  = dyn.masked(NIfTId.load(maskfn));
            dyn  = dyn.volumeSummed;
            tvec = sqeeze(dyn.img);
            plot(tvec);
        end
        function testImport
            import mlpet.AutoradiographyWorker.*;
            testImport2;
        end
    end
    
    %% PRIVATE
    
    methods (Static, Access = 'private')
        function fn1 = removeAparcDot(fn)            
            [pth,fp,ext] = fileparts(fn);
            if (strncmp(fp, 'aparc.', 6))
                fp(1:6) = 'aparc_';
                fn1 = fullfile(pth, [fp ext]);
                mlbash(sprintf('cp %s %s', fn, fn1));
            end
        end
        function fn1 = convert2niigz(fn)
            [pth,fp] = fileparts(fn);
            fn1 = fullfile(pth, [fp '.nii.gz']);
            mlbash(sprintf('mri_convert %s %s', fn, fn1));
        end
        function testImport2
           fprintf('inside testImport2\n'); 
        end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

