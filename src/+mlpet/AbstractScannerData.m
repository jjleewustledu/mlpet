classdef (Abstract) AbstractScannerData < mlpet.IScannerData 
	%% ABSTRACTSCANNERDATA   
    %  Yet abstract:  static method load, method save

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.4.0.150421 (R2014b) 
 	%  $Id$ 
    
    properties  
        dt = 1 % sec, for timeInterpolants
        useBecquerels = false % boolean for dividing accumulated counts by sampling durations of each time-frame to obtain 1/sec  
    end
	
    properties (Dependent)
        filename
        filepath
        fileprefix 
        filesuffix
        fqfilename
        fqfileprefix
        fqfn
        fqfp
        noclobber      
        
        scanIndex % integer, e.g., last char in 'p1234ho1'
        tracer % char, e.g., 'ho'
        length % integer, number valid frames
        scanDuration % sec   
        times
        timeInterpolants
        counts
        countInterpolants
        header
        
        taus
        timeMidpoints
        injectionTime
        
        nifti
        recFqfilename 		
    end 

    methods %% GET, SET
        function f = get.filename(this)
            f = this.nifti_.filename;
        end
        function f = get.filepath(this)
            f = this.nifti_.filepath;
        end
        function f = get.fileprefix(this)
            f = this.nifti_.fileprefix;
        end
        function f = get.filesuffix(this)
            f = this.nifti_.filesuffix;
        end
        function f = get.fqfilename(this)
            f = this.nifti_.fqfilename;
        end
        function f = get.fqfileprefix(this)
            f = this.nifti_.fqfileprefix;
        end
        function f = get.fqfn(this)
            f = this.nifti_.fqfn;
        end
        function f = get.fqfp(this)
            f = this.nifti_.fqfp;
        end
        function f = get.noclobber(this)
            f = this.nifti_.noclobber;
        end
        
        function idx  = get.scanIndex(this)
            names = regexp(this.fileprefix, mlpet.PETIO.SCAN_INDEX_EXPR, 'names');
            idx = str2double(names.idx);
        end
        function t    = get.tracer(this)
            names = regexp(this.fileprefix, mlpet.PETIO.TRACER_EXPR, 'names');
            t = names.tracer;
        end
        function l    = get.length(this)
            assert(~isempty(this.times_));
            l = length(this.times);
        end
        function sd   = get.scanDuration(this)
            assert(~isempty(this.times_));
            sd = this.times_(end);
        end
        function t    = get.times(this)
            assert(~isempty(this.times_));
            t = this.times_;
        end
        function this = set.times(this, t)
            assert(isnumeric(t));
            this.times_ = t;
        end
        function t    = get.timeInterpolants(this)
            assert(~isempty(this.times_));
            t = this.times_(1):this.dt:this.times_(end);
        end
        function c    = get.counts(this)
            assert(~isempty(this.nifti_));
            c = this.nifti_.img;
        end
        function this = set.counts(this, c)
            assert(isnumeric(c));
            this.nifti_.img = c;
        end
        function c    = get.countInterpolants(this)
            assert(~isempty(this.nifti_));
            if (prod(this.nifti_.size) > length(this.times))
                c = nan; 
                return
            end
            im = squeeze(this.nifti_.img)';
            c  = pchip(this.times, im, this.timeInterpolants);
        end
        function h    = get.header(this)
            assert(~isempty(this.header_));
            h = this.header_;
        end
        function this = set.header(this, h)
            if (isstruct(h))
                this.header_ = h; end            
        end
        
        function t = get.taus(this)
            assert(~isempty(this.taus_));
            t = this.taus_;
        end
        function tmp = get.timeMidpoints(this)
            tmp = this.times;
            for t = 2:this.length
                tmp(t) = (this.times_(t-1) + this.times_(t))/2;
            end
        end
        function t = get.injectionTime(this)
            t = this.header.injectionTime;
        end
        function n = get.nifti(this)
            assert(~isempty(this.nifti_));
            n = this.nifti_;
        end
        function this = set.nifti(this, nii)
            assert(isa(nii, 'mlfourd.NIfTI'));
            this.nifti_ = nii;
        end
        function f = get.recFqfilename(this)
            f = sprintf('%s.img.rec', this.fqfileprefix);
        end
    end
    
	methods 		  
 		function this = AbstractScannerData(fileLoc) 
 			%% ABSTRACTSCANNERDATA 
 			%  Usage:  this = this@mlpet.AbstractScannerData(file_location) 
            %          this = this@mlpet.AbstractScannerData('/path/to/p1234data/p1234ho1.crv')
            %          this = this@mlpet.AbstractScannerData('/path/to/p1234data/p1234ho1')
            %          this = this@mlpet.AbstractScannerData('p1234ho1')

            this.nifti_ = mlfourd.NIfTI.load(fileLoc);
 		end 
        function this = saveas(this, fqfn)
            this.nifti_.fqfilename = fqfn;
            this.save;
        end
        function i = guessIsotope(this)
            if (lstrfind(this.tracer, {'ho' 'oo' 'oc' 'co'}))
                i = '15O';
                return
            end
            if (lstrfind(this.tracer, 'g'))
                i = '11C';
                return
            end            
            error('mlpet:indeterminatePropertyValue', ...
                'AbstractScannerData.guessIsotope could not recognize the isotope of %s', this.fileprefix);
        end
    end 
    
    %% PROTECTED
    
    properties (Access = 'protected')
        nifti_
        
        times_
        taus_
        counts_
        header_
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

