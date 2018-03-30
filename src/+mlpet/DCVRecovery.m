classdef DCVRecovery 
	%% DCVRECOVERY  

	%  $Revision$
 	%  was created 11-Feb-2016 17:15:01
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.0.0.307022 (R2016a) Prerelease for MACI64.
 	

	properties
 		
 	end

	methods (Static)
        function dcv = fromCRVAutoradiography(ecat, crv, dcv, mask)
            %% CRVAUTORADIOGRAPHY estimates parameters for the Kety autoradiographic method for PET.
            %  It fits ECAT, CRV and, optionally, DCV data.  A data-derived catheter impulse response is needed.
            %  Dcv is estimated by two generalized gamma-variates + steady-state.
    
            crva = mlarbelaez.CRVAutoradiography.load( ...
                ecat.fqfilename, crv.fqfilename, dcv.fqfilename, mask.fqfilename); 
            crva = crva.estimateParameters;
            dcv  = crva.itsConcentration_dcv;
        end
        function dcv = fromCRVDeconvolution(crv)
            %% CRVDECONVOLUTION estimates dcv as two generalized gamma-variates plus steady-state.  
            %  It fits data-derived crv and catheter impulse response.
    
            crvd = mlarbelaez.CRVDeconvolution.loadCRV(crv.fqfilename);
            crvd = crvd.estimateParameters;
            dcv  = crvd.itsConcentrationDCV;
        end
        function dcv = fromBetadcvDeconv(crv)
            %% BETADCVDECONV determines dcv from provided crv and catheter impulse response.
            %  It uses Fourier transformation and resampling to match the algorithm of the original betadcv.
            
            bdd = mlarbelaez.BetadcvDeconv;
        end
        function dcv = fromDCVByGammas(crv)
            dbg = mlpet.DCVByGammas;
        end
        function dcv = fromBayesianDCV0(crv)
            bd0 = mlperfusion.BayesianDCV0;
        end
        function dcv = fromBayesianDCV1(crv)
            bd0 = mlperfusion.BayesianDCV1;
        end
        function dcv = fromExpCatheterDeconvolution4(crv)
            ecd = mlarbelaez.ExpCatheterDeconvolution4;
        end
        function dcv = fromCatheterDeconvolution(crv)
            % See also:  mlarbelaez.CatheterAnalysis
            cd = mlarbelaez.CatheterDeconvolution;
        end
        function dcv = fromBetadcv3(fileprefix, varargin)
            %% BETADCV3 duplicates functionality of the original betadcv from Avi Snyder.
            %  The model of the catheter impulse response is in silentGETTKE.  silentBETADCV
            %  returns the response and the dcv as vectors.
            
            ip = inputParser;
            addRequired(ip, 'fileprefix', @(x) isdir(myfileparts(x)));
            addParmater(ip, 'catheterId', 1, @isnumeric);
            addParmater(ip, 'scanType', 2, @isnumeric);
            addParmater(ip, 'Hct', 42, @isnumeric);
            parse(ip, fileprefix, varargin{:});
            
            b3 = Betadcv3(fileprefix);
            b3.catheterId = ip.Results.catheterId;
            b3.scanType = ip.Results.scanType;
            b3.Hct = ip.Results.Hct;
            [~,dcv] = b3.silentBETADCV;
        end
        function dcv = fromFFT(crv)
        end
        function R = responseByMLEM()
        end
        function R = responseByCatheterTvd()
            ct = mlarbelaez.CatheterTvd;
        end
        function [R,csg] = responseByCatheterSavitzkyGolay(dccrv)
            %% RESPONSEBYCATHETERSAVITZKYGOLAY
            %  See also:  mlarbelaez.CatheterSavitzkyGolay
            
            assert(isa(dccrv, 'mlpet.DecayCorrectedCRV'));
            
            csg = mlarbelaez.CatheterSavitzkyGolay(dccrv);
            csg.explore([13 23 33 43 53], [7 9 11]);
            R   = csg.kernel;
        end
        function R = responseByLegacyCatheterResponse()
            lcr = mlarbelaez.LegacyCatheterResponse;
        end
        function R = responseByLegacyCatheterAnalysis()
            lca = mlarbelaez.LegacyCatheterAnalysis;
        end
        function R = responseByStretchedExpResponse(dccrv, dcv)
            %% STRETCHEDEXPRESPONSE estimates a parametric generalized-gamma model for the cathether impulse response
            %  by fitting crv and dcv data.  It models responses ~ 
            %      exp[-((t - t0)/tau)^beta] [1 + c1 (t - t0)/tau + c2 (t - t0)^2/tau^2, 0 < beta < 2.
            
            assert(isa(dccrv, 'mlpet.DecayCorrectedCRV'));
            assert(isa(dcv,   'mlpet.DCV'));
            
            ser = mlarbelaez.StretchedExpResponse(dccrv, dcv);
            ser = ser.estimateParameters;
            b   = ser.finalParams('beta');
            c0  = ser.finalParams('c0');
            c1  = ser.finalParams('c1');
            c2  = ser.finalParams('c2');
            t0  = ser.finalParams('t0');
            tau = ser.finalParams('tau');
            R   = ser.stretchedExp(b, c0, c1, c2, t0, tau);
        end
        function [R,bcr] = responseByBetadcvCatheterResponse(crv)
            %% BETADCVCATHETERRESPONS estimates parameters of the betadcv kernel (ak1, e) by fitting 
            %  crv data with a Heaviside input and betadcv model for the catheter impulse response.
            
            assert(isa(crv, 'mlpet.CRV'));
            
            bcr = mlarbelaez.BetadcvCatheterResponse(crv);
            bcr.showPlots = true;
            bcr = bcr.estimateParameters;
            R   = bcr.estimateKernel;
        end
        function [R,cr] = responseByCatheterResponse(dccrv)
            %% CATHETERRESPONSE fits two gamma-variates + steady-state to a putative catheter impulse response
            %  that is the finite difference of crv from a Heaviside input of labeled blood into the catheter.
            
            assert(isa(dccrv, 'mlpet.DecayCorrectedCRV'));
            
            cr = mlarbelaez.CatheterResponse(dccrv);
            cr.showPlots = true;
            cr = cr.estimateParameters;
            R  = cr.estimateData;
        end
    end 
    
    methods
        function this = DCVRecovery
            this = this.prepareKernel;
        end
    end
    
    %% PRIVATE

    properties (Access = 'private')
        kernel_
    end
    
    methods (Access = 'private')
        function this = prepareKernel(this)
            crk = mlpet.CatheterResponseKernels('kernelBest');
            this.kernel_ = crk.kernel;
        end
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

