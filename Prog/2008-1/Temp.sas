/**************************************************************************
 Program:  Temp.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  02/13/08
 Version:  SAS 9.1
 Environment:  Windows
 
 Description:

 Modifications:
**************************************************************************/

%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";

** Define libraries **;
%DCData_lib( HsngMon )
%DCData_lib( RealProp )

proc print data=HsngMon.Assisted_units_own;
  where OwnerCat = '100';
  id NLIHC_ID;
  sum mid_asst_units;
  var ui_proptype progcat ward2002 mid_asst_units Proj_Addr_ref premiseadd_std Proj_Name ownername OwnerDC OwnerCat;
  format OwnerCat $OwnCat.;
  title2 'Housing owned by religious entities';
  
run;

