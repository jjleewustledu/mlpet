classdef (Abstract) ResolverToTracerStrategy < handle & matlab.mixin.Copyable
	%% RESOLVERTOTRACER from a strategy design pattern with ResolverToFDG, ResolverToHO and other child classes.

	%  $Revision$
 	%  was created 08-Jan-2020 19:53:44 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.7.0.1261785 (R2019b) Update 3 for MACI64.  Copyright 2020 John Joowon Lee.
 	
	properties (Abstract) 		
 	end

	methods (Abstract)
    end 
    
    %%
    
    properties (Dependent)
        collectionRB
        product
        tracer
        workpath
    end
    
    methods (Static)
        function this = CreateResolver(client)
            import mlpet.*
            switch class(client) % deprecated
                case 'mlpet.SubjectResolveBuilder'
                    this = ResolverToTracerStrategy.CreateSubjectResolver(client);
                case 'mlpet.SessionResolveBuilder'
                    this = ResolverToTracerStrategy.CreateSessionResolver(client);
                otherwise
                    error('mlpet:NotImplementedError', 'ResolverToTracerStrategy.CreateResolver')                    
            end
        end
        function this = CreateSubjectResolver(client)
            switch upper(client.sessionData.referenceTracer)
                case 'FDG'
                    this = mlpet.SubjectResolverToFDG('client', client);
                otherwise
                    error('mlpet:NotImplementedError', 'ResolverToTracerStrategy.CreateSubjectResolver')
            end
        end
        function this = CreateSessionResolver(client)
            switch upper(client.sessionData.referenceTracer)
                case 'FDG'
                    this = mlpet.SessionResolverToFDG('client', client);
                case 'HO'
                    this = mlpet.SessionResolverToHO('client', client);                    
                otherwise
                    error('mlpet:NotImplementedError', 'ResolverToTracerStrategy.CreateSessionResolver')
            end            
        end
    end
    
    %%
    
    methods
        
        %% GET
        
        function g = get.collectionRB(this)
            g = this.collectionRB_;
        end
        function     set.collectionRB(this, s)
            assert(isa(s, 'mlfourdfp.CollectionResolveBuilder'))
            this.collectionRB_ = s;
        end
        function g = get.product(this)
            g = this.collectionRB.product;
            if ~iscell(g)
                g = {g};
            end
        end
        function     set.product(this, s)
            if ~iscell(s)
                s = {s};
            end
            this.collectionRB.product = s;
        end
        function g = get.tracer(this)
            g = this.collectionRB.tracer;
        end
        function     set.tracer(this, s)
            assert(ischar(s));
            this.collectionRB.tracer = upper(s) ;
        end
        function g = get.workpath(this)
            g = this.collectionRB.workpath;
        end
        
        %%        
        
        function that = clone(this)
            that = copy(this);
        end
        function this = packageProduct(this, varargin)
            this.collectionRB = this.collectionRB.packageProduct(varargin{:});
        end
        function this = productAverage(this, varargin)
            this.collectionRB = this.collectionRB.productAverage(varargin{:});
        end
    end
    
    %% PROTECTED
    
    properties (Access = protected)
        client_
        collectionRB_
    end
    
    methods (Access = protected)
        function that = copyElement(this)
            %%  See also web(fullfile(docroot, 'matlab/ref/matlab.mixin.copyable-class.html'))
            
            that = copyElement@matlab.mixin.Copyable(this);
            % N.B.:  that.object_ = copy(this.object_);
        end
        
        function this = ResolverToTracerStrategy(varargin)
            %% forces creation by factory methods CreateFrom*
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'client', [], @(x) isa(x, 'mlpet.StudyResolveBuilder'))
            parse(ip, varargin{:})
            ipr = ip.Results;            
            this.client_ = ipr.client;
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

