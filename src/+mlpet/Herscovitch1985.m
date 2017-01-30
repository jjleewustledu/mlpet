classdef Herscovitch1985 
	%% HERSCOVITCH1985  
    %  See also:
    %  1. Herscovitch P, Mintun MA, Raichle ME (1985) Brain oxygen utilization measured with oxygen-15 radiotracers and 
    %  positron emission tomography: generation of metabolic images. J Nucl Med 26(4):416?417.
    %  2. Videen TO, Perlmutter JS, Herscovitch P, Raichle ME (1987) Brain blood volume, flow, and oxygen utilization 
    %  measured with 15O radiotracers and positron emission tomography: revised metabolic computations. 
    %  J Cereb Blood Flow Metab 7(4):513?516.

	%  $Revision$
 	%  was created 28-Jan-2017 12:53:40
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.
 	

    properties (Constant)        
        LAMBDA = 0.95           % brain-blood equilibrium partition coefficient, mL/mL, Herscovitch, Raichle, JCBFM (1985) 5:65
        LAMBDA_DECAY = 0.005677 % KLUDGE:  hard-coded [15O] half-life for propagating to static methods
        BRAIN_DENSITY = 1.05    % assumed mean brain density, g/mL
        RBC_FACTOR = 0.766      % per Tom Videen, metproc.inc, line 193        
    end
    
    properties 
        flows = 10:10:100 % mL/100 g/min
    end
    
	properties (Dependent)
        ho
        oo
        oc
        cbf
        cbv
        oef
        
 		aif
        pet
        product        
        sessionData
    end
    
    methods %% GET
        function g = get.ho(this)
            g = this.ho_;
        end
        function g = get.oo(this)
            g = this.oo_;
        end
        function g = get.oc(this)
            g = this.oc_;
        end
        function g = get.cbf(this)
            g = this.cbf_;
        end
        function g = get.cbv(this)
            g = this.cbv_;
        end
        function g = get.oef(this)
            g = this.oef_;
        end
        
        function g = get.aif(this)
            g = this.sessionData.aif;
        end
        function g = get.pet(this)
            g = this.sessionData.pet;
        end
        function g = get.product(this)
            g = this.product_;
        end        
        function g = get.sessionData(this)
            g = this.sessionData_;
        end
    end

    methods (Static)
        function rho = estimatePetdyn(aif, cbf)
            assert(isa(aif, 'mlpet.IAifData'));
            assert(isnumeric(cbf));   
            
            import mlpet.*;
            lam  = Herscovitch1985.LAMBDA;
            lamd = Herscovitch1985.LAMBDA_DECAY;  
            rho  = cbf*conv(aif.becquerelInterpolants, exp(-(cbf/lam + lamd)*aif.timeInterpolants));
            rho  = rho(1:length(aif.times));
        end
        function petobs = estimatePetobs(aif, cbf)
            assert(isa(aif, 'mlpet.IAifData'));
            assert(isnumeric(cbf));   
            
            import mlpet.*;
            rho = Herscovitch1985.estimatePetdyn(aif, cbf);
            petobs = trapz(aif.dt, rho);
        end
        function cbf = estimateCbf(As, petobs)
            cbf = As(1)*petobs^2 + As(2)*petobs;
        end
    end
    
	methods
 		function this = Herscovitch1985(varargin)
 			%% HERSCOVITCH1985
 			%  @param named sessionData
 			
            ip = inputParser;
            addParameter(ip, 'sessionData', [], @(x) isa(x, 'mlpipeline.ISessionData'));
            parse(varargin{:});
            this.sessionData_ = ip.Results.sessionData;
        end
        
        function this = buildA1A2(this, petobs, cbf)
            %% BUILDA1A2 
            %  @param petobs are numeric PETobs := \int_{t \in \text{obs}} dt' \varrho(t').
            %  @param cbf are numeric CBF.
            %  @returns this with this.product := mdl.  A1, A2 are in mdl.Coefficients{:,'Estimate'}.
            %  See also:  https://www.mathworks.com/help/releases/R2016b/stats/nonlinear-regression-workflow.html
            
            fprintf('Herscovitch1985.buildA1A2 ..........\n');
            cbf = ensureCol(cbf);
            petobs = ensureCol(petobs);
            As  = ones(2, 1);
            mdl = fitnlm(petobs, cbf, @mlpet.Herscovitch1985.estimateCbf, As);
            disp(mdl)
            fprintf('mdl.RMSE -> %g, min(rho) -> %g, max(rho) -> %g\n', mdl.RMSE, min(petobs), max(petobs));
            plotResiduals(mdl);
            plotDiagnostics(mdl, 'cookd');
            plotSlice(mdl);
            this.product_ = mdl;
        end
        function this = buildCbfWholebrain(this, varargin)
            sd = this.sessionData;
            ip = inputParser;
            addParameter(ip, 'DtAif', 0, @isnumeric); % sec
            addParameter(ip, 'DtPet', 0, @isnumeric); % sec
            parse(ip, varargin{:});
            
            this = this.ensureAif;
            this = this.ensurePet;
            
            duration = this.aif.times(end) - this.aif.times(1) - abs(ip.Results.DtAif);
            pet = this.pet.petNIfTId;
            pet = pet.masked(ip.Results.mask);
            pet = pet.volumeSummed;
            petobj = ;
            
            this.product_ = cbf;
        end
        function this = buildPetobs(this, varargin)
            ip = inputParser;
            addParameter(ip, 'flows', [], @isnumeric);
            parse(ip, varargin{:});
            
            this.ensureAif;
            this.ensurePet;
            this.product_ = this.estimatePetdyn(this.aif, ip.Results.flows);
        end
        function this = ensureAif(this)
            this.aif_ = this.sessionData.aif;
        end
        function this = ensurePet(this)
            this.pet_ = this.sessionData.pet;
        end
        function plotAif(this)
            this.ensureAif;
            figure;
            plot(this.aif.times, this.aif.activity);
            sd = this.sessionData;
            title(sprintf('Herscovitch1985.plotAif:  %s %s', sd.sessionPath, sd.tracer));
        end
        function plotWholebrain(this, varargin)
            ip = inputParser;
            addOptional(ip, 'flows', this.flows, @isnumeric);
            parse(ip, varargin{:});
            
            this.ensurePet;
            wb = this.pet;
            wb = wb.volumeSummed;
            wb = wb.petNiftid(this.sessionData);
            plot(wb.times, wb.activity);
        end
    end 

    %% PRIVATE
    
	properties (Access = private)
        ho_
        oo_
        oc_
        cbf_
        cbv_
        oef_
        
 		aif_
        pet_
        product_        
        sessionData_
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

