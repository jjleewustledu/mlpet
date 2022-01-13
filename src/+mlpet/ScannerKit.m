classdef (Abstract) ScannerKit < handle & mlpet.IDeviceKit
	%% SCANNERKIT 

	%  $Revision$
 	%  was created 23-Feb-2020 15:42:18 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.7.0.1296695 (R2019b) Update 4 for MACI64.  Copyright 2020 John Joowon Lee.
   
    methods (Static)
        function this = createFromSession(sesd)
            %  @param sesd is a concrete implementation of mlpipeline.ISessionData.
            %  @returns a concrete implementation of ScannerKit appropriate for the instance of ISessionData.

            switch class(sesd)
                case 'mlraichle.SessionData'
                    this = mlsiemens.BiographMMRKit.createFromSession(sesd);
                case 'mlvg.SessionData'
                    switch sesd.scannerKit
                        case 'mlsiemens.EcatExactHRPlusKit'
                            this = mlsiemens.EcatExactHRPlusKit.createFromSession(sesd);
                        case 'mlsiemens.BiographMMRKit'                            
                            this = mlsiemens.BiographMMRKit.createFromSession(sesd);
                        case 'mlsiemens.BiographVisionKit'                            
                            this = mlsiemens.BiographVisionKit.createFromSession(sesd);
                        otherwise 
                            error('mlpet:ValueError', 'ScannerKit does not support %s', sesd.scannerKit)
                    end
                case 'mlan.SessionData'
                    this = mlsiemens.BiographMMRKit.createFromSession(sesd);
                otherwise
                    error('mlpet:ValueError', 'ScannerKit does not support %s', class(sesd))
            end
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

