/**************************************************************************
 Program:  Table1.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  08/07/06
 Version:  SAS 8.2
 Environment:  Windows with SAS/Connect
 
 Description:  Table 1. Real Estate Listing Trends by Housing Type,
 Washington, D.C.

 Modifications:
**************************************************************************/

%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";
*%include "K:\Metro\PTatian\DCData\SAS\Inc\AlphaSignon.sas" /nosource2;

** Define libraries **;
%DCData_lib( HsngMon )

%let path = D:\DCData\Libraries\HsngMon\Reports\2006-3;
%let workbook = DC Housing Monitor Fall 2006 tables.xls;
%let sheet = Table 1;

proc format;
  value $yearq
    '2006' = '2006 Q1-Q2';
    
run;

** Create table data **;

ods output table=Table1;

proc tabulate data=HsngMon.MRIS_monthly_dc format=comma10. noseps missing;
  class month;
  var listings_condo listings_sf listings_tot
      sales_condo sales_sf sales_tot;
  var pct_mkt_60 pct_mkt_90 pct_mkt_120 / weight=sales_tot;
  var list_sale_condo / weight=sales_condo;
  var list_sale_sf / weight=sales_sf;
  var list_sale_tot / weight=sales_tot;
  table
    month,
    n='Months of data'
    mean='Avg. listings/month' * 
      ( listings_tot='Total' listings_sf='SF' listings_condo='Condo' )
    sum='Total sales' *
      ( sales_tot='Total' sales_sf='SF' sales_condo='Condo' )
    mean='Listing to sale ratio' *
      ( list_sale_tot='Total' list_sale_sf='SF' list_sale_condo='Condo' ) * f=comma10.1
    mean='Pct. sales by time on market' *
      ( pct_mkt_60='>= 60 days' pct_mkt_90='>= 90 days' pct_mkt_120='>= 120 days' ) * f=percent10.;
  format month year.;
  title2 "MRIS monthly real estate trend indicators, Washington, D.C.";

run;

ods output close;

run;

%File_info( data=Table1 )

** Write to output table **;

filename xlsFile dde "excel|&path\[&workbook]&sheet!r10c2:r19c9" lrecl=1000 notab;

data _null_;

  set Table1;
  
  file xlsFile;
  
  length xmonth $ 40;
  
  xmonth = put( put( month, year4. ), $yearq. );
  
  put xmonth '09'x @;
  
  put listings_sf_Mean '09'x list_sale_sf_Mean '09'x @;

  put listings_condo_Mean '09'x list_sale_condo_Mean '09'x @;
  
  put pct_mkt_60_Mean '09'x pct_mkt_90_Mean '09'x pct_mkt_120_Mean ;

run;

*signoff;
