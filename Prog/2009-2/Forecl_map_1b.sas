/**************************************************************************
 Program:  Forecl_map_1b.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  05/04/09
 Version:  SAS 9.1
 Environment:  Windows
 
 Description:  Create file with x-y coordinates of new foreclosure
starts for 2008.

 Modifications:
**************************************************************************/

%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";

** Define libraries **;
%DCData_lib( HsngMon )

data HsngMon.Map1b_2009_2 (compress=no);

  set HsngMon.Foreclosures_year_2009_2;
  
  where ui_proptype in ( '10', '11' ) and foreclosure_start and year( report_dt ) = 2008;
  
  keep ssl x_coord y_coord start_dt ui_proptype;

run;

proc print data=HsngMon.Map1b_2009_2 (Obs=100);
  
