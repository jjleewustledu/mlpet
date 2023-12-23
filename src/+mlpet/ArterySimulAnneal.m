classdef ArterySimulAnneal < mlpet.TracerSimulAnneal
    %% line1
    %  line2
    %  
    %  Created 28-Apr-2023 14:35:30 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
    %  Developed on Matlab 9.14.0.2239454 (R2023a) Update 1 for MACI64.  Copyright 2023 John J. Lee.
    
	properties
    end
    
	properties (Dependent) 
        kernel  
        model_kind
        tracer
    end

	methods %% GET
        function g = get.kernel(this)
            g = this.model.kernel;
        end
        function g = get.model_kind(this)
            try
                g = this.model.Data.model_kind;
            catch % legacy support
                g = this.model.model_kind;
            end
        end
        function g = get.tracer(this)
            try
                g = this.model.Data.tracer;
            catch % legacy support
                g = this.model.tracer;
            end
        end
    end

    methods
        function this = ArterySimulAnneal(varargin)
            this = this@mlpet.TracerSimulAnneal(varargin{:})
        end
     
        function D = Delta(this)
            %% override as needed, e.g., D <- 0

            D = 0;
        end
        function [k,sk] = k1(this, varargin)
            [k,sk] = find_result(this, 'k1');
        end
        function [k,sk] = k2(this, varargin)
            [k,sk] = find_result(this, 'k2');
        end
        function [k,sk] = k3(this, varargin)
            [k,sk] = find_result(this, 'k3');
        end    
        function [k,sk] = k4(this, varargin)
            [k,sk] = find_result(this, 'k4');
        end          
        function [k,sk] = k5(this, varargin)
            [k,sk] = find_result(this, 'k5');
        end  
        function [k,sk] = k6(this, varargin)
            [k,sk] = find_result(this, 'k6');
        end
        function [k,sk] = k7(this, varargin)
            [k,sk] = find_result(this, 'k7');
        end
        function [k,sk] = k8(this, varargin)
            [k,sk] = find_result(this, 'k8');
        end
        function [k,sk] = k9(this, varargin)
            [k,sk] = find_result(this, 'k9');
        end
        function [k,sk] = k10(this, varargin)
            [k,sk] = find_result(this, 'k10');
        end
        function [k,sk] = k11(this, varargin)
            [k,sk] = find_result(this, 'k11');
        end
        function [k,sk] = k12(this, varargin)
            [k,sk] = find_result(this, 'k12');
        end
        function Q = loss(this)
            Q = this.product_.loss;
        end
        function est = rescaleModelEstimate(this, est, opts)
            arguments
                this mloptimization.SimulatedAnnealing
                est {mustBeNumeric}
                opts.norm {mustBeTextScalar} = "max"
            end

            if strcmpi(opts.norm, "max")
                % est = est/max(est); % this is a bug!
                est = this.M0*est;
                return
            end

            % rescale by this.int_dt_M
            est = est/max(est); % for floating-point density
            int_dt_est = trapz(this.TimesSampled, est);
            est = est*this.int_dt_M/int_dt_est;
        end
        function save(this)
            save([this.fileprefix '.mat'], this);
        end
        function saveas(this, fn)
            save(fn, this);
        end
        function this = solve(this, loss_function)
            %% Args:
            %      this mlpet.ArterySimulAnneal
            %      loss_function function_handle
            
            arguments
                this mlpet.ArterySimulAnneal
                loss_function function_handle
            end
            
            options_fmincon = optimoptions('fmincon', ...
                'FunctionTolerance', 1e-12, ...
                'OptimalityTolerance', 1e-12, ...
                'TolCon', 1e-14, ...
                'TolX', 1e-14);
            if this.visualize_anneal
                options = optimoptions('simulannealbnd', ...
                    'AnnealingFcn', 'annealingboltz', ...
                    'FunctionTolerance', eps, ...
                    'HybridFcn', {@fmincon, options_fmincon}, ...
                    'InitialTemperature', 20, ...
                    'MaxFunEvals', 50000, ...
                    'ReannealInterval', 200, ...
                    'TemperatureFcn', 'temperatureexp', ...
                    'Display', 'diagnose', ...
                    'PlotFcns', {@saplotbestx,@saplotbestf,@saplotx,@saplotf,@saplotstopping,@saplottemperature});
            else
                options = optimoptions('simulannealbnd', ...
                    'AnnealingFcn', 'annealingboltz', ...
                    'FunctionTolerance', eps, ...
                    'HybridFcn', {@fmincon, options_fmincon}, ...
                    'InitialTemperature', 20, ...
                    'MaxFunEvals', 50000, ...
                    'ReannealInterval', 200, ...
                    'TemperatureFcn', 'temperatureexp');
            end
 			[ks_,loss,exitflag,output] = simulannealbnd( ...
                @(ks__) loss_function( ...
                        ks__, this.Data, this.ArteryInterpolated, this.TimesSampled, double(this.Measurement)), ...
                        this.ks0, this.ks_lower, this.ks_upper, options);
            
            this.product_ = struct('ks0', this.ks0, 'ks', ks_, 'loss', loss, 'exitflag', exitflag, 'output', output); 
            if ~this.quiet
                fprintfModel(this)
            end
            if this.visualize
                plot(this)
            end
        end 
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
