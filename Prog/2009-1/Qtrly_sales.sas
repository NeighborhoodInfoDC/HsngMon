/**************************************************************************
 Program:  Qtrly_sales.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  11/23/07
 Version:  SAS 8.2
 Environment:  Windows
 
 Description:  Figure 1. Single-family home and condominium quarter-to-
 quarter sales trends.

 Modifications:
**************************************************************************/

%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";

** Define libraries **;
%DCData_lib( HsngMon )
%DCData_lib( RealProp )

%Init_macro_vars( rpt_yr=2009, rpt_qtr=1 )

%Make_sales_formats()

proc tabulate data=HsngMon.Sales_clean_&g_rpt_yr._&g_rpt_qtr format=comma16. noseps missing;
  where cluster_tr2000 ~= '' and Ward2002 ~= '' and put( saledate, dtrngB. ) ~= '';
  class saledate ui_proptype;
  var saleprice_adj;
  table 
    ui_proptype=' ',
    saledate='By quarter', 
    n='Number of sales'
    saleprice_adj="Price ($ &g_sales_end_yr)" * median=' '
    / box=_page_ row=float condense;
  format saledate dtrngB. ui_proptype $uiprtyp.;

run;

