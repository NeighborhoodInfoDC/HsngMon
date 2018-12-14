/**************************************************************************
 Program:  Hmda_chart.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  08/11/06
 Version:  SAS 8.2
 Environment:  Windows
 
 Description:  HMDA new mortgage chart.

 Modifications:
**************************************************************************/

%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";

** Define libraries **;
%DCData_lib( HsngMon )

data Hmda_chart;

  set HsngMon.Hmda_city (keep=nummrtgorighomepurch_: units_sf_condo_:);
  
  newmort1995 = 100 * nummrtgorighomepurch_1995 / units_sf_condo_2001;
  newmort1996 = 100 * nummrtgorighomepurch_1996 / units_sf_condo_2001;
  newmort1997 = 100 * nummrtgorighomepurch_1997 / units_sf_condo_2001;
  newmort1998 = 100 * nummrtgorighomepurch_1998 / units_sf_condo_2001;
  newmort1999 = 100 * nummrtgorighomepurch_1999 / units_sf_condo_2001;
  newmort2000 = 100 * nummrtgorighomepurch_2000 / units_sf_condo_2001;
  newmort2001 = 100 * nummrtgorighomepurch_2001 / units_sf_condo_2001;
  newmort2002 = 100 * nummrtgorighomepurch_2002 / units_sf_condo_2002;
  newmort2003 = 100 * nummrtgorighomepurch_2003 / units_sf_condo_2003;
  newmort2004 = 100 * nummrtgorighomepurch_2004 / units_sf_condo_2004;
  
  keep newmort: ;

run;

filename fexport "D:\DCData\Libraries\HsngMon\Reports\2006-3\Hmda_chart.csv" lrecl=2000;

proc export data=Hmda_chart
    outfile=fexport
    dbms=csv replace;

run;

filename fexport clear;

