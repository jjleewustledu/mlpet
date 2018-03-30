classdef Bloodxlsx < mlpet.IBloodData
	%% BLOODXLSX   

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.5.0.197613 (R2015a) 
 	%  $Id$  	 

	properties 
 		 xlsxFilename
         sheetLabel
         dryWeight  % as col vector
         wetWeight  % as col vector         
         drawn
         drawnMin   % as col vector
         drawnSec   % as col vector
         counted
         countedMin % as col vector
         countedSec % as col vector
         counts     % as col vector
         nSyringes         
         variableCountTime % as col vector
         
         pNumber = ''
         scanDate = ''
         scanIndex = nan
         scanType = nan
    end 

	methods 		  
 		function this = Bloodxlsx(varargin) 
 			%% BLOODXLSX 
 			%  Usage:  this = Bloodxlsx(xlsx_filename) 

            ip = inputParser;
            addRequired(ip, 'xlsxFilename', @(x) lexist(x, 'file') && lstrfind(x, '.xlsx'));
            addOptional(ip, 'sheetLabel', 'Sheet1', @ischar);
            parse(ip, varargin{:});
            
            this.xlsxFilename = ip.Results.xlsxFilename;
            this.sheetLabel   = ip.Results.sheetLabel;
            [num,txt]         = xlsread(this.xlsxFilename, this.sheetLabel); %#ok<ASGLU>
            %fprintf('mlpet.Bloodxlsx found cell-labels:\n%s\n', cell2str(txt', 'AsRow', true, 'WithQuotes', true));

            this.dryWeight  = num(2:end,1);
            this.wetWeight  = num(2:end,2);
            this.drawnMin   = num(2:end,3);
            this.drawnSec   = num(2:end,4);
            this.countedMin = num(2:end,5);
            this.countedSec = num(2:end,6);
            this.counts     = num(2:end,7);
            this.nSyringes  = size(num,1) - 1;
            
            this = this.parseFilename;
 		end 
    end 
    
    methods (Access = 'private')
        function this = parseFilename(this)
            try
                expr = '(?<pnum>p\d\d\d\d)(?<tracer>[a-z]+)(?<sidx>\d)\w+.xlsx';
                names = regexp(this.xlsxFilename, expr, 'names');
                this.pNumber = names.pnum;
                this.scanIndex = str2double(names.sidx);
                switch (names.tracer)
                    case 'gluc'
                        this.scanType = 10;
                    case 'ho'
                        this.scanType = 2;
                    case {'oc' 'co'}
                        this.scanType = 3;
                    case 'oo'
                        this.scanType = 1;
                    case 'bu'
                        this.scanType = 4;
                    case 'sp'
                        this.scanType = 5;
                    case 'xx'
                        this.scanType = 6;
                end
            catch ME
                handwarning(ME);
            end
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

