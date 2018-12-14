/**************************************************************************
 Program:  Table2a.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  08/09/06
 Version:  SAS 8.2
 Environment:  Windows
 
 Description:  DC Housing Monitor Table 2. 
 Home Sales and Section 8 Housing by Ward, Washington, D.C., 1995-2005
 
 Part A:
 - Number of Sales
 - Median sales price (2005 $ thousands)
 - Percent change, median sales price
 
 Nb:  Does not include Percent units sold, owner occupants and 
 Housing Units in Section 8 Multifamily Projects.

 Modifications:
**************************************************************************/

%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";

** Define libraries **;
%DCData_lib( HsngMon )

%let path = D:\DCData\Libraries\HsngMon\Reports\2006-3;
%let workbook = DC Housing Monitor Fall 2006 tables.xls;
%let sheet = Table 2;


proc format;
  value dtrngA 
    '01jan2006'd - '31mar2006'd = '2006 Q1'
    '01jan2005'd - '31dec2005'd = '2005'
    '01jan2000'd - '31dec2004'd = '2000-2004 (annual average)'
    '01jan1996'd - '31dec1999'd = '1996-1999 (annual average)';
  value dtrngB
    '01jan2006'd - '31mar2006'd = '2006 Q1'
    '01oct2005'd - '31dec2005'd = '2005 Q4'
    '01jan2005'd - '31mar2005'd = '2005 Q1'
    '01jan2000'd - '31mar2000'd = '2000 Q1'
    '01jan1996'd - '31mar1996'd = '1996 Q1'
    other = ' ';
  value lblB
    4 = '2005 Q4 - 2006 Q1'
    3 = '2005 Q1 - 2006 Q1'
    2 = '2000 Q1 - 2006 Q1 (annualized)'
    1 = '1996 Q1 - 2006 Q1 (annualized)';
    
data Sales_adj;

  set HsngMon.Sales_clean_final;
  
  where cluster_tr2000 ~= '' and Ward2002 ~= '' and
    ( '01jan1996'd <= saledate < '01apr2006'd );
  
  %dollar_convert( saleprice, saleprice_adj, saledate_yr, 2006 )
  
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
    when ( '2006 Q1' ) avg_sales = num_sales;
    when ( '2005' ) avg_sales = num_sales;
    when ( '2000-2004 (annual average)' ) avg_sales = num_sales / ( 5 );
    when ( '1996-1999 (annual average)' ) avg_sales = num_sales / ( 4 );
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
  price_chg = 100 * %annchg( price2005_q4, price2006_q1, 1 );
  output;
  
  saledate = 3;
  price_chg = 100 * %annchg( price2005_q1, price2006_q1, 1 );
  output;

  saledate = 2;
  price_chg = 100 * %annchg( price2000_q1, price2006_q1, 6 );
  output;

  saledate = 1;
  price_chg = 100 * %annchg( price1996_q1, price2006_q1, 10 );
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

%macro Output_Table1( start_row=, var=, data=, fmt=dtrngA. );

  /*%let start_row = 12;*/
  %let start_col = 2;

  %let end_row = %eval( &start_row + 3 );
  %let end_col = %eval( &start_col + 8 + 1 );

  %let start_cell = r&start_row.c&start_col;
  %let end_cell = r&end_row.c&end_col;

  filename xout dde "excel|&path\[&workbook]&sheet!&start_cell:&end_cell" lrecl=1000 notab;

  data _null_;

    file xout;
    
    set &data;
    by descending saledate;
    
    if first.saledate then put saledate &fmt @;
    
    put '09'x &var @;
    
    if last.saledate then put;
    
  run;

  filename xout clear;

%mend Output_Table1;

/** End Macro Definition **/

** Single family **;

%Table1_data( ui_proptype='10' )

%Output_Table1( start_row=12, var=avg_sales, data=avg_sales )

%Output_Table1( start_row=17, var=saleprice_adj, data=avg_sales )

%Output_Table1( start_row=22, var=price_chg, data=sales_chg, fmt=lblB. )

** Condominiums **;

%Table1_data( ui_proptype='11' )

%Output_Table1( start_row=33, var=avg_sales, data=avg_sales )

%Output_Table1( start_row=38, var=saleprice_adj, data=avg_sales )

%Output_Table1( start_row=43, var=price_chg, data=sales_chg, fmt=lblB. )

