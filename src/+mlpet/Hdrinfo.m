classdef Hdrinfo 
	%% HDRINFO  

	%  $Revision$
 	%  was created 16-Oct-2015 13:45:07
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlpet/src/+mlpet.
 	%% It was developed on Matlab 8.5.0.197613 (R2015a) for MACI64.
 	

	properties (Constant)
 		EXTENSION = '.hdrinfo'
    end
    
    properties (Dependent)
        bloodVolumeFactor
    end
    
    methods % GET
        function g = get.bloodVolumeFactor(this)
            g = this.parser_.parseAssignedNumeric('Blood Volume Factor');
        end
    end
    
    methods (Static)
        function this = load(filename)
            assert(lexist(filename, 'file'));
            
            import mlpet.*;
            this = Hdrinfo;
            this.parser_ = mlio.TextParser.loadx(filename, Hdrinfo.EXTENSION);
        end
    end
    
    %% PRIVATE
    
    properties (Access = 'private')
        parser_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

