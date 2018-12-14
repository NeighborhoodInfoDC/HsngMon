/**************************************************************************
 Program:  Sales_2006_wd02.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  11/17/06
 Version:  SAS 8.2
 Environment:  Windows
 
 Description:  Export data to Excel spreadsheet for Housing Monitor
 web profiles.
 Wards (2002)

 Modifications:
**************************************************************************/

%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";

** Define libraries **;
%DCData_lib( HsngMon )
%DCData_lib( RealProp )

*options obs=0;

%let cur_rpt_date = '1mar2006'd; 
%let cur_rpt_title = %str(Washington, D.C., 1995 - 2005);
%let last_sale_date = '31dec2005'd;
%let data = HsngMon.Sales_clean_final;
%let num_years = 11;
%let rpt_path = D:\DCData\Libraries\HsngMon\Web profiles\2006;
%let rpt_xls  = Sales_2006_wd02.xls;

%let sf_sales = (ui_proptype='10');
%let condo_sales = (ui_proptype='11');
%let valid_sales = (&sf_sales or &condo_sales);

%let BLANK = '20'x;    ** Blank character for DDE output **;

%let dollar_yr = %sysfunc( year( &last_sale_date ) );
%let num_rows = 9;     ** Includes city total **;

%let geonam = Ward;
%let geolvl = ward2002;
%let geosuf = wd02;
%let geofmt = ward02a.;

%let MIN_UNITS = 100;
%let MIN_SALES_PER_YR = 10;

%fdate()

proc format;
  ** Replace missing with zero in output **;
  value misszero (default=10)
    . = '0';
  ** Replace missing with n/a in output **;
  value missna (default=10)
    . = 'n/a';

** Create allyears format for report **;

data _cntlin;

  retain fmtname 'allyears' type 'n' sexcl 'n' eexcl 'y' hlo ' ';
  
  do i = 1 - (&num_years) to 0;
  
    dt0 = intnx( 'year', &last_sale_date, i, 'beginning' );
    dt1 = intnx( 'year', &last_sale_date, i + 1, 'beginning' );
    
    format dt0 dt1 mmddyy10.;
  
    start = put( dt0, 8. );
    end = put( dt1, 8. );
    
    label = left( put( dt0, year4. ) );
    
    output;
  
  end;
  
run;

proc format library=work cntlin=_cntlin fmtlib;

run;

** Write data summary info. **;

filename xlsFile dde "excel|&rpt_path\[&rpt_xls]Data-sum!r4c2:r20c2" lrecl=256 notab;

data _null_;

  file xlsFile;

  ** Date of report update **;
  
  put "&fdate";
  
  ** Report month & year **;

  rmonth = month( &cur_rpt_date );
  ryear = year( &cur_rpt_date );
  
  put "&cur_rpt_title" /;
  *put rmonth / ryear;
  
  ** Geographic level **;
  put "&geonam";     
  
  ** Number of rows to write **;
  put "&num_rows";
  
  ** Dollars **;
  put "&dollar_yr";
  
  ** Year row labels **;
  
  ryear = year( intnx( 'year', &last_sale_date, (1 - &num_years ), 'beginning' ) );
  
  do i = ryear to ryear + (&num_years - 2 );
    put i;
  end;

  ryear = year( &last_sale_date );
  rqtr = qtr( &last_sale_date );

  if rqtr = 4 then
    put ryear;
  else do;
    buff = put( ryear, 4. ) || ' Q' || put( rqtr, 1. );
    put buff;
  end;

run;

filename xlsFile clear;


/** Macro Write_col_heads - Start Definition **/

%macro Write_col_heads( start=, end= );

  file xlsFileH;
  
  %do yr = &start %to &end;
  
    put 
      "r_mprice_sf_&yr" '09'x 
      "sales_sf_&yr" '09'x 
      "sales_100u_sf_&yr" '09'x @;
  
  %end;

  %do yr = &start %to &end;
  
    put 
      "r_mprice_condo_&yr" '09'x 
      "sales_condo_&yr" '09'x 
      "sales_100u_condo_&yr" '09'x @;
  
  %end;

  put
    "chg_r_mprice_sf_10" '09'x
    "chg_sales_100u_sf_10" '09'x
    "chg_r_mprice_sf_5" '09'x
    "chg_sales_100u_sf_5" '09'x
    "chg_r_mprice_sf_1" '09'x
    "chg_sales_100u_sf_1" '09'x
    "chg_r_mprice_condo_10" '09'x
    "chg_sales_100u_condo_10" '09'x
    "chg_r_mprice_condo_5" '09'x
    "chg_sales_100u_condo_5" '09'x
    "chg_r_mprice_condo_1" '09'x
    "chg_sales_100u_condo_1" '09'x 
    @;

  put;

%mend Write_col_heads;

/** End Macro Definition **/



/** Macro Write_data - Start Definition **/

