/**************************************************************************
 Program:  Download_sales_clean.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  02/12/07
 Version:  SAS 9.1
 Environment:  Windows with SAS/Connect
 
 Description:  Download latest sales data for Housing Monitor report.

 Modifications:
**************************************************************************/

%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";
%include "K:\Metro\PTatian\DCData\SAS\Inc\AlphaSignon.sas" /nosource2;

** Define libraries **;
%DCData_lib( HsngMon )
%DCData_lib( RealProp )

%let data = Test_sales_12_2006;
%let out  = Sales_clean_2007_2;
%let start_dt = '01jan1995'd;
%let end_dt = '01oct2006'd;

%syslput data=&data;
%syslput out=&out;
%syslput start_dt=&start_dt;
%syslput end_dt=&end_dt;

** Start submitting commands to remote server **;

rsubmit;

*options obs=100;

data &out (compress=no);

  set RealProp.&data;
  where &start_dt <= saledate < &end_dt;
  
  keep ssl saleprice saledate ui_proptype ward2002 cluster_tr2000 saledate_yr owner_occ_sale;

run;

proc download status=no
  data=&out 
  out=HsngMon.&out;

run;

endrsubmit;

** End submitting commands to remote server **;

%file_info( data=HsngMon.&out, printobs=20, 
            freqvars=ward2002 cluster_tr2000 ui_proptype saledate_yr owner_occ_sale )

proc freq data=HsngMon.&out;
  tables saledate;
  format saledate yyq.;

run;

signoff;
