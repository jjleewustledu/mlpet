classdef Test_O15Builder < MyTestCase
	%% TEST_O15BUILDER 
	%  Usage:  >> runtests tests_dir 
	%          >> runtests mlpet_xunit.Test_O15Builder % in . or the matlab path
	%          >> runtests mlpet_xunit.Test_O15Builder:test_nameoffunc
	%          >> runtests(mlpet_xunit.Test_O15Builder, Test_Class2, Test_Class3, ...)
	%  See also:  package xunit

	%  $Revision: 2314 $
 	%  was created $Date: 2013-01-12 17:53:38 -0600 (Sat, 12 Jan 2013) $
 	%  by $Author: jjlee $, 
 	%  last modified $LastChangedDate: 2013-01-12 17:53:38 -0600 (Sat, 12 Jan 2013) $
 	%  and checked into repository $URL: file:///Users/jjlee/Library/SVNRepository_2012sep1/mpackages/mlfsl/test/+mlfsl_xunit/trunk/Test_O15Builder.m $, 
 	%  developed on Matlab 8.0.0.783 (R2012b)
 	%  $Id: Test_O15Builder.m 2314 2013-01-12 23:53:38Z jjlee $
 	%  N.B. classdef (Sealed, Hidden, InferiorClasses = {?class1,?class2}, ConstructOnLoad)

	properties
 		% N.B. (Abstract, Access=private, GetAccess=protected, SetAccess=protected, Constant, Dependent, Hidden, Transient)
 	end

	methods 
 		% N.B. (Static, Abstract, Access='', Hidden, Sealed) 

 		function test_afun(this) 
 			import mlfsl.*; 
 		end 
 		function this = Test_O15Builder(varargin) 
 			this = this@TestCase(varargin{:}); 
 		end% ctor 
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

