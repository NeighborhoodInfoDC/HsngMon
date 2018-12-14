/**************************************************************************
 Program:  Assisted_units_vouchers.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  12/06/07
 Version:  SAS 9.1
 Environment:  Windows
 
 Description:  Create total of housing vouchers by ward.

 Modifications:
**************************************************************************/

%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";

** Define libraries **;
%DCData_lib( HsngMon )
%DCData_lib( HUD )

proc tabulate data=Hud.Vouchers_sum_wd02 format=comma8.0 noseps missing;
  class ward2002;
  var Total_2004;
  table 
    /** Columns **/
    Total_2004 * ( all='Total' ward2002 ) * sum=' '
  ;

run;
