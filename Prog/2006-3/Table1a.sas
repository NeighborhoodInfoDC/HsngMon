/**************************************************************************
 Program:  Table1a.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  04/03/06
 Version:  SAS 8.2
 Environment:  Windows
 
 Description:  DC Housing Monitor Table 1. 
 Home Sales and Section 8 Housing by Ward, Washington, D.C., 1995-2005
 
 Part A:
 - Number of Sales
 - Median sales price (2005 $ thousands)
 - Percent change, median sales price
 
 Nb:  Does not include Percent units sold, owner occupants and 
 Housing Units in Section 8 Multifamily Projects.

 Modifications:
  05/08/06 PT  Replaced sales per quarter with total sales per year.
**************************************************************************/

%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";

** Define libraries **;
%DCData_lib( HsngMon )

%let outfile = DC Housing Monitor Summer 2006 tables.xls;
%let outpath = D:\DCData\Libraries\HsngMon\Reports\2006-2;

proc format;
  value dtrngA 
    '01jan2005'd - '31dec2005'd = '2005'
    '01jan2004'd - '31dec2004'd = '2004'
    '01jan1999'd - '31dec2003'd = '1999-2003'
    '01jan1995'd - '31dec1998'd = '1995-1998';
  value dtrngB
    '01oct2005'd - '31dec2005'd = '2005 Q4'
    '01jul2005'd - '30sep2005'd = '2005 Q3'
    '01oct2004'd - '31dec2004'd = '2004 Q4'
    '01oct1999'd - '31dec1999'd = '1999 Q4'
    '01oct1995'd - '31dec1995'd = '1995 Q4'
    other = ' ';
    
data Sales_adj;

  set HsngMon.Sales_clean_final;
  
  where cluster_tr2000 ~= '' and Ward2002 ~= '';
  
  %dollar_convert( saleprice, saleprice_adj, saledate_yr, 2005 )
  
run;

/** Macro Table1_data - Start Definition **/

%macro Table1_data( ui_proptype= );

title2 "UI_PROPTYPE = &ui_proptype";

proc summary data=Sales_adj;
  where ui_proptype = &ui_proptype;
  class saledate ward2002;
  var saleprice_adj;
  output out=avg_sales (where=(_type_ in (2,3)) rename=(_freq_=num_sales))
    median=;
  format saledate dtrngA.;

run;

data avg_sales;

  set avg_sales;
  
  /**** NO LONGER DOING SALES PER QUARTER *****
  select ( put( saledate, dtrngA. ) );
    when ( '2005' ) avg_sales = num_sales / 4;
    when ( '2004' ) avg_sales = num_sales / 4;
    when ( '1999-2003' ) avg_sales = num_sales / ( 5 * 4 );
    when ( '1995-1998' ) avg_sales = num_sales / ( 4 * 4 );
  end;
  *********************************************/
  
  ** Calculate sales per year **;
  
  select ( put( saledate, dtrngA. ) );
    when ( '2005' ) avg_sales = num_sales;
    when ( '2004' ) avg_sales = num_sales;
    when ( '1999-2003' ) avg_sales = num_sales / ( 5 );
    when ( '1995-1998' ) avg_sales = num_sales / ( 4 );
  end;

  saleprice_adj = saleprice_adj / 1000;
  
run;

proc sort data=avg_sales;
  by descending saledate ward2002;

proc print;

run;

proc summary data=Sales_adj;
  where ui_proptype = &ui_proptype and put( saledate, dtrngB. ) ~= '';
  class saledate ward2002;
  var saleprice_adj;
  output out=qtr_sales (where=(_type_ in (2,3)) rename=(_freq_=num_sales))
    median=;
  format saledate dtrngB.;

run;

proc sort data=qtr_sales;
  by ward2002 saledate;

proc transpose data=qtr_sales out=qtr_sales_tr prefix=price;
  by ward2002;
  id saledate;
  var saleprice_adj;

proc print;

data sales_chg;

  set qtr_sales_tr;
  
  saledate = 4;
  **** NB: Quarter to quarter change is not annualized *****;
  price_chg = 100 * %annchg( price2005_q3, price2005_q4, 1 );
  output;
  
  saledate = 3;
  price_chg = 100 * %annchg( price2004_q4, price2005_q4, 1 );
  output;

  saledate = 2;
  price_chg = 100 * %annchg( price1999_q4, price2005_q4, 6 );
  output;

  saledate = 1;
  price_chg = 100 * %annchg( price1995_q4, price2005_q4, 10 );
  output;
  
  drop _name_;

run;

proc sort data=sales_chg;
  by descending saledate ward2002;
  
proc print;

run;

title2;

%mend Table1_data;

/** End Macro Definition **/


/** Macro Output_Table1 - Start Definition **/

%macro Output_Table1( start_row=, var=, data= );

  /*%let start_row = 12;*/
  %let start_col = 3;

  %let end_row = %eval( &start_row + 3 );
  %let end_col = %eval( &start_col + 8 );

  %let start_cell = r&start_row.c&start_col;
  %let end_cell = r&end_row.c&end_col;

  filename xout dde "excel|&outpath\[&outfile]Table 1!&start_cell:&end_cell" lrecl=256;

  data _null_;

    file xout;
    
    set &data;
    by descending saledate;
    
    put &var @;
    
    if last.saledate then put;
    
  run;

  filename xout clear;

%mend Output_Table1;

/** End Macro Definition **/

** Single family **;

%Table1_data( ui_proptype='10' )

%Output_Table1( start_row=12, var=avg_sales, data=avg_sales )

%Output_Table1( start_row=17, var=saleprice_adj, data=avg_sales )

%Output_Table1( start_row=22, var=price_chg, data=sales_chg )

** Condominiums **;

%Table1_data( ui_proptype='11' )

%Output_Table1( start_row=33, var=avg_sales, data=avg_sales )

%Output_Table1( start_row=38, var=saleprice_adj, data=avg_sales )

%Output_Table1( start_row=43, var=price_chg, data=sales_chg )

