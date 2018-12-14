/**************************************************************************
 Program:  Map1_2009_3.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  09/21/09
 Version:  SAS 9.1
 Environment:  Windows
 
 Description:  Export data for Housing Monitor Map 1, neighborhood
cluster price changes.
Summer-Fall 2009

 Modifications:
**************************************************************************/

%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";

** Define libraries **;
%DCData_lib( HsngMon )

data HsngMon.Map1_2009_3 (compress=no);

  set HsngMon.table4_20093;
  
  where Cluster_tr2000 ~= '';
  
  keep Cluster_tr2000 chg_price_1998_2008 chg_price_2003_2008 chg_price_2007_2008;
  
  array a{*} chg_price_1998_2008 chg_price_2003_2008 chg_price_2007_2008;
  
  do i = 1 to dim( a );
    if missing( a{i} ) then a{i} = -999999;
  end;
  
  rename chg_price_1998_2008=chpr98_08 chg_price_2003_2008=chpr03_08 chg_price_2007_2008=chpr07_08;
  
  format Cluster_tr2000 ;

run;

proc print data=HsngMon.Map1_2009_3 (Obs=100);
  
run;
