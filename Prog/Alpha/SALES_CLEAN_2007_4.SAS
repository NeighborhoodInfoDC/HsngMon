%include "[dcdata]stdhead.sas";

%Dcdata_lib( RealProp )
%Dcdata_lib( HsngMon )

filename xptFile "[dcdata.hsngmon.data]Sales_clean_2007_4.cpt";

data Sales_clean_2007_4 (compress=no);

  set RealProp.Sales_res_clean;

  where '01jan1996'd <= saledate <= '31mar2007'd;

  saledate_yr = year( saledate );

  %dollar_convert( saleprice, saleprice_adj, saledate_yr, 2007 )

  pct_owner_occ_sale = 100 * owner_occ_sale;

  label
    saledate_yr = "Property sale year"
    saleprice_adj = "Property sale price (2007 $)"
    pct_owner_occ_sale = "Pct. owner-occupied sale";

  keep ssl saleprice saledate ui_proptype ward2002 cluster_tr2000 saledate_yr owner_occ_sale
       saleprice_adj pct_owner_occ_sale ;

run;

%File_info( data=Sales_clean_2007_4 )

proc tabulate data=SALES_CLEAN_2007_4 missing noseps;
  var pct_owner_occ_sale;
  class saledate_yr;
  table all='Total' saledate_yr=' ', pct_owner_occ_sale * (n nmiss mean);
run;

proc cport data=Sales_clean_2007_4 file=xptFile;

run;

