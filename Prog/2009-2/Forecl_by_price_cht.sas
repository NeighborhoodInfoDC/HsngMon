/**************************************************************************
 Program:  Forecl_by_price_cht.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  04/29/09
 Version:  SAS 9.1
 Environment:  Windows
 
 Description:  Compare foreclosure levels with changes in home prices
 by neighborhood cluster.
 
 Also create mapping file (HsngMon.Map1_2009_2).

 Modifications:
**************************************************************************/

%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";

** Define libraries **;
%DCData_lib( HsngMon )

proc sort data=HsngMon.Table4_2009_2 (where=(cluster_tr2000~='' and ui_proptype='10')) 
    out=Price;
  by cluster_tr2000;
  
proc sort data=HsngMon.Forecl_cluster_tbl_2009_2 (where=(cluster_tr2000~=''))
    out=Foreclosures;
  by cluster_tr2000;

data Forecl_by_price;

  merge Price Foreclosures;    
  by cluster_tr2000;

run;

proc print data=Forecl_by_price;
  id cluster_tr2000;
  var chg_price_2007_2008 foreclosure_start_rate in_foreclosure_end;
run;

proc corr data=Forecl_by_price;
  var chg_price_2007_2008 chg_price_2003_2008 chg_price_1998_2008 saleprice_adj_2008;
  with foreclosure_start_rate in_foreclosure_end_rate foreclosure_sale_rate;
run;

proc plot data=Forecl_by_price;
  plot foreclosure_start_rate * chg_price_2007_2008;
  plot in_foreclosure_end_rate * chg_price_2007_2008;
  plot foreclosure_sale_rate * chg_price_2007_2008;
  plot foreclosure_start_rate * saleprice_adj_2008;
  plot in_foreclosure_end_rate * saleprice_adj_2008;
  plot foreclosure_sale_rate * saleprice_adj_2008;
run;

proc reg data=Forecl_by_price;
  where foreclosure_start_rate < 40;
  model foreclosure_start_rate = saleprice_adj_2008;
  model foreclosure_start_rate = saleprice_adj_2008 chg_price_2003_2008;
run;


data HsngMon.Map1_2009_2 (compress=no);

  retain cluster_tr2000 ward2002 saleprice_adj_2008 foreclosure_start_rate foreclosure_start;

  set Forecl_by_price;
  
  keep ward2002 cluster_tr2000 foreclosure_start_rate saleprice_adj_2008 foreclosure_start;
  
  rename foreclosure_start_rate=fcl_st_rt saleprice_adj_2008=pr_adj_08 foreclosure_start=fcl_start;
  
run;

proc sort data=HsngMon.Map1_2009_2;
  by ward2002 cluster_tr2000;

filename fexport "&_dcdata_path\HsngMon\Prog\2009-2\Forecl_by_price.csv" lrecl=256;

proc export data=HsngMon.Map1_2009_2
    outfile=fexport
    dbms=csv replace;

run;

filename fexport clear;

