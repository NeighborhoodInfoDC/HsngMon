/**************************************************************************
 Program:  Forecl_cluster_tbl.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  04/27/09
 Version:  SAS 9.1
 Environment:  Windows
 
 Description:  Table of foreclosure indicators by ward/cluster.
 
 SPRING 2009

 Modifications:
**************************************************************************/

%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";

** Define libraries **;
%DCData_lib( HsngMon )
%DCData_lib( RealProp )

%Init_macro_vars( rpt_yr=2009, rpt_qtr=2, sales_qtr_offset=-2 )

%let year = 2008;

/** Macro Geo - Start Definition **/

%macro Geo( geo=, geosuf= );

  proc summary data=HsngMon.Foreclosures_year_2009_2 nway;
    where ui_proptype in ( '10', '11' ) and year( report_dt ) = &year;
    class &geo report_dt;
    var in_foreclosure_beg in_foreclosure_end foreclosure_start foreclosure_sale distressed_sale foreclosure_avoided;
    output out=Chart (drop=_type_ _freq_) sum=;
  run;

  data &geo._tr;

    merge 
      Chart 
      RealProp.Num_units_&geosuf (keep=&geo units_sf_condo_: );
    by &geo;
    
    select ( year( report_dt ) );
      when ( 1999 ) units_sf_condo = units_sf_condo_1999;
      when ( 2000 ) units_sf_condo = units_sf_condo_2000;
      when ( 2001 ) units_sf_condo = units_sf_condo_2001;
      when ( 2002 ) units_sf_condo = units_sf_condo_2002;
      when ( 2003 ) units_sf_condo = units_sf_condo_2003;
      when ( 2004 ) units_sf_condo = units_sf_condo_2004;
      when ( 2005 ) units_sf_condo = units_sf_condo_2005;
      when ( 2006 ) units_sf_condo = units_sf_condo_2006;
      when ( 2007 ) units_sf_condo = units_sf_condo_2007;
      when ( 2008 ) units_sf_condo = units_sf_condo_2008; 
      otherwise units_sf_condo = units_sf_condo_2008;
    end;
    
    in_foreclosure_beg_rate = 1000 * in_foreclosure_beg / units_sf_condo;
    in_foreclosure_end_rate = 1000 * in_foreclosure_end / units_sf_condo;
    foreclosure_start_rate = 1000 * foreclosure_start / units_sf_condo;
    foreclosure_sale_rate = 1000 * foreclosure_sale / units_sf_condo;
    distressed_sale_rate = 1000 * distressed_sale / units_sf_condo;
    foreclosure_avoided_rate = 1000 * foreclosure_avoided / units_sf_condo;
        
    drop units_sf_condo_: ;
    
  run;

  proc print data=&geo._tr;
    id report_dt &geo;
    sum in_foreclosure_beg in_foreclosure_end foreclosure_start foreclosure_sale distressed_sale foreclosure_avoided;
    title2 "File = &geo._tr";
  run;

  title2;

%mend Geo;

/** End Macro Definition **/


%Geo( geo=ward2002, geosuf=wd02 )

%Geo( geo=cluster_tr2000, geosuf=cltr00 )

%Geo( geo=city, geosuf=city )


** Add wards to cluster file, resort **;

data cluster_tr2000_tr;

  set cluster_tr2000_tr;

  ** Cluster ward var **;
  
  length ward2002 $ 1;
  
  ward2002 = put( cluster_tr2000, $cl0wd2f. );
  
  label ward2002 = 'Ward (cluster-based)';
  
run;


** Merge transposed data together **;

data HsngMon.Forecl_cluster_tbl_2009_2;

  set city_tr ward2002_tr cluster_tr2000_tr;
  
  ** Remove noncluster areas **;
  
  if cluster_tr2000 = '99' then delete;

run;

proc sort data=HsngMon.Forecl_cluster_tbl_2009_2;
  by ward2002 cluster_tr2000;
run;

%File_info( data=HsngMon.Forecl_cluster_tbl_2009_2, printobs=0 )

proc print data=HsngMon.Forecl_cluster_tbl_2009_2;
  id city ward2002 cluster_tr2000;
  title2 "File = Table";
run;
title2;


**** Write data to Excel table ****;

/** Macro Output_table4 - Start Definition **/

%macro Output_table( start_row=, end_row=, sheet= );

  filename xout dde 
    "excel|&g_path\[&g_table_wbk]&sheet!R&start_row.C1:R&end_row.C16" 
    lrecl=1000 notab;

  data _null_;

    file xout;
    
    set HsngMon.Forecl_cluster_tbl_2009_2;
    by ward2002;
    
    cluster_num = input( cluster_tr2000, 2. );
    
    if ward2002 = '' then 
      put 'Washington, D.C. Total' '09'x '09'x '09'x '09'x @;
    else if Cluster_tr2000 = '' then 
      put ward2002 '09'x '09'x '09'x '09'x @;
    else
      put '09'x cluster_num '09'x '09'x Cluster_tr2000 $clus00s. '09'x @;
      
    put  
      in_foreclosure_beg '09'x 
      foreclosure_start '09'x 
      foreclosure_sale '09'x 
      distressed_sale '09'x 
      foreclosure_avoided '09'x
      in_foreclosure_end '09'x 
      
      in_foreclosure_beg_rate '09'x 
      foreclosure_start_rate '09'x 
      foreclosure_sale_rate '09'x 
      distressed_sale_rate '09'x 
      foreclosure_avoided_rate '09'x
      in_foreclosure_end_rate '09'x
    ;
      
    if last.ward2002 then put;
    
  run;

  filename xout clear;

%mend Output_table;

/** End Macro Definition **/

options missing='-';


** Write table **;

%Output_table( 
  sheet = Table X,
  start_row = 9, 
  end_row = 63
)