%macro Write_data( start=, end= );

  ** Calculate sales per unit **;

  %do yr = &start %to &end;
  
    %if &yr >= 2001 %then %do;
      if units_sf_&yr > 0 then sales_100u_sf_&yr = 100 * sales_sf_&yr / units_sf_&yr;
      if units_condo_&yr > 0 then sales_100u_condo_&yr = 100 * sales_condo_&yr / units_condo_&yr;
    %end;
    %else %do;
      if units_sf_2001 > 0 then sales_100u_sf_&yr = 100 * sales_sf_&yr / units_sf_2001;
      if units_condo_2001 > 0 then sales_100u_condo_&yr = 100 * sales_condo_&yr / units_condo_2001;
    %end;
    
  %end;
    
  ** Calculate changes **;
  
  if inc_sf then do;
  
    chg_r_mprice_sf_10 = 100 * %annchg( r_mprice_sf_&start, r_mprice_sf_&end, (&end - &start) );
    chg_r_mprice_sf_5 = 100 * %annchg( r_mprice_sf_%eval(&end-5), r_mprice_sf_&end, 5 );
    chg_r_mprice_sf_1 = 100 * %annchg( r_mprice_sf_%eval(&end-1), r_mprice_sf_&end, 1 );
    
    chg_sales_100u_sf_10 = 100 * %annchg( sales_100u_sf_&start, sales_100u_sf_&end, (&end - &start) );
    chg_sales_100u_sf_5 = 100 * %annchg( sales_100u_sf_%eval(&end-5), sales_100u_sf_&end, 5 );
    chg_sales_100u_sf_1 = 100 * %annchg( sales_100u_sf_%eval(&end-1), sales_100u_sf_&end, 1 );
  
  end;
  
  if inc_condo then do;
  
    chg_r_mprice_condo_10 = 100 * %annchg( r_mprice_condo_&start, r_mprice_condo_&end, (&end - &start) );
    chg_r_mprice_condo_5 = 100 * %annchg( r_mprice_condo_%eval(&end-5), r_mprice_condo_&end, 5 );
    chg_r_mprice_condo_1 = 100 * %annchg( r_mprice_condo_%eval(&end-1), r_mprice_condo_&end, 1 );
    
    chg_sales_100u_condo_10 = 100 * %annchg( sales_100u_condo_&start, sales_100u_condo_&end, (&end - &start) );
    chg_sales_100u_condo_5 = 100 * %annchg( sales_100u_condo_%eval(&end-5), sales_100u_condo_&end, 5 );
    chg_sales_100u_condo_1 = 100 * %annchg( sales_100u_condo_%eval(&end-1), sales_100u_condo_&end, 1 );
  
  end;
  
  ** Round sales prices to nearest $100 **;

  %do yr = &start %to &end;
  
    f_r_mprice_sf_&yr = round( r_mprice_sf_&yr, 100 );
    f_r_mprice_condo_&yr = round( r_mprice_condo_&yr, 100 );
    
  %end;

  ** Write data **;
  
  %do yr = &start %to &end;
  
    put 
      f_r_mprice_sf_&yr misszero. '09'x 
      sales_sf_&yr misszero. '09'x 
      sales_100u_sf_&yr misszero. '09'x 
      @;
  
  %end;

  %do yr = &start %to &end;
  
    put 
      f_r_mprice_condo_&yr misszero. '09'x 
      sales_condo_&yr misszero. '09'x 
      sales_100u_condo_&yr misszero. '09'x 
      @;
  
  %end;
  
  put
    chg_r_mprice_sf_10 '09'x
    chg_sales_100u_sf_10 '09'x
    chg_r_mprice_sf_5 '09'x
    chg_sales_100u_sf_5 '09'x
    chg_r_mprice_sf_1 '09'x
    chg_sales_100u_sf_1 '09'x
    chg_r_mprice_condo_10 '09'x
    chg_sales_100u_condo_10 '09'x
    chg_r_mprice_condo_5 '09'x
    chg_sales_100u_condo_5 '09'x
    chg_r_mprice_condo_1 '09'x
    chg_sales_100u_condo_1 '09'x 
    @;
    
%mend Write_data;

/** End Macro Definition **/

data Units (drop=city);

  set
    RealProp.Units_sum_city
    RealProp.Units_sum_&geosuf;
    
run;

data Sales (drop=city);

  set
    RealProp.Sales_sum_dc_city
    RealProp.Sales_sum_dc_&geosuf;
    
run;

filename xlsFileH dde "excel|&rpt_path\[&rpt_xls]Data!r1c6:r1c84" lrecl=5000 notab;
filename xlsFileD dde "excel|&rpt_path\[&rpt_xls]Data!r2c1:r%eval(2+&num_rows-1)c84" lrecl=5000 notab;

