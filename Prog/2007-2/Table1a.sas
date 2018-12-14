/**************************************************************************
 Program:  Table1a.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  02/12/07
 Version:  SAS 9.1
 Environment:  Windows
 
 Description:  DC Housing Monitor Spring 2007: Table 1. 
 Home Sales and Section 8 Housing by Ward, Washington, D.C., 1995-2006 Q3
 
 Part A:
 - Number of Sales
 - Median sales price (2006 $ thousands)
 - Percent change, median sales price
 
 Nb:  Does not include Percent units sold, owner occupants and 
 Housing Units in Section 8 Multifamily Projects.

 Modifications:
  11/21/06 PAT Separated 1st & 2nd quarters for sales & price.
**************************************************************************/

***%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";
%include "C:\DCData\SAS\Inc\Stdhead.sas";

** Define libraries **;
%DCData_lib( HsngMon )

%let path = &_dcdata_path\HsngMon\Prog\2007-2;
%let workbook = DC Housing Monitor Spring 2007 tables.xls;
%let sheet = Table 1;
%let end_dt = '01oct2006'd;
%let sales_data = HsngMon.Sales_clean_2007_2;

proc format;
  /** Date ranges for calculating no. sales and median price, labeling number of sales **/
  value dtrngA 
    '01jul2006'd -< &end_dt = '2006 Q3'
    '01apr2006'd -< '01jul2006'd = '2006 Q2'
    '01jan2006'd -< '01apr2006'd = '2006 Q1'
    '01jan2005'd - '31dec2005'd = '2005'
    '01jan2001'd - '31dec2004'd = '2001-2004 (annual average)'
    '01jan1996'd - '31dec2000'd = '1996-2000 (annual average)';
  /** Date ranges for labeling median sales price **/
  value lblA 
    '01jul2006'd -< &end_dt = '2006 Q3'
    '01apr2006'd -< '01jul2006'd = '2006 Q2'
    '01jan2006'd -< '01apr2006'd = '2006 Q1'
    '01jan2005'd - '31dec2005'd = '2005'
    '01jan2001'd - '31dec2004'd = '2001-2004'
    '01jan1996'd - '31dec2000'd = '1996-2000';
  /** Dates ranges for calculating qtr-to-qtr changes **/
  value dtrngB
    '01jul2006'd -< '01oct2006'd = '2006 Q3'
    '01apr2006'd -< '01jul2006'd = '2006 Q2'
    '01jul2005'd -< '01oct2005'd = '2005 Q3'
    '01jul2001'd -< '01oct2001'd = '2001 Q3'
    '01jul1996'd -< '01oct1996'd = '1996 Q3'
    other = ' ';
  /** Date ranges for labeling qtr-to-qtr changes **/
  value lblB
    4 = '2006 Q2 - 2006 Q3'
    3 = '2005 Q3 - 2006 Q3'
    2 = '2001 Q3 - 2006 Q3 (annualized)'
    1 = '1996 Q3 - 2006 Q3 (annualized)';
    
data Sales_adj (compress=no);

  set &sales_data;
  
  where cluster_tr2000 ~= '' and Ward2002 ~= '' and
    ( '01jan1996'd <= saledate < &end_dt );
  
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
  
  ** Calculate sales per year **;
  
  select ( put( saledate, dtrngA. ) );
    when ( '2006 Q1', '2006 Q2', '2006 Q3' ) avg_sales = num_sales;   /** Not annualized **/
    when ( '2005' ) avg_sales = num_sales;
    when ( '2001-2004 (annual average)' ) avg_sales = num_sales / ( ( 2004 - 2001 ) + 1 );
    when ( '1996-2000 (annual average)' ) avg_sales = num_sales / ( ( 2000 - 1996 ) + 1 );
    otherwise do;
      %err_put( msg="Invalid sales date range. " saledate= )
    end;
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
  price_chg = 100 * %annchg( price2006_q2, price2006_q3, 1 );
  output;
  
  saledate = 3;
  price_chg = 100 * %annchg( price2005_q3, price2006_q3, 1 );
  output;

  saledate = 2;
  price_chg = 100 * %annchg( price2001_q3, price2006_q3, 5 );
  output;

  saledate = 1;
  price_chg = 100 * %annchg( price1996_q3, price2006_q3, 10 );
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

  %let end_row = %eval( &start_row + 5 );
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

%Output_Table1( start_row=19, var=saleprice_adj, data=avg_sales, fmt=lblA. )

%Output_Table1( start_row=26, var=price_chg, data=sales_chg, fmt=lblB. )

** Condominiums **;

%Table1_data( ui_proptype='11' )

%Output_Table1( start_row=38, var=avg_sales, data=avg_sales )

%Output_Table1( start_row=45, var=saleprice_adj, data=avg_sales, fmt=lblA. )

%Output_Table1( start_row=52, var=price_chg, data=sales_chg, fmt=lblB. )

