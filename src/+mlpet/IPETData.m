classdef IPETData
	%% IPETDATA  

	%  $Revision$
 	%  was created 08-Jun-2016 17:48:45
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.0.0.341360 (R2016a) for MACI64.
 	
    
	methods (Abstract)
        % accept parameter 'type', {'folder' 'path'}
        f = hdrinfoLocation(this, ~)
        f = petLocation(    this, ~)
        f = petObject(      this, ~)
        f = scanLocation(   this, ~)
        
        % accept parameter 'type', {'filename' 'fn' 'fqfn' 'fileprefix' 'fp' 'fqfp' 'folder' 'path' 'ext' 'imagingContext'}
        f = ct(  this, ~)
        f = fdg( this, ~)
        f = gluc(this, ~)
        f = ho(  this, ~)
        f = oc(  this, ~)
        f = oo(  this, ~)
        f = tr(  this, ~)
        f = umap(this, ~)
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

