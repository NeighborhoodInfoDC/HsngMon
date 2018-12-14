/**************************************************************************
 Program:  Table1.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  11/22/07
 Version:  SAS 9.1
 Environment:  Windows
 
 Description:  Create Housing Monitor table 1.

 Modifications:
**************************************************************************/

***%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";
%include "C:\DCData\SAS\Inc\Stdhead.sas";

** Define libraries **;
%DCData_lib( HsngMon )

options mprint symbolgen mlogic;

%Init_macro_vars( rpt_yr=2007, rpt_qtr=4 )

%Make_sales_formats()

******  Single family  ******;

%Table1_data( ui_proptype='10' )

** Number of sales **;

%Table1_output( start_row=12, var=avg_sales, data=avg_sales, dde=n )

** Median sales price **;

%Table1_output( start_row=20, var=saleprice_adj, data=avg_sales, fmt=lblA., dde=n )

** Percent change, median sales price **;

%Table1_output( start_row=28, var=price_chg, data=sales_chg, fmt=lblB., dde=n )

** Owner-occupied sales **;

%Table1_output( start_row=33, var=owner_occ_sale_mean, data=own_occ_sales, fmt=lst4qtr., dde=n )


******  Condominiums  ******;

%Table1_data( ui_proptype='11' )

** Number of sales **;

%Table1_output( start_row=41, var=avg_sales, data=avg_sales, dde=n )

** Median sales price **;

%Table1_output( start_row=49, var=saleprice_adj, data=avg_sales, fmt=lblA., dde=n )

** Percent change, median sales price **;

%Table1_output( start_row=57, var=price_chg, data=sales_chg, fmt=lblB., dde=n )

** Owner-occupied sales **;

%Table1_output( start_row=62, var=owner_occ_sale_mean, data=own_occ_sales, fmt=lst4qtr., dde=n )


run;
