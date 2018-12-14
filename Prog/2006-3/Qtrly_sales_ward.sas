/**************************************************************************
 Program:  Qtrly_sales_ward.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  08/10/06
 Version:  SAS 8.2
 Environment:  Windows
 
 Description:  Figure 3. Single-family home price trends by ward.

 Modifications:
**************************************************************************/

%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";

** Define libraries **;
%DCData_lib( HsngMon )
%DCData_lib( RealProp )

*options obs=0;

data Sales_adj (compress=no);

  set HsngMon.Sales_clean_final;
  
  where 
    ( cluster_tr2000 ~= '' and Ward2002 ~= '' ) and
    ( '01jan1995'd <= saledate < '01apr2006'd ) and
    ui_proptype = '10';
  
  ** Synchronize start at first quarter 1996 **;
  
  if year( saledate ) = 1995 and qtr( saledate ) = 1 then delete;
  
  %dollar_convert( saleprice, saleprice_adj, saledate_yr, 2006 )
  
run;

proc summary data=Sales_adj nway;
  class ward2002 saledate;
  var saleprice_adj;
  output out=Qtrly_sales_price (drop=_type_ _freq_ compress=no) median=;
  format saledate yyq.;

data Qtrly_sales_ward (compress=no);

  set Qtrly_sales_price;
  by ward2002;
  
  retain price1 price2 price3;
  
  if first.ward2002 then do;
    price1 = .;
    price2 = .;
    price3 = .;
  end;

  ** 4 quarter moving average **;
  
  mov_avg_price = ( saleprice_adj + price1 + price2 + price3 ) / 4;
  
  put (_all_) (=);
  
  if mov_avg_price ~= . then output;
  
  price3 = price2;
  price2 = price1;
  price1 = saleprice_adj;
  
  drop price1 price2 price3 saleprice_adj;
  
run;  
  
proc print data=Qtrly_sales_ward;
  by ward2002;
  
run;

proc sort data=Qtrly_sales_ward;
  by saledate;

proc transpose data=Qtrly_sales_ward 
    out=Qtrly_sales_ward_tr (drop=_name_ compress=no) 
    prefix=price_wd_;
  var mov_avg_price;
  id ward2002;
  by saledate;
  format ward2002 $1.;

proc print;
  
data Csv_out (compress=no);

  length year_fmt $ 4;

  set Qtrly_sales_ward_tr;
  
  if qtr( saledate ) = 1 then year_fmt = put( year( saledate ), 4. );
  else year_fmt = "";
  
  drop saledate;
  
run;

filename fexport "D:\DCData\Libraries\HsngMon\Reports\2006-3\Qtrly_sales_ward.csv" lrecl=256;

proc export data=Csv_out
    outfile=fexport
    dbms=csv replace;

run;

filename fexport clear;

