classdef (Abstract) AbstractBetaCurve < mlpet.AbstractWellData & mlpet.IBetaCurve
	%% ABSTRACTBETACURVE 
    %  Yet abstract:  static method load, method save

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.3.0.532 (R2014a) 
 	%  $Id$  	
    
    properties (Dependent)
        wellFqfilename
        wellFactor
        wellCounts
    end
    
    methods %% GET
        function f = get.wellFqfilename(this)
            f = fullfile(this.petio_.filepath, sprintf('%s.wel', str2pnum(this.petio_.fileprefix)));
        end
        function w = get.wellFactor(this)
            assert(~isempty(this.wellMatrix_), ...
                'DecayCorrection.get.wellFactor:  this.wellMatrix_ was empty');
            w = this.wellMatrix_(5,1); 
        end
        function wc  = get.wellCounts(this)
            wc = this.betaCounts2wellCounts(this.counts);
        end
    end
    
	methods 
        function this = AbstractBetaCurve(fileLoc)
            %% ABSTRACTBETACURVE
            %  Usage:  this = this@mlpet.AbstractBetaCurve(file_location);
            %          this = this@mlpet.AbstractBetaCurve('/path/to/p1234data/p1234ho1.crv')
            %          this = this@mlpet.AbstractBetaCurve('/path/to/p1234data/p1234ho1')
            %          this = this@mlpet.AbstractBetaCurve('p1234ho1')
            
            this = this@mlpet.AbstractWellData(fileLoc);            
            this = this.readWellMatrix;
        end
        function wc   = wellCountInterpolants(this, varargin)
            wc = pchip(this.times, this.wellCounts, this.timeInterpolants);
            wc = wc(1:length(this.timeInterpolants));
            
            if (~isempty(varargin))
                wc = wc(varargin{:}); end
        end
    end
    
    %% PROTECTED
    
    properties (Access = 'protected')
        wellMatrix_
    end
    
    methods (Access = 'protected')
        function this = readWellMatrix(this)
            try
                fid = fopen(this.wellFqfilename);
                tmp = textscan(fid, '%f %f %f %f %f');
                this.wellMatrix_ = cell2mat(tmp);
                fclose(fid);
            catch ME
                handexcept(ME);
            end
        end
        function curve  = betaCounts2wellCounts(this, curve)
            %% PETCOUNTS2WELLCOUNTS; cf. man pie; does not divide out number of pixels.

            for t = 1:length(curve)
                curve(t) = this.wellFactor * curve(t); % taus in sec
            end
        end
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

