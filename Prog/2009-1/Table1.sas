/**************************************************************************
 Program:  Table1.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  11/22/07
 Version:  SAS 9.1
 Environment:  Windows
 
 Description:  Create Housing Monitor table 1.
 
 NB: Adjust start_row= values after reformatting workbook.

 Modifications:
**************************************************************************/

%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";

** Define libraries **;
%DCData_lib( HsngMon )
%DCData_lib( RealProp )

options mprint symbolgen mlogic;

%Init_macro_vars( rpt_yr=2009, rpt_qtr=1 )

%Make_sales_formats()

******  Single family  ******;

%Table1_data( ui_proptype='10' )

** Number of sales **;

%Table1_output( start_row=12, var=avg_sales, data=avg_sales, dde=y )

** Median sales price **;

%Table1_output( start_row=21, var=saleprice_adj, data=avg_sales, fmt=lblA., dde=y )

** Percent change, median sales price **;

%Table1_output( start_row=30, var=price_chg, data=sales_chg, fmt=lblB., dde=y )

** Owner-occupied sales **;

%Table1_output( start_row=35, var=owner_occ_sale_mean, data=own_occ_sales, fmt=lst4qtr., dde=y )


******  Condominiums  ******;

%Table1_data( ui_proptype='11' )

** Number of sales **;

%Table1_output( start_row=43, var=avg_sales, data=avg_sales, dde=y )

** Median sales price **;

%Table1_output( start_row=52, var=saleprice_adj, data=avg_sales, fmt=lblA., dde=y )

** Percent change, median sales price **;

%Table1_output( start_row=61, var=price_chg, data=sales_chg, fmt=lblB., dde=y )

** Owner-occupied sales **;

%Table1_output( start_row=66, var=owner_occ_sale_mean, data=own_occ_sales, fmt=lst4qtr., dde=y )


run;
