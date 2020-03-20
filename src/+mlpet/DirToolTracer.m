classdef DirToolTracer
	%% DIRTOOLTRACER provides globbing of folders bearing notation FOLDER_EXPRESSION.

	%  $Revision$
 	%  was created 06-Mar-2019 17:30:17 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.5.0.1049112 (R2018b) Update 3 for MACI64.  Copyright 2019 John Joowon Lee.
 	
	properties (Constant)
 		FOLDER_EXPRESSION = '(?<tracer>\w+)_(?<dt>DT\d+(|\.\d+))\-Converted\-(?<ac>[ACN]+)'
    end
    
    properties (Dependent)
        acTag
        itsPath
        itsListing
    end
    
    methods (Static)
        function ac = folder2ac(s)
            assert(ischar(s));            
            re = regexp(s, mlpet.DirToolTracer.FOLDER_EXPRESSION, 'names');
            ac = strcmpi(re.ac, 'AC');
        end
        function dt = folder2datetime(s)
            assert(ischar(s));            
            re = regexp(s, mlpet.DirToolTracer.FOLDER_EXPRESSION, 'names');
            s = re.dt(3:end);
            if (contains(s, '.'))
                cs = strsplit(s, '.');
                s = cs{1};
            end
            dt = datetime([s(1:8) 'T' s(9:end)], 'TimeZone', mlpipeline.ResourcesRegistry.instance().preferredTimeZone);
        end
        function tr = folder2tracer(s)
            assert(ischar(s));            
            re = regexp(s, mlpet.DirToolTracer.FOLDER_EXPRESSION, 'names');
            if (~isempty(re))
                tr = re.tracer;
            else
                tr = '';
            end
        end
        function tf = isfolder(s)
            assert(ischar(s));            
            re = regexp(s, mlpet.DirToolTracer.FOLDER_EXPRESSION, 'names');
            tf = ~isempty(re);
        end
    end

	methods 
        
        %% GET
        
        function g = get.acTag(this)
            if (isempty(this.ac_))
                g = '*';
                return
            end
            if (this.ac_)
                g = 'AC';
            else
                g = 'NAC';
            end
        end
        function g = get.itsPath(this)
            g = this.dirtools_.itsPath;
        end
        function g = get.itsListing(this)
            g = this.dirtools_.itsListing;
        end
        
        %%
        
        function dt  = datetime(this, varargin)
            ip = inputParser;
            addOptional(ip, 'obj', this.fqdns, @(x) iscell(x) || ischar(x));
            parse(ip, varargin{:});
            obj = ip.Results.obj;
            
            if (iscell(obj))
                dt = cellfun(@(x) this.datetime(x), obj);
                return
            end
            
            % base case
            if (ischar(obj))
                re = this.regexp_names(obj);
                try
                    dt = datetime( ...
                        re.dt(3:end), 'InputFormat', 'yyyyMMddHHmmss.SSSSSS', ...
                        'TimeZone', mlpipeline.ResourcesRegistry.instance().preferredTimeZone);
                catch ME
                    handwarning(ME);
                    if (strcmp(ME.identifier, 'MATLAB:datetime:ParseErr'))
                        dt = datetime( ...
                            re.dt(3:end), 'InputFormat', 'yyyyMMdd', ...
                            'TimeZone', mlpipeline.ResourcesRegistry.instance().preferredTimeZone);
                    end
                end
            end
        end
        function ff  = fqdns(this, varargin)
            ff = this.dirtools_.fqdns(varargin{:});
        end
        function ff  = dns(this, varargin)
            ff = this.dirtools_.dns(varargin{:});
        end
        function ff  = fqfns(this, varargin)
            ff = this.dirtools_.fqfns(varargin{:});
        end
        function ff  = fns(this, varargin)
            ff = this.dirtools_.fns(varargin{:});
        end
        function len = length(this)
            len = this.dirtools_.length;
        end
        function re  = regexp_names(this, s)
            assert(ischar(s));
            re = regexp(s, this.FOLDER_EXPRESSION, 'names');
        end
		  
 		function this = DirToolTracer(varargin)
 			%% DIRTOOLTRACER
 			%  @param tracer is char; may include path preceding a tracer identifer as well as asterisks for globbing,
            %  e. g., /path/to/FDG*.
            %  @param ac is logical
            %  @return object with subset functionality of mlsystem.DirTool.

            ip = inputParser;
            addParameter(ip, 'tracer', '', @(x) ischar(x) || iscell(x));
            addParameter(ip, 'ac', [], @(x) ischar(x) || islogical(x) || isempty(x));
            parse(ip, varargin{:});
            if (ischar(ip.Results.ac))
                this.ac_ = strcmpi('AC', ip.Results.ac);
            end    
            if (islogical(ip.Results.ac))
                this.ac_ = ip.Results.ac;
            end     
            this.dirtools_ = mlsystem.DirTools(this.tracersToGlob(ip.Results.tracer));
 		end
    end
    
    %% PRIVATE
    
    properties (Access = private)
        ac_
        dirtools_
    end
    
    methods (Access = private)
        function e = tracersToGlob(this, e)
            %% adds terminal asterisk for use in globbing
            
            if (iscell(e))
                for ie = 1:length(e)
                    e{ie} = this.tracersToGlob(e{ie});
                end
                return
            end
            
            % base case
            assert(ischar(e));
            if (~contains(e, '*'))
                e = [e '*'];
            end
            if (islogical(this.ac_) && ~contains(e, this.acTag))
                e = [e '-' this.acTag];
            end
            e = {e};
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

