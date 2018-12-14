%include "[dcdata]stdhead.sas";

%Dcdata_lib( RealProp )
%Dcdata_lib( HsngMon )

filename xptFile "[dcdata.hsngmon.data]Sales_clean_2007_3.cpt";

data Sales_clean_2007_3 (compress=no);

  set RealProp.Sales_res_clean;

  where '01jan1996'd <= saledate <= '31dec2006'd;

  saledate_yr = year( saledate );

  %dollar_convert( saleprice, saleprice_adj, saledate_yr, 2006 )

  keep ssl saleprice saleprice_adj saledate ui_proptype ward2002 cluster_tr2000 saledate_yr owner_occ_sale;

run;

%File_info( data=Sales_clean_2007_3 )

proc cport data=Sales_clean_2007_3 file=xptFile;

run;

