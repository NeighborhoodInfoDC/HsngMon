/**************************************************************************
 Program:  Who_owns.sas
 Library:  RealProp
 Project:  DC Data Warehouse
 Author:   P. Tatian
 Created:  10/23/06
 Version:  SAS 9.1
 Environment:  Alpha
 
 Description:  List of owners for Who Owns the Neighborhood analysis.

 Modifications:
**************************************************************************/

%include "[Dcdata]Stdhead.sas";

** Define libraries **;
%DCData_lib( RealProp )

*options obs=100;

proc freq data=RealProp.Ownerpt_2001_10a;
  table ownername / nocum nopercent;
run;

