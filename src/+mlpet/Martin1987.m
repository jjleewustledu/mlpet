classdef Martin1987 < mlpet.ModelBuilder
	%% MARTIN1987  

	%  $Revision$
 	%  was created 30-May-2018 01:53:55 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties
 		
    end

    methods (Static)
        function assertOc(obj)
            assert(isa(obj, 'mlfourd.ImagingContext'));
            assert(lstrfind(lower(obj.fileprefix), 'oc'));
            assert(~isempty(obj.niftid.img));
        end
    end
    
	methods 
        
        function this = buildCbv(this, varargin)
            ip = inputParser;
            addParameter(ip, 'oc', [], @this.assertOc);
            parse(ip, varargin{:});
            
            pwd0 = pushd(this.sessionContext.vallLocation);
            this.calibrations_ = this.assembleCalibrations;
            a = this.assembleAif;
            s = this.assembleScan(ip.Results.oc);
            s = s.petobs;
            W = this.calibrations_.invEffMMR;
            s.img = 100 * s.img * W / (this.RBC_FACTOR * this.BRAIN_DENSITY * a.specificActivityIntegral);
            %s.img = 100 * s.img / max(max(max(s.img)));
            s = s.blurred(s.petPointSpread);
            s.fqfilename = this.sessionContext.cbv('typ', 'fqfn');            
            s.save;
            this.product_ = mlfourd.ImagingContext(s.component);
            popd(pwd0);
        end
		  
 		function this = Martin1987(varargin)
 			%% MARTIN1987
 			%  @param named tracerContext.

 			this = this@mlpet.ModelBuilder(varargin{:});
 		end
    end 
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

