/**************************************************************************
 Program:  Temp.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  10/08/07
 Version:  SAS 9.1
 Environment:  Windows
 
 Description:

 Modifications:
**************************************************************************/

***%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";
%include "C:\DCData\SAS\Inc\Stdhead.sas";

** Define libraries **;
%DCData_lib( HsngMon )

proc freq data=HsngMon.Sales_clean_2007_3;
  where saledate_yr in ( 2005, 2006 ) and ui_proptype = '11' and ward2002 = '6';
  tables saledate_yr * cluster_tr2000;

proc print data=HsngMon.Sales_clean_2007_3;
  where saledate_yr = 2005 and ui_proptype = '11' and ward2002 = '6';
  id ssl;
  var saledate saleprice_adj; 

run;
