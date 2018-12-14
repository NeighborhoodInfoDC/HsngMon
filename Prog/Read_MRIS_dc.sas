/**************************************************************************
 Program:  Read_MRIS_dc.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  08/07/06
 Version:  SAS 8.2
 Environment:  Windows
 
 Description:  Read monthly MRIS data for DC after updating workbook:
 
   D:\DCData\Libraries\HsngMon\Raw\DC MRIS data.xls
 
 This workbook must be open before program is run.
 
 NB: After successfully updating the MRIS data, run Upload_MRIS_dc.sas
 to upload file to Alpha and register with metadata sytem.

 Modifications:
**************************************************************************/

%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";

** Define libraries **;
%DCData_lib( HsngMon )

%let lastrow = 200;

%let path = D:\DCData\Libraries\HsngMon\Raw\;
%let wbook = DC MRIS data.xls;
%let sheet = summary;

filename xlsFileA dde "excel|&path[&wbook]&sheet!r11c1:r&lastrow.c1" lrecl=1000;
filename xlsFileB dde "excel|&path[&wbook]&sheet!r11c9:r&lastrow.c11" lrecl=1000;
filename xlsFileC dde "excel|&path[&wbook]&sheet!r11c15:r&lastrow.c17" lrecl=1000;
filename xlsFileD dde "excel|&path[&wbook]&sheet!r11c24:r&lastrow.c26" lrecl=1000;

data HsngMon.MRIS_monthly_dc 
      (label="MRIS monthly real estate trend indicators, DC");
      
  infile xlsFileA;
  
  input month :mmddyy10.;
  
  infile xlsFileB;
  
  input listings_condo :comma12. listings_sf :comma12. listings_tot :comma12. ;
  
  if listings_condo + listings_sf ~= listings_tot then do;
    %err_put( msg="Listing totals do not add up: " _n_= month= listings_condo= listings_sf= listings_tot= )
  end;
  
  infile xlsFileC;
  
  input sales_condo :comma12. sales_sf :comma12. sales_tot :comma12. ;
  
  if sales_condo + sales_sf ~= sales_tot then do;
    %err_put( msg="Sale totals do not add up: " _n_= month= sales_condo= sales_sf= sales_tot= )
  end;
  
  infile xlsFileD;
  
  input pct_mkt_60 :percent12. pct_mkt_90 :percent12. pct_mkt_120 :percent12. ;
  
  pct_mkt_60 = 100 * pct_mkt_60;
  pct_mkt_90 = 100 * pct_mkt_90;
  pct_mkt_120 = 100 * pct_mkt_120;
  
  ** Listing to sale ratio **;
  
  list_sale_condo = listings_condo / sales_condo;
  list_sale_sf = listings_sf / sales_sf;
  list_sale_tot = listings_tot / sales_tot;
  
  label
    month = "Month"
    listings_condo = "Active listings, condos/coops/ground rent"
    listings_sf    = "Active listings, s.f. homes"
    listings_tot   = "Active listings, total"
    sales_condo = "Sales, condos/coops/ground rent"
    sales_sf    = "Sales, s.f. homes"
    sales_tot   = "Sales, total"
    list_sale_condo = "Listing to sale ratio, condos/coops/ground rent"
    list_sale_sf    = "Listing to sale ratio, s.f. homes"
    list_sale_tot   = "Listing to sale ratio, total"
    pct_mkt_60  = "Pct. units sold on market for at least 60 days"
    pct_mkt_90  = "Pct. units sold on market for at least 90 days"
    pct_mkt_120  = "Pct. units sold on market for at least 120 days"
  ;
    
  format month mmddyy10.;

run;

proc sort data=HsngMon.MRIS_monthly_dc;
  by month;

%File_info( data=HsngMon.MRIS_monthly_dc )

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
      ( listings_tot='Total' listings_sf='SF' listings_condo='Condo' );
  table
    month,
    n='Months of data'
    sum='Total sales' *
      ( sales_tot='Total' sales_sf='SF' sales_condo='Condo' );
  table
    month,
    n='Months of data'
    mean='Listing to sale ratio' *
      ( list_sale_tot='Total' list_sale_sf='SF' list_sale_condo='Condo' ) * f=comma10.1;
  table
    month,
    n='Months of data'
    mean='Pct. sales by time on market' *
      ( pct_mkt_60='>= 60 days' pct_mkt_90='>= 90 days' pct_mkt_120='>= 120 days' ) * f=comma10.1;
  format month year.;
  title2 "MRIS monthly real estate trend indicators, Washington, D.C.";

run;

