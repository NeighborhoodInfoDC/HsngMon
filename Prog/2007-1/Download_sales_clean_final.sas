/**************************************************************************
 Program:  Download_sales_clean_final.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  11/03/06
 Version:  SAS 8.2
 Environment:  Windows with SAS/Connect
 
 Description:  Download latest sales data for Housing Monitor report.
 Add information on sales to owner occupants for 2004 to 2006-Q2.
 Winter 2006/2007

 Modifications:
**************************************************************************/

%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";
%include "K:\Metro\PTatian\DCData\SAS\Inc\AlphaSignon.sas" /nosource2;

** Define libraries **;
%DCData_lib( HsngMon )
%DCData_lib( RealProp )
%DCData_lib( Octo )
%DCData_lib( General )

*options obs=100;

** Standardize addresses to check for owner-occ. sales **;

rsubmit;

%let data = Realprop.Test_sales_09_2006;
%let start_dt = '01jan1995'd;
%let end_dt = '01jul2006'd;

/**** PATCH *****/
proc upload status=no
  data=RealProp.Test_sales_07_2006 
  out=Work.Test_sales_07_2006;
run;
%let data = Test_sales_07_2006;
/****************/

*options obs=100;

data sales_owner_dc (keep=ssl saledate premiseadd address2);

  set &data;
  where '01jan2004'd <= saledate < &end_dt and indexw( address3, 'DC' );

  if address2 = '' then address2 = address1;
  
run;

%DC_geocode(
  data=sales_owner_dc,
  out=premise_geo,
  staddr=premiseadd,
  id=ssl saledate,
  ds_label=,
  keep_geo=,
  geo_match=N,
  block_match=N,
  listunmatched=N
)

%DC_geocode(
  data=sales_owner_dc,
  out=address2_geo,
  staddr=address2,
  id=ssl saledate,
  ds_label=,
  keep_geo=,
  geo_match=N,
  block_match=N,
  listunmatched=N
)

run;

** Merge standardized addresses & create owner-occ. sale flag **;

data sales_own_occ;

  merge
    &data
    premise_geo (keep=ssl saledate premiseadd_std)
    address2_geo (keep=ssl saledate address2_std in=inDC);
  by ssl saledate;
  
  length owner_occ_sale 3;

  if '01jan2004'd <= saledate < &end_dt then do;
    if inDC and
      ( premiseadd_std = address2_std or hstd_code in ( '1', '5' ) ) then 
        owner_occ_sale = 1;
    else owner_occ_sale = 0;
  end;
  else do;
    owner_occ_sale = .u;
  end;
  
  format owner_occ_sale yesno.;
  
  label
    owner_occ_sale = 'Owner-occupied sale (2004 & later only)';

run;

endrsubmit;

** Start submitting commands to remote server **;

rsubmit;

*options obs=100;

data Sales_clean_final;

  merge 
    /*RealProp.Test_sales_clean_final */
    Sales_own_occ
      (/*drop=anc2002 cluster2000 geo1990 geo2000 Psa2004
            OWNERNAME CJRTRACTBL index_attr index_sale
            LOWNUMBER HIGHNUMBER STREETNAME QDRNTNAME CAREOFNAME 
            CLUSTERUI CLUSTERCITY clusnew yr*/
       rename=(GeoBlk2000=GeoBlk2000_old Ward2002=Ward2002_old
               cluster_tr2000=cluster_tr2000_old)
       in=inSales)
    RealProp.Parcel_geo (keep=ssl ward2002 geoblk2000 cluster_tr2000 geo2000);
  by ssl;

  if inSales;
  
  saledate_yr = year( saledate );
  
  if &start_dt <= saledate < &end_dt;
  
  if GeoBlk2000 = '' then GeoBlk2000 = GeoBlk2000_old;
  if Ward2002 = '' then Ward2002 = Ward2002_old;
  if cluster_tr2000 = '' then cluster_tr2000 = cluster_tr2000_old;
  
  drop GeoBlk2000_old Ward2002_old cluster_tr2000_old; 
  
run;

proc download status=no
  data=Sales_clean_final 
  out=HsngMon.Sales_clean_final;

run;

endrsubmit;

** End submitting commands to remote server **;

%file_info( data=HsngMon.Sales_clean_final, printobs=5, 
            freqvars=ward2002 cluster_tr2000 ui_proptype saledate_yr owner_occ_sale )

proc freq data=HsngMon.Sales_clean_final;
  tables saledate;
  format saledate yyq.;

run;

signoff;
