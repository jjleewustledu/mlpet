classdef C15OBuilder 
	%% C15OBUILDER  

	%  $Revision$
 	%  was created 16-Oct-2015 14:52:57
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlpet/src/+mlpet.
 	%% It was developed on Matlab 8.5.0.197613 (R2015a) for MACI64.
 	

	properties (Dependent)
        niftid 		
    end
    
    methods % GET
        function g = get.niftid(this)
            assert(~isempty(this.niftid_));
            g = this.niftid_;
        end
    end
    
    methods (Static)
        function this = load(filename)
            %  Usage:  this = C15OBuilder.load(filename)
            
            [~,fprefix] = myfileparts(filename);
            assert(lstrfind(fprefix, 'oc'));
            this = mlpet.C15OBuilder;
            this.niftid_ = mlfourd.NIfTId.load(filename);
        end
        
    end

	methods 		  
        function a = maskedAverage(this, mask)
            %  Usage:  average = this.maskedAverage(mask_NIfTId)
            
            import mlfourd.*;
            mNiid = MaskingNIfTId(this.niftid_);
            a     = mNiid.maskedMean(mask);
        end
        
 		function this = C15OBuilder(varargin)
 			%% C15OBUILDER
 			%  Usage:  this = C15OBuilder() 			
 		end
    end 
    
    %% PRIVATE
    
    properties (Access = 'private')
        niftid_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

