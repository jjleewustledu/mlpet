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
    end

	methods         
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

