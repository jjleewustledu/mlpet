classdef TSC_np755 < mlpet.TSC
	%% TSC_NP755 objectifies Mintun-Markham *.tsc files for use with calculations on data from np755.  
    %  Tsc files record scanner-array events, correct for positron half-life and adjust scanner-array events to yield well-counter units.
    %  This is a simple subclassing of TSC with methods replaced as needed.
    
	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.4.0.150421 (R2014b) 
 	%  $Id$ 
 	 
    methods (Static)
        function this = loadH15O(pnumPth, scanIdx)
            %% LOADGLUT
 			%  Usage:  this = TSC_np755.loadH15O(pnumber_path, scan_index) 
            %          this = TSC_np755.loadH15O('/path/to/p1234data', 1)
            
            assert(lexist(pnumPth, 'dir'));
            pnum = str2pnum(pnumPth);
            if (isnumeric(scanIdx)); scanIdx = num2str(scanIdx); end
            
            ecatLoc = fullfile(pnumPth, 'ECAT_EXACT', 'pet', [pnum 'ho' scanIdx '.nii.gz']);
            tscLoc  = fullfile(pnumPth, 'ECAT_EXACT', 'pet', [pnum 'ho' scanIdx '.tsc']);
            dtaLoc  = fullfile(pnumPth, 'ECAT_EXACT', 'pet', [pnum '.dta']);
            this = mlpet.TSC_np755.load(tscLoc, ecatLoc, dtaLoc, 4.88);            
        end
        function this = load(tscLoc, ecatLoc, dtaLoc, pie)
            %% LOAD
 			%  Usage:  this = TSC_np755.load(tsc_file_location, ecat_file_location,  dta_file_location, pie_factor) 
            %          this = TSC_np755.load('/p1234data/jjl_proc/p1234wb1.tsc', '/p1234data/PET/scan1/p1234gluc1.nii.gz', '/p1234data/jjl_proc/p1234g1.dta', 4.88)
            %          this = TSC_np755.load('/p1234data/jjl_proc/p1234wb1', '/p1234data/PET/scan1/p1234gluc1', '/p1234data/jjl_proc/p1234g1', 4.88)
            %          this = TSC_np755.load('p1234wb1', '../PET/scan1/p1234gluc1', 'p1234g1', 4.88) 
            
            import mlpet.* mlfourd.*;
            
            this = TSC_np755(tscLoc);
            this.mask_ = this.makeMask;
            this.dta_ = DTA(dtaLoc);
            this.decayCorrectedEcat_ = this.maskEcat( ...
                                       DecayCorrectedEcat.load(pie, ecatLoc), this.mask_);
            
            this.times_  = this.decayCorrectedEcat_.times;  
            this.taus_   = this.decayCorrectedEcat_.taus; 
            this.counts_ = this.squeezeVoxels(this.decayCorrectedEcat_, this.mask_);  
            this.header_ = this.decayCorrectedEcat_.header;                 
            
            if (~lexist(this.fqfilename) || ~this.noclobber)
                this.save;
            end
        end
    end

	methods 	
 		function this = TSC_np755(tscLoc)
            %% TSC_NP755
 			%  Usage:  this = TSC_np755(tsc_file_location, ecat_file_location,  dta_file_location, pie_factor) 
            %          this = TSC_np755('/p1234data/jjl_proc/p1234wb1.tsc', '/p1234data/PET/scan1/p1234gluc1.nii.gz', '/p1234data/jjl_proc/p1234g1.dta', 4.88)
            %          this = TSC_np755('/p1234data/jjl_proc/p1234wb1', '/p1234data/PET/scan1/p1234gluc1', '/p1234data/jjl_proc/p1234g1', 4.88)
            %          this = TSC_np755('p1234wb1', '../PET/scan1/p1234gluc1', 'p1234g1', 4.88)   
 			%  Usage:  this = TSC_np755(tsc_file_location) 
            %          this = TSC_np755('/path/to/p1234data/jjl_proc/p1234wb1.tsc')
            %          this = TSC_np755('/path/to/p1234data/jjl_proc/p1234wb1')
            %          this = TSC_np755('p1234wb1')   
            %
            % N.B.:  \pi \equiv \frac{wellcnts/cc/sec}{PETcnts/pixel/min}
            %        wellcnts/cc = \pi \frac{PETcnts}{pixel} \frac{sec}{min}

            this = this@mlpet.TSC(tscLoc);            
        end
    end 

    %% PROTECTED
    
    methods (Access = 'protected')
        function f   = maskFilename(this)
            f = sprintf('aparc_a2009s+aseg_mask_on_%sho%i.nii.gz', this.pnumber, this.scanIndex);
        end
        function f   = maskFqfilename(this)
            f = fullfile(this.fslPath, this.maskFilename);
        end  
    end
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

