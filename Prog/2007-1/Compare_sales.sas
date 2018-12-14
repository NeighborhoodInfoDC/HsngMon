/**************************************************************************
 Program:  Compare_sales.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  10/31/06
 Version:  SAS 8.2
 Environment:  Windows
 
 Description:  Compare current and previous sales data.

 Modifications:
**************************************************************************/

%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";

** Define libraries **;
%DCData_lib( HsngMon )

proc compare base=HsngMon.sales_clean_final compare=HsngMon.sales_clean_final_2006_3 maxprint=(40,32000);
  id ssl saledate;

run;

