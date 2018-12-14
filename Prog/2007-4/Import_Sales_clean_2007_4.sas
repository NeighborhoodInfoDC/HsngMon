/**************************************************************************
 Program:  Import_Sales_clean_2007_4.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  11/22/07
 Version:  SAS 9.1
 Environment:  Windows
 
 Description:  Import Sales_clean_2007_4 file.

 Modifications:
**************************************************************************/

***%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";
%include "C:\DCData\SAS\Inc\Stdhead.sas";

** Define libraries **;
%DCData_lib( HsngMon )

filename tranfile "&_dcdata_path\hsngmon\data\Sales_clean_2007_4.cpt";

proc cimport library=HsngMon infile=tranfile;
run;

%File_info( data=HsngMon.Sales_clean_2007_4, freqvars=ward2002 cluster_tr2000 )

proc freq data=HsngMon.Sales_clean_2007_4;
  tables saledate;
  format saledate yyq.;

run;
