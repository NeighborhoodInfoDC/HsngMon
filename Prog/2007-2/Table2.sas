/**************************************************************************
 Program:  Table2.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  11/03/06
 Version:  SAS 8.2
 Environment:  Windows with SAS/Connect
 
 Description:  Table 2. Real Estate Listing Trends by Housing Type,
 Washington, D.C.

 Modifications:
  11/26/06 PAT  Changed time groupings to resemble table 1.
**************************************************************************/

%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";
***%include "C:\DCData\SAS\Inc\Stdhead.sas";
*%include "K:\Metro\PTatian\DCData\SAS\Inc\AlphaSignon.sas" /nosource2;

** Define libraries **;
%DCData_lib( HsngMon )

%let path = &_dcdata_path\HsngMon\Reports\2007-2;
%let workbook = DC Housing Monitor Spring 2007 tables.xls;
%let sheet = Table 2;
%let start_dt = '01jan1997'd;
%let end_dt = '01jan2007'd;

proc format;
    
  /** Date ranges for labeling median sales price **/
  value lblA 
    '01oct2006'd -< '01jan2007'd = '2006 Q4'
    '01jul2006'd -< '01oct2006'd = '2006 Q3'
    '01apr2006'd -< '01jul2006'd = '2006 Q2'
    '01jan2006'd -< '01apr2006'd = '2006 Q1'
    '01jan2005'd - '31dec2005'd = '2005'
    '01jan2001'd - '31dec2004'd = '2001-2004'
    '01jan1997'd - '31dec2000'd = '1997-2000';
    
   value na
     .n = 'n/a';

run;

** Create table data **;

ods output table=Table2;

proc tabulate data=HsngMon.MRIS_monthly_dc format=comma10. noseps missing;
  where &start_dt <= month < &end_dt;
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
  format month lblA. /*year.*/;
  title2 "MRIS monthly real estate trend indicators, Washington, D.C.";

run;

ods output close;

run;

proc sort data=Table2;
  by descending month;

%File_info( data=Table2 )


** Write to output table **;

filename xlsFile dde "excel|&path\[&workbook]&sheet!r10c2:r16c9" lrecl=1000 notab;

data _null_;

  set Table2;
  
  ** Supress time on market data before 2001 **;
  
  if year( month ) < 2001 then do;
    pct_mkt_60_Mean = .n;
    pct_mkt_90_Mean = .n;
    pct_mkt_120_Mean = .n;
  end;
  
  file xlsFile;
  
  length xmonth $ 40;
  
  xmonth = put( month, lblA. );
  
  put xmonth '09'x @;
  
  put listings_sf_Mean '09'x list_sale_sf_Mean '09'x @;

  put listings_condo_Mean '09'x list_sale_condo_Mean '09'x @;
  
  put pct_mkt_60_Mean na. '09'x pct_mkt_90_Mean na. '09'x pct_mkt_120_Mean na.;

run;