data _null_;

  merge Units Sales;
  by &geolvl;
  
  if _n_ = 1 then do;
    %Write_col_heads( start=1995, end=2005 )
  end;
  
  if units_sf_2005 >= &MIN_UNITS and 
    min( of sales_sf_: ) >= &MIN_SALES_PER_YR then inc_sf = 1;
  else inc_sf = 0;
  
  if units_condo_2005 >= &MIN_UNITS and 
    min( of sales_condo_: ) >= &MIN_SALES_PER_YR then inc_condo = 1;
  else inc_condo = 0;
  
  if inc_sf or inc_condo;
  
  file xlsFileD;
  
  *if first.&geolvl then do;
    if &geolvl = '' then do;
      put 'City' '09'x 'City Total' '09'x '09'x @;
    end;
    else do;
      put &geolvl $11. '09'x @;
      put &geolvl &geofmt '09'x '09'x @;
    end;
  *end;
  
  put inc_sf '09'x inc_condo '09'x @;
  
  %Write_data( start=1995, end=2005 )
  
  /*if last.&geolvl then*/ put;
  
run;

filename _all_ clear;


*************************************************************************;

ENDSAS;

*************************************************************************;

** Compile sales data by tract **;

data Sales;

  set &data (keep=ssl saledate saleprice ui_proptype saletype);

  where &valid_sales and  
    intnx( 'year', &last_sale_date, (1 - &num_years ), 'beginning' ) <= 
    saledate <= &last_sale_date;

  year = year( saledate );
  
  %dollar_convert( saleprice, saleprice_&dollar_yr.d, year, &dollar_yr );
  
  ** Sales type (1=SF, 2=Condo) **;
  
  if &sf_sales then stype = 1;
  else stype = 2;

run;

proc sql;
  create table Sales_geo as
  select Sales.*, geo.ward2002, geo.Cluster_tr2000, geo.geo2000
  from 
    Sales left join
    RealProp.Ownerpt_geo as geo
  on Sales.ssl = geo.ssl;

*proc print data=Sales_geo (obs=10);
*  title2 'Sales_geo';

** Unit counts **;

proc sql;
  create table Sf_units as
  select parcels.ssl, geo.ward2002, geo.Cluster_tr2000, geo.geo2000,
    1 as stype, 1 as units 
  from 
    RealProp.Ownerpt_2004_12 (where=(&sf_sales)) as parcels left join
    RealProp.Ownerpt_geo as geo
  on parcels.ssl = geo.ssl;

  create table Condo_units as
  select parcels.ssl, geo.ward2002, geo.Cluster_tr2000, geo.geo2000,
    2 as stype, 1 as units
  from 
    RealProp.Ownerpt_2004_12 (where=(&condo_sales)) as parcels left join
    RealProp.Ownerpt_geo as geo
  on parcels.ssl = geo.ssl;

proc format;
  ** For completetypes on sale type **;
  value stype
    1 = 'SF'
    2 = 'Condo';
  ** Replace missing with zero in output **;
  value misszero (default=10)
    . = '0';
  ** Replace missing with n/a in output **;
  value missna (default=10)
    . = 'n/a';

proc summary data=Sales_geo completetypes;
  where geo2000 ~= '';
  class stype geo2000 saledate / preloadfmt;
  var saleprice_&dollar_yr.d;
  output out=Sales_sum (where=(_type_ in (5,7)) rename=(_freq_=numsales)) median=;
  format stype stype. geo2000 $geo00a. saledate allyears.;
run;

*proc print data=Sales_sum (obs=50);
*  title2 'Sales_sum';

proc summary data=Sf_units;
  class stype geo2000;
  var units;
  output out=Sf_units_sum (where=(_type_ in (2,3)) drop=_freq_) sum=;
run;

*proc print;

proc summary data=Condo_units;
  class stype geo2000;
  var units;
  output out=Condo_units_sum (where=(_type_ in (2,3)) drop=_freq_) sum=;
run;

*proc print;

data all_units;
  set sf_units_sum condo_units_sum;
run;

** Put it all together **;

proc sql;
  create table Summary_a as
  select * 
  from Sales_sum as a left join all_units as u
  on a.stype = u.stype and a.geo2000 = u.geo2000
  order by a.geo2000, a.stype, a.saledate;

proc print data=Summary_a;
  id geo2000 stype saledate;
  title2 'Summary_a';

** Write data to work book **;

filename xlsFile dde "excel|&rpt_path\[&rpt_xls]Data!r2c1:r%eval(2+&num_rows-1).c82" lrecl=5000 notab;

data _null_;

  file xlsFile;

  set Summary_a;
    by geo2000;
  
  if first.geo2000 then do;
    if geo2000 = '' then do;
      put 'City' '09'x 'Washington, D.C.' '09'x '09'x @;
    end;
    else do;
      put geo2000 $11. '09'x @;
      put geo2000 $geo00a. '09'x '09'x @;
    end;
  end;
  
  sales_per_100u = 100 * ( numsales / units );
  
/****  if &num_years = 11 or year( saledate ) ~= 2005 then  ****/
    put saleprice_&dollar_yr.d misszero. '09'x numsales misszero. '09'x sales_per_100u misszero. '09'x @;
/***  else  ***/
    /*** TEMPORARY UNTIL WE GET 2005 SALES ***/
/***    put &BLANK '09'x &BLANK '09'x &BLANK '09'x @; ***/
  
  if last.geo2000 then put;
  
run;
  
