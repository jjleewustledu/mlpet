classdef OCCRVAutoradiography < mlpet.CRVAutoradiography
	%% OCCRVAUTORADIOGRAPHY
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
            ecatObj = OCCRVAutoradiography.loadEcat(ip.Results.ecatFn); 
            crvObj  = OCCRVAutoradiography.loadCrv( ip.Results.crvFn); 
            dcvObj  = [];
            if (lexist(ip.Results.dcvFn, 'file'))
                dcvObj = OCCRVAutoradiography.loadDcv( ip.Results.dcvFn); 
            end
            maskObj = OCCRVAutoradiography.loadMask(ip.Results.maskFn);          
            args = OCCRVAutoradiography.interpolateData( ...
                ecatObj, crvObj, dcvObj, maskObj, ...
                ip.Results.ecatShift, ip.Results.crvShift, ip.Results.dcvShift);
            this = OCCRVAutoradiography(args{:});
        end
    end
    
	methods	  
 		function this = OCCRVAutoradiography(varargin)
 			%% OCCRVAUTORADIOGRAPHY 

 			this = this@mlpet.CRVAutoradiography(varargin{:});            
        end 
    end     
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

