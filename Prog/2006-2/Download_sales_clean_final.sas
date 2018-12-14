/**************************************************************************
 Program:  Download_sales_clean_final.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  04/03/06
 Version:  SAS 8.2
 Environment:  Windows with SAS/Connect
 
 Description:  Download latest sales data for Housing Monitor report.
 Add information on sales to owner occupants for 2004 and 2005.

 Modifications:
  04/11/06  Added information on owner-occ. sales
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

*options obs=100;

data sales_2004_2005_dc (keep=ssl saledate premiseadd address2);

  set Realprop.Test_sales_clean_final;
  where 2004 <= saledate_yr <= 2005 and indexw( address3, 'DC' );

  if address2 = '' then address2 = address1;
  
run;

%DC_geocode(
  data=sales_2004_2005_dc,
  out=premise_geo,
  staddr=premiseadd,
  id=ssl saledate,
  ds_label=,
  keep_geo=,
  block_match=N,
  listunmatched=N
)

%DC_geocode(
  data=sales_2004_2005_dc,
  out=address2_geo,
  staddr=address2,
  id=ssl saledate,
  ds_label=,
  keep_geo=,
  block_match=N,
  listunmatched=N
)

run;

** Merge standardized addresses & create owner-occ. sale flag **;

data sales_own_occ;

  merge
    Realprop.Test_sales_clean_final
    premise_geo (keep=ssl saledate premiseadd_std)
    address2_geo (keep=ssl saledate address2_std in=inDC);
  by ssl saledate;
  
  length owner_occ_sale 3;

  if 2004 <= saledate_yr <= 2005 then do;
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
    owner_occ_sale = 'Owner-occupied sale (2004 & 2005 only)';

run;

endrsubmit;

** Read parcel files with geo info (local) **;

libname dbmsdbf dbdbf "D:\DCData\Libraries\OCTO\Maps" ver=4 width=12 dec=2
  block=All_xy_block00 ward=All_xy_ward;

data All_xy_block00;

  set dbmsdbf.block (keep=ssl cjrTractBl);
  
  format _all_;
  informat _all_;

  %Octo_geoblk2000()

  %Block00_to_cluster_tr00()
  
  drop cjrTractBl;
  
run;

proc sort data=All_xy_block00;
  by ssl;
  
data All_xy_ward;

  set dbmsdbf.ward (keep=ssl ward_id);
  
  format _all_;
  informat _all_;

  %Octo_ward2002()
  
  drop ward_id;

run;

proc sort data=All_xy_ward;
  by ssl;
  
run;

** Start submitting commands to remote server **;

rsubmit;

*options obs=100;

proc upload status=no
  inlib=work 
  outlib=work memtype=(data);
  select All_xy_ward All_xy_block00;

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
    All_xy_ward 
    All_xy_block00;
  by ssl;

  if inSales;
  
  saledate_yr = year( saledate );
  
  if 1995 <= saledate_yr <= 2005;
  
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
