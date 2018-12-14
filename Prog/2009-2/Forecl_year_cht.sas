/**************************************************************************
 Program:  Forecl_qtr_cht.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  04/25/09
 Version:  SAS 9.1
 Environment:  Windows
 
 Description:  Create data for quarterly foreclosure chart
(inventory, starts, sales).

 Modifications:
**************************************************************************/

%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";
***%include "C:\DCData\SAS\Inc\Stdhead.sas";

** Define libraries **;
%DCData_lib( HsngMon )


** Summarize data for chart **;

proc summary data=HsngMon.Foreclosures_year_2009_2 nway;
  where ui_proptype in ( '10', '11' );
  class report_dt;
  var in_foreclosure_beg foreclosure_start foreclosure_sale distressed_sale foreclosure_avoided;
  output out=Chart (drop=_type_ _freq_) sum=;
run;

data Chart;

  retain report_dt foreclosure_rate;

  set Chart;
  
  foreclosure_rate = 100 * foreclosure_sale / in_foreclosure_beg;
  
run;

proc print data=Chart;
  id report_dt;
run;

filename fexport "&_dcdata_path\HsngMon\Prog\2009-2\Foreclosures_year.csv" lrecl=1000;

proc export data=Chart
    outfile=fexport
    dbms=csv replace;

run;

filename fexport clear;


run;
