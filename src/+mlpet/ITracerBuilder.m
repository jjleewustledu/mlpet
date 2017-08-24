classdef ITracerBuilder 
	%% ITRACERBUILDER  
    %  @param buildVisitor is, e.g., mlfourdfp.FourdfpVisitor.
    %  @param compositeResolveBuilder is, e.g., mlfourdfp.CompositeT4ResolveBuilder.
    %  @param resolveBuilder is an mlfourdfp.AbstractT4ResolveBuilder.
    %  @param resolveTag is char.
    %  @param roisBuilder is an mlrois.IRoisBuilder.

	%  $Revision$
 	%  was created 30-Jul-2017 16:39:30 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2017 John Joowon Lee.
 	
	
    properties (Abstract)
        buildVisitor
        compositeResolveBuilder
        resolveBuilder
        roisBuilder
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

