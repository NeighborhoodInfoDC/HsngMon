/**************************************************************************
 Program:  Qtrly_sales.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  08/10/06
 Version:  SAS 8.2
 Environment:  Windows
 
 Description:  Figure 2. Single-family home and condominium quarter-to-
 quarter sales trends.

 Modifications:
**************************************************************************/

%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";

** Define libraries **;
%DCData_lib( HsngMon )
%DCData_lib( RealProp )

proc format;
  value dtrngB
    '01jan2006'd - '31mar2006'd = '2006 Q1'
    '01oct2005'd - '31dec2005'd = '2005 Q4'
    '01jan2005'd - '31mar2005'd = '2005 Q1'
    '01jan2001'd - '31mar2001'd = '2001 Q1'
    '01jan1996'd - '31mar1996'd = '1996 Q1'
    other = ' ';


data Sales_adj;

  set HsngMon.Sales_clean_final;
  
  where cluster_tr2000 ~= '' and Ward2002 ~= '';
  
  %dollar_convert( saleprice, saleprice_adj, saledate_yr, 2006 )
  
run;


proc tabulate data=Sales_adj format=comma16. noseps missing;
  where put( saledate, dtrngB. ) ~= '';
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

