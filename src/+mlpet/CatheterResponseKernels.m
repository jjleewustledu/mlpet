classdef CatheterResponseKernels 
	%% CATHETERRESPONSEKERNELS  

	%  $Revision$
 	%  was created 11-Feb-2016 19:22:33
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.0.0.307022 (R2016a) Prerelease for MACI64.
 	

	properties
 		kernel
 	end

	methods 
		  
 		function this = CatheterResponseKernels(choice)
 			%% CATHETERRESPONSEKERNELS
 			%  Usage:  this = CatheterResponseKernels()

            switch (choice)
                case 'bsrf_id1'
                    load(fullfile('ARBELAEZ'), 'bsrf120_id1.mat');
                    kernel = bsrf120_id1;
                case 'bsrf_id2'
                    load(fullfile('ARBELAEZ'), 'bsrf120_id2.mat');
                    kernel = bsrf120_id2;
                case 'kernelBest' % red catheter, by Savitsky-Golay filtering
                    load(fullfile(getenv('ARBELAEZ'), 'kernelBest.mat'));
                    kernel = kernelBest;
                    kernel = kernel(12:40);
                    kernel(kernel < 0) = 0;
                otherwise
                    error('mlpet:unmatchedSwitchCase', 'CatheterResponseKernels.ctor');
            end
            this.kernel = kernel/sum(kernel);
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

