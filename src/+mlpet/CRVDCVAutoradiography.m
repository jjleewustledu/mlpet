classdef CRVDCVAutoradiography < mlpet.CRVAutoradiography
	%% CRVDCVAutoradiography
    %  Cf:  Raichle, Martin, Herscovitch, Mintun, Markham, 
    %       Brain Blood Flow Measured with Intravenous H_2[^15O].  II.  Implementation and Valication, 
    %       J Nucl Med 24:790-798, 1983.
    %       Hescovitch, Raichle, Kilbourn, Welch,
    %       Positron Emission Tomographic Measurement of Cerebral Blood Flow and Permeability-Surface Area Product of
    %       Water Using [15O]Water and [11C]Butanol, JCBFM 7:527-541, 1987.
    %  Internal units:   mL, cm, g, s

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.4.0.150421 (R2014b) 
 	%  $Id$
    
    methods (Static)        
        function this = load(ecatFn, crvFn, dcvFn, maskFn, varargin)            
            ip = inputParser;
            addRequired(ip, 'ecatFn', @(x) lexist(x, 'file'));
            addRequired(ip, 'crvFn',  @(x) lexist(x, 'file'));
            addRequired(ip, 'dcvFn',  @(x) ischar(x));
            addRequired(ip, 'maskFn', @(x) lexist(x, 'file'));
            addOptional(ip, 'ecatShift', 0, @(x) isnumeric(x) && isscalar(x));
            addOptional(ip, 'crvShift',  0, @(x) isnumeric(x) && isscalar(x));
            addOptional(ip, 'dcvShift',  0, @(x) isnumeric(x) && isscalar(x));
            parse(ip, ecatFn, crvFn, dcvFn, maskFn, varargin{:});
            
            import mlfourd.* mlpet.*;
            ecatObj = CRVDCVAutoradiography.loadEcat(ip.Results.ecatFn); 
            crvObj  = CRVDCVAutoradiography.loadCrv( ip.Results.crvFn); 
            dcvObj  = [];
            if (lexist(ip.Results.dcvFn, 'file'))
                dcvObj = CRVDCVAutoradiography.loadDcv( ip.Results.dcvFn); 
            end
            maskObj = CRVDCVAutoradiography.loadMask(ip.Results.maskFn);          
            args = CRVDCVAutoradiography.interpolateData( ...
                ecatObj, crvObj, dcvObj, maskObj, ...
                ip.Results.ecatShift, ip.Results.crvShift, ip.Results.dcvShift);
            this = CRVDCVAutoradiography(args{:});
        end
    end
    
	methods	  
 		function this = CRVDCVAutoradiography(varargin)
 			%% CRVDCVAutoradiography 

 			this = this@mlpet.CRVAutoradiography(varargin{:});            
        end
        function S    = sumSquaredErrors(this, pars)
            pars = num2cell(pars);        
            logP1 = sum(abs(this.dependentData - this.estimateDataFast(pars{:})).^2) / ...
                    sum(abs(this.dependentData).^2); % ECAT_t[ROI]
            logP2 = sum(abs(this.conc_crv_      - this.estimateCrvFast( pars{:})).^2) / ...
                    sum(abs(this.conc_crv_).^2); % CRV_t[arterial]
            logP3 = sum(abs(this.conc_dcv_      - this.estimateDcvFast( pars{:})).^2) / ...
                    sum(abs(this.conc_dcv_).^2); % DCV_t[arterial]
            S     = logP1 + logP2 + logP3;
            if (S < eps)
                S = eps * (1 + rand(1)); 
            end
        end             
        function        plotProduct(this)
            figure;
            max_ecat = max( max(this.itsConcentration_ecat), max(this.dependentData));
            max_aif  = max([max(this.itsConcentration_crv) max(this.conc_crv_)]);
            
            plot(this.times, this.itsConcentration_ecat   / max_ecat, ...
                 this.times, this.dependentData           / max_ecat, 'o', ...
                 this.times, this.itsConcentration_crv    / max_aif, ...
                 this.times, this.conc_crv_               / max_aif, 's', ...
                 this.times, this.itsConcentration_dcv    / max_aif, ...
                 this.times, this.conc_dcv_               / max_aif, '^');
            legend('concentration_{ecat}', 'data_{ecat}', ...
                   'concentration_{crv}',  'data_{crv}', ...
                   'concentration_{drv}',  'data_{drv}'); 
            title(this.detailedTitle, 'Interpreter', 'none');
            xlabel(this.xLabel);
            ylabel(sprintf('arbitrary:  ECAT norm %g, AIF norm %g', max_ecat, max_aif));
        end
    end     
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

