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
 	
    methods (Abstract)
        obj = doMakeClass(this)
    end
    
    properties (Dependent)
        preferredTimeZone
    end
    
    methods (Static)
        function this = instance()
            persistent uniqueInstance
            if isempty(uniqueInstance)
                this = mlpet.InstrumentKit();
                uniqueInstance = this;
            else
                this = uniqueInstance;
            end
        end
        
        function rm  = createRadMeasurements(varargin)
            %% CREATERADMEASUREMENTS
 			%  @param session is mlraichle.Session.
            %  @return mlraichle.RadMeasurements.
            
            ip = inputParser;
            addParameter(ip, 'session', [], @(x) isa(x, 'mlraichle.Session'));
            parse(ip, varargin{:});
            rm = mlraichle.CCIRRadMeasurements.createBySession(ip.Results.session);
        end
        function rs  = createReferenceSources(varargin)
            %% CREATEREFERENCESOURCES
 			%  @param session is mlraichle.Session.
            %  @return mlpet.ReferenceSource.
            
            ip = inputParser;
            addParameter(ip, 'session', [], @(x) isa(x, 'mlraichle.Session'));
            parse(ip, varargin{:});
            
            import mlpet.ReferenceSource;
            import mlpet.InstrumentKit;
            rs(1) = ReferenceSource( ...
                'isotope', '137Cs', ...
                'activity', 500, ...
                'activityUnits', 'nCi', ...
                'sourceId', '1231-8-87', ...
                'refDate', datetime(2007,4,1, 'TimeZone', InstrumentKit.preferredTimeZone));
            if (datetime(ip.Results.session) > datetime(2016,4,7, 'TimeZone', 'America/Chicago'))
                rs(2) = ReferenceSource( ...
                    'isotope', '22Na', ...
                    'activity', 101.4, ...
                    'activityUnits', 'nCi', ...
                    'sourceId', '1382-54-1', ...
                    'refDate', datetime(2009,8,1, 'TimeZone', InstrumentKit.preferredTimeZone));
            end
            if (datetime(ip.Results.session) > datetime(2018,10,4, 'TimeZone', 'America/Chicago'))
                rs(3) = ReferenceSource( ...
                    'isotope', '68Ge', ...
                    'activity', 101.3, ...
                    'activityUnits', 'nCi', ...
                    'sourceId', '1932-53', ...
                    'refDate', datetime(2017,11,1, 'TimeZone', InstrumentKit.preferredTimeZone), ...
                    'productCode', 'MGF-068-R3');
            end
            for irs = 1:length(rs)
                assert(datetime(ip.Results.session) > rs(irs).refDate);
            end
        end
        function obj = prepareCapracDevice(varargin)
 			%% PREPARECAPRACDEVICE instantiates the InstrumentKit with the device then calibrates the device.
 			%  @param session is mlraichle.Scan.
            
            import mlraichle.*;
            this = InstrumentKit(varargin{:});
            obj  = CapracDevice( ...
                'radMeasurements',  this.createRadMeasurements( 'session', this.sessionData_), ...
                'referenceSources', this.createReferenceSources('session', this.sessionData_));
            try
                obj = obj.calibrateDevice;
            catch ME
                handexcept(ME, ...
                    'mlraichle:RunTimeError', ...
                    'InstrumentKit.prepareCapracDevice could not calibrate the device');
            end
        end
        function obj = prepareTwiliteDevice(varargin)
            import mlraichle.*;
            this = InstrumentKit(varargin{:});
            obj  = TwiliteDevice('radMeasurements', this.createRadMeasurements('session', this.sessionData_));
            try
                obj = obj.calibrateDevice(this.twiliteCalMeasurements);
            catch ME
                handexcept(ME, ...
                    'mlraichle:RunTimeError', ...
                    'InstrumentKit.prepareTwiliteDevice could not calibrate the device');
            end
        end
        function obj = prepareBiographMMRDevice(varargin)
            import mlraichle.*;
            this = InstrumentKit(varargin{:});
            obj  = BiographMMRDevice('radRadMeasurements', this.createRadMeasurements('session', this.sessionData_));
            try
                obj = obj.calibrateDevice(this.biographMMRCalMeasurements);
            catch ME
                handexcept(ME, ...
                    'mlraichle:RunTimeError', ...
                    'InstrumentKit.prepareBiographMMRDevice could not calibrate the device');
            end
        end
        function obj = prepareBloodSuckerDevice(varargin)
            obj = [];
        end
        function obj = prepareEcatExactHRPlusDevice(varargin)
            obj = [];
        end
    end
    
    methods    
        
        %% GET
        
        function g = get.preferredTimeZone(~)
            g = mlpipeline.ResourcesRegistry.instance().preferredTimeZone;
        end
        
        %%
        
        function m  = twiliteCalMeasurements(this)
        end
        function m  = biographMMRCalMeasurements(this)
        end
        function dt = datetime(this)
            dt = datetime(this.sessionData_);
        end
    end
    
    %% PRIVATE
    
    properties (Access = private)
        radMeasurements_
        sessionData_
    end
    
    methods (Access = private) 		
 		function this = InstrumentKit(varargin)
 			%% INSTRUMENTKIT
 			%  @param session is mlraichle.Session.
            
            ip = inputParser;
            addParameter(ip, 'sessionData', [], @(x) isa(x, 'mlpipeline.ISessionData'));
            parse(ip, varargin{:});
            this.sessionData_ = ip.Results.sessionData;
            this.radMeasurements_ = mlraichle.CCIRRadMeasurements.createBySession(this.sessionData_);
 		end	 
    end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

