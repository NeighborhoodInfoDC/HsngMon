/**************************************************************************
 Program:  Qtrly_sales.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  11/03/06
 Version:  SAS 8.2
 Environment:  Windows
 
 Description:  Figure 1. Single-family home and condominium quarter-to-
 quarter sales trends.

 Modifications:
**************************************************************************/

***%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";
%include "C:\DCData\SAS\Inc\Stdhead.sas";

** Define libraries **;
%DCData_lib( HsngMon )
%DCData_lib( RealProp )

%Init_macro_vars( rpt_yr=2007, rpt_qtr=3 )

%Make_sales_formats()

%macro skip;
proc format;
  /** Dates ranges for calculating qtr-to-qtr changes **/
  value dtrngB
    '01jul2006'd -< '01oct2006'd = '2006 Q3'
    '01apr2006'd -< '01jul2006'd = '2006 Q2'
    '01jul2005'd -< '01oct2005'd = '2005 Q3'
    '01jul2001'd -< '01oct2001'd = '2001 Q3'
    '01jul1996'd -< '01oct1996'd = '1996 Q3'
    other = ' ';
%mend skip;

data Sales_adj;

  set &sales_data;
  
  where cluster_tr2000 ~= '' and Ward2002 ~= '';
  
run;


proc tabulate data=HsngMon.Sales_clean_&g_rpt_yr._&g_rpt_qtr format=comma16. noseps missing;
  where cluster_tr2000 ~= '' and Ward2002 ~= '' and put( saledate, dtrngB. ) ~= '';
  class saledate ui_proptype;
  var saleprice_adj;
  table 
    ui_proptype=' ',
    saledate='By quarter', 
    n='Number of sales'
    saleprice_adj='Price ($ 2006)' * median=' '
    / box=_page_ row=float condense;
  format saledate dtrngB. ui_proptype $uiprtyp.;

run;

