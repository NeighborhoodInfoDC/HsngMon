/**************************************************************************
 Program:  Qtrly_sales.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  04/06/06
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
  value dtrngA 
    '01jan2005'd - '31dec2005'd = '2005'
    '01jan2004'd - '31dec2004'd = '2004'
    '01jan1999'd - '31dec2003'd = '1999-2003'
    '01jan1995'd - '31dec1998'd = '1995-1998';
  value dtrngB
    '01oct2005'd - '31dec2005'd = '2005 Q4'
    '01jul2005'd - '30sep2005'd = '2005 Q3'
    '01oct2004'd - '31dec2004'd = '2004 Q4'
    '01oct2000'd - '31dec2000'd = '2000 Q4'
    '01oct1999'd - '31dec1999'd = '1999 Q4'
    '01oct1995'd - '31dec1995'd = '1995 Q4'
    other = ' ';


data Sales_adj;

  set HsngMon.Sales_clean_final;
  
  where cluster_tr2000 ~= '' and Ward2002 ~= '';
  
  %dollar_convert( saleprice, saleprice_adj, saledate_yr, 2005 )
  
run;


proc tabulate data=Sales_adj format=comma16. noseps missing;
  where put( saledate, dtrngB. ) ~= '';
  class saledate ui_proptype;
  var saleprice_adj;
  table 
    ui_proptype=' ',
    saledate='By quarter', 
    n='Number of sales'
    saleprice_adj='Price ($ 2005)' * median=' '
    / box=_page_ row=float condense;
  format saledate dtrngB. ui_proptype $uiprtyp.;

run;

