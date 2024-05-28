classdef BetadcvDeconv
	%% BETADCVDECONV determines dcv from provided crv and catheter impulse response.
    %  It uses Fourier transformation and resampling to match the algorithm of the original betadcv.

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.5.0.197613 (R2015a) 
 	%  $Id$ 
 	 
	properties  
        nBinMax = 4096  
        sampleTime = 1 % Sample time (sec/bin)
        nSmoothing = 2
        nExpand = 4    
    end 

    properties (Dependent)
        nBin
        nBuf
        nWork
    end
    
    methods %% GET
        function n = get.nBin(this)
            n = this.dccrv_.length;
        end
        function n = get.nBuf(this)
            n = 20 / this.sampleTime + 1; % 20-sec deconvolution buffer
        end
        function n = get.nWork(this)            
            n = log((this.nBinMax) / (this.nBin + this.nBuf)) / log(2);
        end
    end
    
	methods 		
        function dcvBlood = deconv(this, kernel)
            %% DECONV                                        
            
            kernel = mlfourd.ImagingContext2(kernel);
            kernel = kernel.imagingFormat.img;

            %%  Expand blood vector
                        
            [blood,nBinExpanded] = this.expandData(this.dccrv_.counts, this.nBin);
            kernel               = this.expandData(kernel, this.nBin);
            
            %%	Deconvolve
             
            import mlpet.*;
            dcvBlood = BetadcvDeconv.DECONV(blood, kernel, this.nBinMax);
            K = nBinExpanded / this.nBin;
            for I = 1:this.nBin
                dcvBlood(I) = dcvBlood(I * K);
            end
            for I = 1:this.nSmoothing
                dcvBlood = BetadcvDeconv.CRVSMO(dcvBlood, this.nBin);
            end
            dcvBlood = dcvBlood(1:this.nBin);
             
            %%	Eliminate negative counts
             
            dcvBlood = BetadcvDeconv.CRVMIN(dcvBlood, this.nBin, 0.0);  
            
            %%  Trim arrays
            
            dcvBlood = dcvBlood(1:this.nBin);
            
        end
        function [f, n] = expandData(this, f, n)
            f = this.ensureRowVector(f);
            f(length(f)+1:this.nBinMax) = 0;            
            for K = 1:this.nExpand
                [f, n] = this.EXPAND(f, n);
            end
        end
 		function this = BetadcvDeconv(obj) 
 			%% BETADCVDECONV 
 			%  Usage:  this = BetadcvDeconv(obj) % obj understood by ImagingContext2
            
            ic = mlfourd.ImagingContext2(obj);
            
            this.dccrv_  = ic.imagingFormat.img;
            this.nExpand = floor(min(this.nExpand, this.nWork));
            if (2^this.nExpand * this.nBin > this.nBinMax)
                error('mlarbelaez:BetadcvDeconv', 'NBIN TOO LARGE->%f', this.nBin);
            end 
 		end 
    end 

    %% PRIVATE
    
    properties (Access = 'private')
        dccrv_
    end
    
    methods (Static, Access = 'private')
        function [A, NBIN] = EXPAND(A, NBIN)
            for I = 1:NBIN
                II = NBIN - I + 1;
        		A(2*II) = A(II);
            end
            for I = 1:NBIN - 1
                II = 2 * I;
        		A(II+1) = .5 * (A(II) + A(II + 2));
            end
            NBIN = 2 * NBIN;
            A = A(1:NBIN);
            return
        end
        function X = CRVMIN(X, N, A)
            for I = 1:N
                X(I) = max(X(I), A);
            end
        end
        function A = CRVSMO(A, N)
            lenA = length(A);
            T = A(1);
            for I = 2:N
                U = A(I - 1) + 2 * A(I) + A(I + 1);
                A(I - 1) = T;
        		T = .25 * U;
            end
            A = A(1:lenA);
        end        
        function F = DECONV(H,G,N)
            %% CALCULATE F where H=F*G given H,G
            %  length N
            
            F = fftshift(ifft(fft(H, N) ./ fft(G, N)));
            F = F(2048:2048+length(H));
        end
        function x = ensureColVector(x)
            %% ENSURECOLVECTOR reshapes row vectors to col vectors, leaving matrices untouched
            
            x = mlsystem.VectorTools.ensureColVector(x);
        end
        function x = ensureRowVector(x)
            %% ENSUREROWVECTOR reshapes row vectors to col vectors, leaving matrices untouched
            
            x = mlsystem.VectorTools.ensureRowVector(x);
        end
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

