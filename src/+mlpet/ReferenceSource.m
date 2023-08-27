classdef ReferenceSource 
	%% REFERENCESOURCE  

	%  $Revision$
 	%  was created 22-Oct-2018 03:12:21 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
    properties (Constant)
        SUPPORTED_UNITS = {'nCi' 'uCi' 'mCi' 'Ci' 'Bq' 'kBq' 'MBq' 'kdpm' 'dpm'}
        BASE_UNITS = {'Ci' 'Bq' 'dpm'}
    end
    
	properties (SetAccess = private)
 		isotope
        activity
        activityUnits
        sourceId
        refDate
        manufacturer
        productCode
    end
    
    methods (Static)
        function a = convertUnits(a, fromUnits, toUnits)
            %  CONVERTUNITS
            %  @param required a is numeric.
            %  @param required fromUnits is char in SUPPORTED_UNITS.
            %  @param required   toUnits is char in SUPPORTED_UNITS.
            %  @return a is numeric.
            
            import mlpet.*; %#ok<NSTIMP>
            SU = ReferenceSource.SUPPORTED_UNITS;
            assert(any(contains(SU, fromUnits)), 'mlpet:ValueError', 'ReferenceSource.convertUnits');
            assert(any(contains(SU,   toUnits)), 'mlpet:ValueError', 'ReferenceSource.convertUnits');
            
            if (strcmp(fromUnits, toUnits))
                return
            end            
            [fromN,fromU] = reduce_(fromUnits);
            [  toN,  toU] = reduce_(  toUnits);
              renN        = rename_(fromU, toU);
            a = a*(fromN/toN)*renN;
            
            function [n_,u_] = reduce_(u_)
                n_ = 1;
                switch (u_(1))
                    case 'n'
                        n_ = 1e-9;
                        u_ = u_(2:end);
                    case 'u'
                        n_ = 1e-6;
                        u_ = u_(2:end);
                    case 'm'
                        n_ = 1e-3;
                        u_ = u_(2:end);
                    case 'k'
                        n_ = 1e3;
                        u_ = u_(2:end);
                    case 'M'
                        n_ = 1e6;
                        u_ = u_(2:end);
                end
            end
            function  [n_,tu_] = rename_(fu_, tu_)
                import mlpet.*; 
                BU = ReferenceSource.BASE_UNITS;
                assert(any(contains(BU, fu_)), 'mlpet:ValueError', 'ReferenceSource.convertUnits.reduce_');
                assert(any(contains(BU, tu_)), 'mlpet:ValueError', 'ReferenceSource.convertUnits.reduce_');
                
                Ci  = [1         37e9 2.22e12]';
                Bq  = [1/37e9    1    60]';
                dpm = [1/2.22e12 1/60 1]';
                tbl = table(Ci, Bq, dpm, 'RowNames', {'Ci' 'Bq' 'dpm'});
                n_  = tbl{tu_, fu_};
            end
        end
        function this = create(s)
            if isstruct(s)
                try
                    this = mlpet.ReferenceSource( ...
                        isotope=s.isotope, ...
                        activity=s.activity, ...
                        sourceId=s.sourceId, ...
                        refDate=s.refDate, ...
                        productCode=s.productCode);
                    return
                catch ME
                    handexcept(ME)
                end
            end
            if isdatetime(s)
                try
                    this = mlpet.ReferenceSource.createFromDatetime(s);
                    return
                catch ME
                    handexcept(ME)
                end
            end
            error('mlpet:TypeError', '%s: class(s)->%s', stackstr(), class(s))
        end
        function this = createFromDatetime(dt)
            arguments
                dt datetime = datetime('now')
            end
            import mlpet.ReferenceSource;

            tz = 'local';
            this = ReferenceSource( ...
                'isotope', '137Cs', ...
                'activity', 500, ...
                'activityUnits', 'nCi', ...
                'sourceId', '1231-8-87', ...
                'refDate', datetime(2007,4,1, 'TimeZone', tz));
            if dt >= datetime(2016,4,7, 'TimeZone', tz) && ...
                    dt < datetime(2018,9,11, 'TimeZone', tz)
                this = ReferenceSource( ...
                    'isotope', '22Na', ...
                    'activity', 101.4, ...
                    'activityUnits', 'nCi', ...
                    'sourceId', '1382-54-1', ...
                    'refDate', datetime(2009,8,1, 'TimeZone', tz));
            end
            if dt >= datetime(2018,9,11, 'TimeZone', tz) && ...
                    dt < datetime(2022,2,1, 'TimeZone', tz)
                this = ReferenceSource( ...
                    'isotope', '68Ge', ...
                    'activity', 101.3, ...
                    'activityUnits', 'nCi', ...
                    'sourceId', '1932-53', ...
                    'refDate', datetime(2017,11,1, 'TimeZone', tz), ...
                    'productCode', 'MGF-068-R3');
            end
            if dt > datetime(2022,2,1, 'TimeZone', tz)
                this = ReferenceSource( ...
                    'isotope', '68Ge', ...
                    'activity', 0.1052, ...
                    'activityUnits', 'uCi', ...
                    'sourceId', '2277-57', ...
                    'refDate', datetime(2022,2,1, 'TimeZone', tz), ...
                    'productCode', 'GF-068-R3');
            end
        end
        function this = createFromTag(tag)
            arguments
                tag {mustBeTextScalar} = ""
            end
            import mlpet.ReferenceSource;

            tz = 'local';
            switch tag
                case "Tu NIST"
                    this = ReferenceSource( ...
                        'isotope', '68Ge', ...
                        'activity', 0.111, ...
                        'activityUnits', 'uCi', ...
                        'refDate', datetime(2021,11,10, 'TimeZone', tz));
                case "Tu new"
                    this = ReferenceSource( ...
                        'isotope', '68Ge', ...
                        'activity', 0.1125, ...
                        'activityUnits', 'uCi', ...
                        'refDate', datetime(2023,6,7, 'TimeZone', tz));
                case "PCIF new"
                    this = ReferenceSource( ...
                        'isotope', '68Ge', ...
                        'activity', 0.1174, ...
                        'activityUnits', 'uCi', ...
                        'refDate', datetime(2023,6,7, 'TimeZone', tz));
                otherwise
                    this = ReferenceSource();
            end
        end
    end

	methods        
        function dc = decayCorrection(this, targetDatetime)
            arguments
                this mlpet.ReferenceSource
                targetDatetime datetime
            end

            dc = 1 ./ 2.^(days(targetDatetime - this.refDate)/this.halflifeDays);
        end
        function d = halflifeDays(this)
            d = mlpet.Radionuclides.halflifeOf(this.isotope)/86400; % sec->days
        end
        function tf = isempty(this)
            % recursion
            if (length(this) > 1)
                tf = true;
                for it = 1:length(this)
                    tf = tf && isempty(this(1));
                end
                return
            end
            
            % base case
            tf = isempty(this.isotope) || ...
                 isempty(this.activity) || ...
                 isempty(this.activityUnits) || ...
                 isempty(this.sourceId) || ...
                 isempty(this.refDate);
        end
        function a = predictedActivity(this, targetDatetime, targetActivityUnits)
            arguments
                this mlpet.ReferenceSource
                targetDatetime datetime
                targetActivityUnits {mustBeTextScalar}
            end

            a = this.activity ./ 2.^(days(targetDatetime - this.refDate)/this.halflifeDays);
            a = this.convertUnits(a, this.activityUnits, targetActivityUnits);            
        end
		  
 		function this = ReferenceSource(varargin)
 			%% REFERENCESOURCE
 			%  @param isotope is char.
            %  @param activity is numeric.
 			%  @param activityUnits is char.
 			%  @param sourceId is char.
 			%  @param refDate is datetime.
 			%  @param manufacturer is char.
 			%  @param productCode is char.

 			ip = inputParser;
            addParameter(ip, 'isotope', '', @ischar);
            addParameter(ip, 'activity', [], @isnumeric);
            addParameter(ip, 'activityUnits', '', @ischar);
            addParameter(ip, 'sourceId', '', @ischar);
            addParameter(ip, 'refDate', NaT, @isdatetime);
            addParameter(ip, 'manufacturer', 'Eckert & Ziegler', @ischar);
            addParameter(ip, 'productCode', '', @ischar);
            parse(ip, varargin{:});
            this.isotope       = ip.Results.isotope;
            this.activity      = ip.Results.activity;
            this.activityUnits = ip.Results.activityUnits;
            this.sourceId      = ip.Results.sourceId;
            this.refDate       = ip.Results.refDate;
            this.manufacturer  = ip.Results.manufacturer;
            this.productCode   = ip.Results.productCode;
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

