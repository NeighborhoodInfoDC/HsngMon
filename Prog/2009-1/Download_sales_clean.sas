/**************************************************************************
 Program:  Download_sales_clean.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  11/22/07
 Version:  SAS 9.1
 Environment:  Windows with SAS/Connect
 
 Description:  Download latest sales data for Housing Monitor report.

 Modifications:
  10/06/07 PAT Changed sale selection to include 3 qtrs prior to sales
               start date (needed for ward 4-qtr moving avg chart).
  11/20/07 PAT Added table for Pct. Owner-Occ. by year to check missing. 
**************************************************************************/

%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";
%include "K:\Metro\PTatian\DCData\SAS\Inc\AlphaSignon.sas" /nosource2;

** Define libraries **;
%DCData_lib( HsngMon )
%DCData_lib( RealProp )

%Init_macro_vars( rpt_yr=2009, rpt_qtr=1 )

%let data = Sales_res_clean;
%let out  = Sales_clean_&g_rpt_yr._&g_rpt_qtr;

%syslput data=&data;
%syslput out=&out;
%syslput start_dt=&g_sales_start_dt;
%syslput end_dt=&g_sales_end_dt;
%syslput g_rpt_title=&g_rpt_title;
%syslput g_sales_end_yr=&g_sales_end_yr;

** Start submitting commands to remote server **;

rsubmit;

*options obs=100;

data &out (label="Clean property sales for &g_rpt_title Housing Monitor" compress=no);

  set RealProp.&data;
  where intnx( 'qtr', &start_dt, -3, 'beginning' ) <= saledate <= &end_dt;
  
  saledate_yr = year( saledate );
  
  %dollar_convert( saleprice, saleprice_adj, saledate_yr, &g_sales_end_yr )
  
  pct_owner_occ_sale = 100 * owner_occ_sale;

  label
    saledate_yr = "Property sale year"
    saleprice_adj = "Property sale price (&g_sales_end_yr $)"
    pct_owner_occ_sale = "Pct. owner-occupied sale";

  keep ssl saleprice saledate ui_proptype ward2002 cluster_tr2000 saledate_yr owner_occ_sale
       saleprice_adj pct_owner_occ_sale ;

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

proc tabulate data=HsngMon.&out missing noseps;
  var pct_owner_occ_sale;
  class saledate_yr;
  table all='Total' saledate_yr=' ', pct_owner_occ_sale * (n nmiss mean);
run;

proc compare base=HsngMon.sales_clean_2009_1_old compare=HsngMon.sales_clean_2009_1 maxprint=(40,32000);
  id ssl saledate;

run;

signoff;
