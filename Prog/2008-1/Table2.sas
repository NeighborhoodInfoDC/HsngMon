/**************************************************************************
 Program:  Table2.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  11/22/07
 Version:  SAS 8.2
 Environment:  Windows
 
 Description:  Table 2. Real Estate Listing Trends by Housing Type,
 Washington, D.C.

 Modifications:
  11/22/07 PAT Revised Proc Tabulate output. 
               Corrected problem with truncated percents in DDE output. 
               NB: Need to manually trim "n/a" labels in Excel worksheet.
**************************************************************************/

%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";

** Define libraries **;
%DCData_lib( HsngMon )

options mprint symbolgen mlogic;

**** NB: This table uses formats for NEXT report period. ****;
%Init_macro_vars( rpt_yr=2008, rpt_qtr=1 )

%let sheet = Table 2;

proc format;
    
  /** Date ranges **/
  value lblAx 
    '01oct2007'd -< '01jan2008'd = '2007 Q4'
    '01jul2007'd -< '01oct2007'd = '2007 Q3'
    '01apr2007'd -< '01jul2007'd = '2007 Q2'
    '01jan2007'd -< '01apr2007'd = '2007 Q1'
    '01jan2006'd -< '01jan2007'd = '2006'
    '01jan2005'd -< '01jan2006'd = '2005'
    '01jan2001'd -< '01jan2005'd = '2001-2004'
    '01jan1997'd -< '01jan2001'd = '1997-2000'
    other = ' ';
   
   value na (min=5)
     .n = 'n/a';

run;

** Create table data **;

ods output table=Table2 (where=(_table_=2));

proc tabulate data=HsngMon.MRIS_monthly_dc format=comma10. noseps missing;
  where put( month, lblAx. ) ~= ' ';
  class month / descending;
  var listings_condo listings_sf listings_tot
      sales_condo sales_sf sales_tot;
  var pct_mkt_60 pct_mkt_90 pct_mkt_120 / weight=sales_tot;
  var list_sale_condo / weight=sales_condo;
  var list_sale_sf / weight=sales_sf;
  var list_sale_tot / weight=sales_tot;
  table
    month,
    n='Months of data'
    sum='Total sales' * ( sales_sf='SF' sales_condo='Condo' );
  table
    month,
    listings_sf='SF' * mean='Avg. listings/month'
    list_sale_sf='SF' * mean='Listing to sale ratio' * f=comma10.1
    listings_condo='Condo' * mean='Avg. listings/month'
    list_sale_condo='Condo' * mean='Listing to sale ratio' * f=comma10.1
    mean='Pct. sales by time on market' *
      ( pct_mkt_60='>= 60 days' pct_mkt_90='>= 90 days' pct_mkt_120='>= 120 days' ) * f=comma10.1;
  format month lblAx.;
  title2 "MRIS monthly real estate trend indicators, Washington, D.C.";

run;

ods output close;

run;

proc sort data=Table2;
  by descending month;

%File_info( data=Table2 )


** Write to output table **;

filename xlsFile dde "excel|&g_path\[&g_table_wbk]&sheet!r10c2:r17c9" lrecl=1000 notab;
*filename xlsFile "&g_path\_tmp_&g_table_wbk..&sheet.!r10c2.txt" lrecl=1000;

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
  
  xmonth = put( month, lblAx. );
  
  put xmonth '09'x @;
  
  put listings_sf_Mean '09'x list_sale_sf_Mean '09'x @;

  put listings_condo_Mean '09'x list_sale_condo_Mean '09'x @;
  
  put pct_mkt_60_Mean na. '09'x pct_mkt_90_Mean na. '09'x pct_mkt_120_Mean na.;

run;

filename xlsFile clear;

