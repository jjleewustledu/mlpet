classdef Ichise2002SimulAnneal < mlpet.TracerSimulAnneal
    %% line1
    %  line2
    %  
    %  Created 14-Dec-2023 18:47:43 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
    %  Developed on Matlab 23.2.0.2428915 (R2023b) Update 4 for MACA64.  Copyright 2023 John J. Lee.
    
    methods
        function this = Ichise2002SimulAnneal(varargin)
            this = this@mlpet.TracerSimulAnneal(varargin{:});
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
        function this = solve(this, varargin)
            ip = inputParser;
            addRequired(ip, 'loss_function', @(x) isa(x, 'function_handle'))
            parse(ip, varargin{:})
            ipr = ip.Results;
            
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
                @(ks__) ipr.loss_function( ...
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
