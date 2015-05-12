classdef AutoradiographyTester  
	%% AUTORADIOGRAPHYTESTER   

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.5.0.197613 (R2015a) 
 	%  $Id$  	 

	methods (Static) 		
        function prods  = testDSC            
            import mlpet.* mlfourd.*;
            this = AutoradiographyTrainer;
            
            pwd0 = this.WORK_DIR;
            cd(pwd0);   
            diary(sprintf('AutoradiographyTrainer.testDSC_%s.log', datestr(now, 30)));
            for c = 1:length(this.MM_CASES)
                cd(fullfile(pwd0, this.casePaths{c})); 
                fprintf('AutoradiographyTrainer.testDSC is working in %s\n', pwd);
                this.director_ = ...
                    AutoradiographyDirector.loadDSC( ...
                        this.maskFn, this.dscMaskFn, this.dscFn, this.ecatFn);
                this.director_ = this.director_.estimateAll;
                prods{c} = this.director_.product;
            end
            cd(pwd0);
            
            save(sprintf('AutoradiographyTrainer.trainDSC.prods_%s.mat', datestr(now,30)), 'prods');
            diary off
        end        
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

