classdef (Abstract) InstrumentKit < handle
	%% INSTRUMENTKIT is the AbstractFactory in an abstract factory pattern.
    %  For concrete factory subclasses see also:  
    %      mlpowers.InstrumentKit, mlarbelaez.InstrumentKit, mlraichle.InstrumentKit.  
    %  InstrumentKit's abstract products are mlpet.Instrument.  For concrete products see also:  
    %      {mlpowers, mlarbelaez, mlraichle, ....}.{BloodSuckerDevice, CapracDevice, TwiliteDevice, 
    %      BiographMMRDevice, EcatExactHRPlusDevice}.

	%  $Revision$
 	%  was created 18-Oct-2018 01:51:54 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	methods (Static)
        function rm  = CreateRadMeasurements(varargin)
            rm = [];
        end
        function obj = prepareBloodSuckerDevice(varargin)
            obj = [];
        end
        function obj = prepareCapracDevice(varargin)
            obj = [];
        end
        function obj = prepareTwiliteDevice(varargin)
            obj = [];
        end
        function obj = prepareBiographMMRDevice(varargin)
            obj = [];
        end
        function obj = prepareEcatExactHRPlusDevice(varargin)
            obj = [];
        end
    end
    
    %% PROTECTED
    
    methods (Access = protected)        
 		function this = InstrumentKit(varargin)
 		end	  
    end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

