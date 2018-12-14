/**************************************************************************
 Program:  temp.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  08/30/06
 Version:  SAS 8.2
 Environment:  Windows
 
 Description:

 Modifications:
**************************************************************************/

%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";

** Define libraries **;
%DCData_lib( HUD )

proc print data=Hud.Sec8mf_current_dc_jul06;
  where contract_number = 'DC39Q971001';

run;
