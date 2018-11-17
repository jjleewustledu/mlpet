classdef DataAdapter 
	%% DATAADAPTER  

	%  $Revision$
 	%  was created 18-Oct-2018 01:14:11 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties
 		
 	end

    methods (Static)
        function obj = CreateTracerDosing(varargin)
            %% CREATETRACERDOSING
            %  @param scid is mlpet.IScanIdentifier.
            
            ip = inputParser;
            addRequired(ip, 'scid', @(x) isa(x, 'mlpet.IScanIdentifier'));
            parse(ip, varargin{:});
            
            obj = mlpet.XlsxAdapter.CreateTracerDosing(varargin{:});
            error('mlpet:NotImplementedError');
        end
        function obj = CreateTiming(varargin)
            %% CREATETIMING
            %  @param scid is mlpet.IScanIdentifier.
            
            ip = inputParser;
            addRequired(ip, 'scid', @(x) isa(x, 'mlpet.IScanIdentifier'));
            parse(ip, varargin{:});
            
            obj = mlpet.XlsxAdapter.CreateTiming(varargin{:});
            error('mlpet:NotImplementedError');
        end
        function obj = CreateDecay(varargin)
            %% CREATEDECAY
            %  @param scid is mlpet.IScanIdentifier.
            
            ip = inputParser;
            addRequired(ip, 'scid', @(x) isa(x, 'mlpet.IScanIdentifier'));
            parse(ip, varargin{:});
            
            obj = mlpet.XlsxAdapter.CreateDecay(varargin{:});
            error('mlpet:NotImplementedError');
        end
        
        function obj = CreateBloodSuckerData(varargin)
            error('mlpet:NotImplementedError');
        end
        function obj = CreateCapracData(varargin)
            error('mlpet:NotImplementedError');
        end
        function obj = CreateTwiliteData(varargin)
            error('mlpet:NotImplementedError');
        end
        function obj = CreateBiographMMRData(varargin)
            error('mlpet:NotImplementedError');
        end
        function obj = CreateEcatExactHRPlusData(varargin)
            error('mlpet:NotImplementedError');
        end
    end
    
	methods 
		  
 		function this = DataAdapter(varargin)
 			%% DATAADAPTER
 			%  @param .

 			
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

