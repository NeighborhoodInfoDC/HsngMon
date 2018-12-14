/**************************************************************************
 Program:  Table4.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  4/23/09
 Version:  SAS 9.1
 Environment:  Windows
 
 Description:  Create table 4 (home sales by ward & cluster).
 
 SUMMER/FALL 2009

 Modifications:
**************************************************************************/

%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";

** Define libraries **;
%DCData_lib( HsngMon )
%DCData_lib( RealProp )

*options mprint symbolgen mlogic;

%let MIN_SALES = 10;
%let MIN_AVG_SALES_PER_YR = 10;

%Init_macro_vars( rpt_yr=2009, rpt_qtr=3, sales_qtr_offset=-3 )

%let prev_year = %eval( &g_sales_end_yr - 1 );

data Sales_adj (compress=no);

  set HsngMon.Sales_clean_&g_rpt_yr._&g_rpt_qtr 
       (keep=ui_proptype cluster_tr2000 ward2002 saledate_yr saleprice_adj);
  
  ** Select single-family homes and condos with non-missing cluster or ward IDs **;
  ** Keep only years to be included in table **;
  
  where ui_proptype in ( '10', '11' ) and cluster_tr2000 ~= '' and Ward2002 ~= '' and 
    saledate_yr in ( &g_sales_start_yr, &g_sales_mid_yr, &prev_year, &g_sales_end_yr );
  
  city = '1';
  format city $city.;
  
  saleprice_adj = saleprice_adj / 1000;
  
run;

/** Macro Transpose_data - Start Definition **/

%macro Transpose_data( by=, id= );

  ** Summarize sales by cluster and housing market typology **;

  proc summary data=Sales_adj nway completetypes;
    class ui_proptype &id;
    class &by / preloadfmt;
    class saledate_yr;
    var saleprice_adj;
    output out=&by (rename=(_freq_=num_sales))
      median=;
  run;

  /*
  proc print data=&by (obs=100);
  title2 "File = &by";
  run;
  title2;
  */

  ** Transpose data to put years in columns **;

  %Super_transpose(  
    data=&by,
    out=&by._tr,
    var=num_sales saleprice_adj,
    id=saledate_yr,
    by=ui_proptype &id &by
  )

  /*
  proc print data=&by._tr;
    title2 "File=&by._tr";
  run;
  */

%mend Transpose_data;

/** End Macro Definition **/

%Transpose_data( by=city )

%Transpose_data( by=ward2002 )

%Transpose_data( by=cluster_tr2000 )

** Add wards to cluster file, resort **;

data cluster_tr2000_tr;

  set cluster_tr2000_tr;

  ** Cluster ward var **;
  
  length ward2002 $ 1;
  
  ward2002 = put( cluster_tr2000, $cl0wd2f. );
  
  label ward2002 = 'Ward (cluster-based)';
  
run;

/*
proc sort data=cluster_tr2000_tr;
  by ward2002 cluster_tr2000;
run;
  */

** Merge transposed data together **;

data HsngMon.Table4_&g_rpt_yr.&g_rpt_qtr.;

  set city_tr ward2002_tr cluster_tr2000_tr;
  
  ** Remove noncluster areas **;
  
  if cluster_tr2000 = '99' then delete;
  
  ** Suppress and filter clusters w/too few sales **;
  
  array sales{*} num_sales_&g_sales_start_yr num_sales_&g_sales_mid_yr num_sales_&prev_year num_sales_&g_sales_end_yr;
  array price{*} saleprice_adj_&g_sales_start_yr saleprice_adj_&g_sales_mid_yr saleprice_adj_&prev_year saleprice_adj_&g_sales_end_yr;
  
  do i = 1 to dim( sales );
    if sales{i} < &MIN_SALES then price{i} = .;
  end;
  
  if n( of saleprice_adj_: ) = 0 or mean( of num_sales_: ) < &MIN_AVG_SALES_PER_YR then do;
    %note_put( msg=ui_proptype= cluster_tr2000 " deleted. " (num_sales_:) (=) )
    delete;
  end;
  
  ** Calculate annual pct. price changes **;
  
  chg_price_&g_sales_start_yr._&g_sales_end_yr. = 100 * %annchg( saleprice_adj_&g_sales_start_yr., saleprice_adj_&g_sales_end_yr., &g_sales_end_yr. - &g_sales_start_yr. );
  chg_price_&g_sales_mid_yr._&g_sales_end_yr. = 100 * %annchg( saleprice_adj_&g_sales_mid_yr., saleprice_adj_&g_sales_end_yr., &g_sales_end_yr. - &g_sales_mid_yr. );
  chg_price_&prev_year._&g_sales_end_yr. = 100 * %annchg( saleprice_adj_&prev_year., saleprice_adj_&g_sales_end_yr., &g_sales_end_yr. - &prev_year. );
  
  keep ui_proptype city ward2002 cluster_tr2000 num_sales_: saleprice_adj_: chg_price_: ;
  
run;

proc sort data=HsngMon.Table4_&g_rpt_yr.&g_rpt_qtr.;
  by ui_proptype ward2002 cluster_tr2000;
run;

%File_info( data=HsngMon.Table4_&g_rpt_yr.&g_rpt_qtr., printobs=0 )

proc print data=HsngMon.Table4_&g_rpt_yr.&g_rpt_qtr.;
  by ui_proptype;
  id city ward2002 cluster_tr2000;
  title2 "File = HsngMon.Table4_&g_rpt_yr.&g_rpt_qtr.";
run;
title2;


**** Write data to Excel table ****;

/** Macro Output_table4 - Start Definition **/

%macro Output_table4( start_row=, end_row=, where=, sheet= );


  filename xout dde 
    "excel|&g_path\[&g_table_wbk]&sheet!R&start_row.C1:R&end_row.C15" 
    lrecl=1000 notab;

  data _null_;

    file xout;
    
    set HsngMon.Table4_&g_rpt_yr.&g_rpt_qtr. (where=(&where));
    by ward2002;
    
    cluster_num = input( cluster_tr2000, 2. );
    
    if ward2002 = '' then 
      put 'Washington, D.C. Total' '09'x '09'x '09'x '09'x @;
    else if Cluster_tr2000 = '' then 
      put ward2002 '09'x '09'x '09'x '09'x @;
    else
      put '09'x cluster_num '09'x '09'x Cluster_tr2000 $clus00s. '09'x @;
      
    put num_sales_&g_sales_start_yr. '09'x num_sales_&g_sales_mid_yr. '09'x num_sales_&prev_year. '09'x num_sales_&g_sales_end_yr. '09'x @;
    put saleprice_adj_&g_sales_start_yr. '09'x saleprice_adj_&g_sales_mid_yr. '09'x saleprice_adj_&prev_year. '09'x saleprice_adj_&g_sales_end_yr. '09'x @;
    put chg_price_&g_sales_start_yr._&g_sales_end_yr. '09'x chg_price_&g_sales_mid_yr._&g_sales_end_yr. '09'x chg_price_&prev_year._&g_sales_end_yr.;
    
    if last.ward2002 then put;
    
  run;

  filename xout clear;

%mend Output_table4;

/** End Macro Definition **/

options missing='-';

** Single-family homes **;

%Output_table4( 
  sheet = Table 4a,
  start_row = 9, 
  end_row = 63, 
  where = ui_proptype = '10' 
)


** Condos **;

%Output_table4( 
  sheet = Table 4b,
  start_row = 9, 
  end_row = 54, 
  where = ui_proptype = '11' 
)


