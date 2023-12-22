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
        function Q = loss(this)
            Q = this.product_.loss;
        end
        function h = plot(this, opts)
            %% PLOT 0:length() -> this.dispersedAif();
            %       this.TimesSampled -> this.Measurement;
            %       this.TimesSampled -> this.model.sampled();
            %       
            %  also plot xs{i} -> ys{i};           

            arguments
                this mlpet.TracerSimulAnneal
                opts.activityUnits {mustBeTextScalar} = "Bq/mL"
                opts.tag {mustBeTextScalar} = ""
                opts.xlim {mustBeNumeric} = [-10 500] % sec
                opts.ylim {mustBeNumeric} = []
                opts.xs cell = {} % additional xs to plot
                opts.ys cell = {} % additional ys to plot
                opts.legends cell = {} % of additional xs, ys
                opts.colorArt {mustBeTextScalar} = "#A2142F" % maroon
                opts.colorMeas {mustBeTextScalar} = "#0072BD" % navy
                opts.colorModel {mustBeTextScalar} = "0072BD" % navy
                opts.colors cell = {} % consider #EDB120 ~ mustard
                opts.zoomArt double = 1
                opts.zoomMeas double = 4 
                opts.zoomModel double = 4 
                opts.zooms cell = {}
            end
            assert(length(opts.xs) == length(opts.ys))
            if ~isempty(opts.xs) && isempty(opts.colors)
                opts.colors = repmat("#EDB120", size(opts.xs));
            end
            this.zoom = struct( ...
                'zoomArt', opts.zoomArt, ...
                'zoomMeas', opts.zoomMeas, ...
                'zoomModel', opts.zoomModel, ...
                'zooms', opts.zooms);
            
            % var notations
            %ad = mlaif.AifData.instance();
            %tBuffer = ad.tBuffer;
            TS = this.TimesSampled;
            TSInt = 0:TS(end);
            ArtInt = this.ArteryInterpolated;  
            Meas = this.Measurement;
            Model = this.rescaleModelEstimate(this.model.sampled(this.ks, this.Data, ArtInt, TS));
            
            % build legends
            legendCell = {};
            legendCell = [legendCell, sprintf('Arterial x%i', opts.zoomArt)];
            legendCell = [legendCell, sprintf('Measurement x%i', opts.zoomMeas)];
            legendCell = [legendCell, sprintf('Model x%i', opts.zoomModel)];
            legendCell = [legendCell, opts.legends]; % of additional xs, ys

            % plotting implementation
            h = figure;
            hold("on");
            plot(TSInt, opts.zoomArt*ArtInt, '-', LineWidth=2, Color=opts.colorArt)
            plot(TS, opts.zoomMeas*Meas, 'o', MarkerSize=12, Color=opts.colorMeas)
            plot(TS, opts.zoomModel*Model, '--', LineWidth=2, Color=opts.colorMeas)
            for ci = 1:length(opts.xs)
                plot(opts.xs{ci}, opts.ys{ci}, ':', LineWidth=1.5, Color=opts.colors{ci})
            end
            legend(legendCell);
            if ~isempty(opts.xlim); xlim(opts.xlim); end
            if ~isempty(opts.ylim); ylim(opts.ylim); end
            xlabel('times / s')
            ylabel(sprintf('activity / (%s)', opts.activityUnits))
            annotation('textbox', [.25 .5 .3 .3], 'String', sprintfModel(this), 'FitBoxToText', 'on', 'FontSize', 10, 'LineStyle', 'none')
            opts.tag = strrep(opts.tag, "_", " ");
            title([stackstr(use_spaces=true)+";"; string(opts.tag); ""], FontSize=6)
            hold("off");
            set(h, position=[300,100,1000,618])
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
