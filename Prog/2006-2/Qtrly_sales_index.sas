/**************************************************************************
 Program:  Qtrly_sales_index.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  04/06/06
 Version:  SAS 8.2
 Environment:  Windows
 
 Description:  Figure 1. Single-Family Home and Condominium Price Trends.
 (Does not include OFHEO index.)

 Modifications:
**************************************************************************/

%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";

** Define libraries **;
%DCData_lib( HsngMon )
%DCData_lib( RealProp )

data Sales_adj;

  set HsngMon.Sales_clean_final;
  
  where 
    ( cluster_tr2000 ~= '' and Ward2002 ~= '' ) and
    ( 1995 <= year( saledate ) <= 2005 );
  
  %dollar_convert( saleprice, saleprice_adj, saledate_yr, 2005 )
  
run;

proc summary data=Sales_adj nway;
  class ui_proptype saledate;
  var saleprice_adj;
  output out=Qtrly_sales_price median=;
  format saledate yyq.;

data Qtrly_sales_index;

  set Qtrly_sales_price;
  by ui_proptype;
  
  retain index_ref;
  
  if first.ui_proptype then index_ref = saleprice_adj;
  
  index = 100 * ( ( saleprice_adj / index_ref ) - 1 );
  
run;  
  
proc print data=Qtrly_sales_index;
  by ui_proptype;
  
run;

proc format;
  value $uiptyps
    '10' = 'sf'
    '11' = 'condo';

proc sort data=Qtrly_sales_index;
  by saledate;

proc transpose data=Qtrly_sales_index out=Qtrly_sales_index_tr (drop=_name_) prefix=index_;
  var index;
  id ui_proptype;
  by saledate;
  *copy year_fmt;
  format ui_proptype $uiptyps.;

proc print;
  
data Csv_out;

  length year_fmt $ 4;

  set Qtrly_sales_index_tr;
  
  if qtr( saledate ) = 1 then year_fmt = put( year( saledate ), 4. );
  else year_fmt = "";
  
  drop saledate;
  
run;

filename fexport "D:\DCData\Projects\HsngMon\Reports\2006-2\Qtrly_sales_index.csv" lrecl=256;

proc export data=Csv_out
    outfile=fexport
    dbms=csv replace;

run;

filename fexport clear;

