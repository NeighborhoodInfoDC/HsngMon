/**************************************************************************
 Program:  Table1b.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  11/03/06
 Version:  SAS 8.2
 Environment:  Windows
 
 Description:  DC Housing Monitor Table 1. 
 Home Sales and Section 8 Housing by Ward, Washington, D.C., 1995-2006 Q2
 
 Part B:
 - Percent units sold, owner occupants (2005 & 2006 Q2)

 Modifications:
**************************************************************************/

***%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";
%include "C:\DCData\SAS\Inc\Stdhead.sas";

** Define libraries **;
%DCData_lib( HsngMon )

%let end_dt = '01oct2006'd;
%let sales_data = HsngMon.Sales_clean_2007_2;
%let path = &_dcdata_path\HsngMon\Prog\2007-2;
%let workbook = DC Housing Monitor Spring 2007 tables.xls;
%let sheet = Table 1;

*options obs=100;

proc format;
  /** Date ranges for labeling median sales price **/
  value lblA 
    '01jul2006'd -< &end_dt = '2006 Q3'
    '01apr2006'd -< '01jul2006'd = '2006 Q2'
    '01jan2006'd -< '01apr2006'd = '2006 Q1'
    '01jan2005'd - '31dec2005'd = '2005'
    '01jan2001'd - '31dec2004'd = '2001-2004'
    '01jan1996'd - '31dec2000'd = '1996-2000';


data Sales_adj (compress=no);

  set &sales_data;
  
  where cluster_tr2000 ~= '' and Ward2002 ~= '';
  
  %dollar_convert( saleprice, saleprice_adj, saledate_yr, 2006 )
  
  owner_occ_sale = 100 * owner_occ_sale;
  
run;


proc tabulate data=Sales_adj format=8.2 noseps out=tabdat;
  where '01jan2006'd <= saledate < &end_dt;
  class ui_proptype saledate ward2002;
  var owner_occ_sale;
  table 
    ui_proptype,
    saledate, 
    owner_occ_sale * mean * ( all='DC' ward2002 )
    / condense ;
  format saledate lblA.;


run;

proc sort data=tabdat;
  by ui_proptype descending saledate ward2002;

proc print data=tabdat;

run;


/** Macro Output_Table1 - Start Definition **/

%macro Output_Table1( start_row=, var=, data=, ui_proptype=, fmt=lblA. );

  /*%let start_row = 12;*/
  %let start_col = 2;

  %let end_row = %eval( &start_row + 5 );
  %let end_col = %eval( &start_col + 8 + 1 );

  %let start_cell = r&start_row.c&start_col;
  %let end_cell = r&end_row.c&end_col;

  filename xout dde "excel|&path\[&workbook]&sheet!&start_cell:&end_cell" lrecl=1000 notab;

  data _null_;

    file xout;
    
    set &data (where=(ui_proptype=&ui_proptype));
    by descending saledate;
    
    if first.saledate then put saledate &fmt @;
    
    put '09'x &var @;
    
    if last.saledate then put;
    
  run;

  filename xout clear;

%mend Output_Table1;

/** End Macro Definition **/

** Single family **;

%Output_Table1( start_row=31, var=owner_occ_sale_mean, ui_proptype='10', data=tabdat )

%Output_Table1( start_row=57, var=owner_occ_sale_mean, ui_proptype='11', data=tabdat )

