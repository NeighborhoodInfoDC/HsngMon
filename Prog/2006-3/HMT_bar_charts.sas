/**************************************************************************
 Program:  HMT_bar_charts.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  04/04/06
 Version:  SAS 8.2
 Environment:  Windows
 
 Description:  DC Housing Monitor.
 Bar charts with price changes for housing market typology groups.

 Modifications:
  05/03/06 PT  Use condo price changes for Downtown group.
**************************************************************************/

%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";

** Define libraries **;
%DCData_lib( HsngMon )
%DCData_lib( General )

*options obs=100;

data Sales_adj;

  set HsngMon.Sales_clean_final (keep=ui_proptype cluster_tr2000 Ward2002 saleprice saledate_yr);
  
  where cluster_tr2000 ~= '' and Ward2002 ~= '';
  
  nbrhd_type = put( cluster_tr2000, $clhmt5f. );

  ** Choose condominiums for Downtown group (7), single-family homes for all others **;
  
  if ( ui_proptype = '10' and nbrhd_type in ( '1', '2', '3', '4', '5', '6' ) ) or 
     ( ui_proptype = '11' and nbrhd_type in ( '7' ) );
    
  format nbrhd_type $hmt05f. cluster_tr2000 $CLUS00S.;
    
  %dollar_convert( saleprice / 1000, saleprice_adj, saledate_yr, 2005 )
  
run;

proc summary data=Sales_adj;
  class nbrhd_type saledate_yr;
  var saleprice_adj;
  output out=med_price (where=(_type_ in (3)) rename=(_freq_=num_sales))
    median=;

proc transpose data=med_price out=med_price_tr (drop=_name_) prefix=price;
  var saleprice_adj;
  id saledate_yr;
  by nbrhd_type;

data HMT_bar_charts;

  set med_price_tr;
  
  chg_price_1995_1997 = 100 * %annchg( price1995, price1997, 2 );
  chg_price_1997_1999 = 100 * %annchg( price1997, price1999, 2 );
  chg_price_1999_2001 = 100 * %annchg( price1999, price2001, 2 );
  chg_price_2001_2003 = 100 * %annchg( price2001, price2003, 2 );
  chg_price_2003_2005 = 100 * %annchg( price2003, price2005, 2 );
  
  keep nbrhd_type chg_price_1995_1997 chg_price_1997_1999
       chg_price_1999_2001 chg_price_2001_2003 chg_price_2003_2005;

run;

proc print;

filename fexport "D:\DCData\Libraries\HsngMon\Reports\2006-2\HMT_bar_charts.csv" lrecl=256;

proc export data=HMT_bar_charts
    outfile=fexport
    dbms=csv replace;

run;

filename fexport clear;



