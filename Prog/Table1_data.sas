/**************************************************************************
 Program:  Table1_data.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  08/05/07
 Version:  SAS 9.1
 Environment:  Windows
 
 Description:  Autocall macro to create data for 
 Housing Monitor Table 1.

 Modifications:
  11/22/07 PAT Filter sales by date using dtrngA. format.
**************************************************************************/

/** Macro Table1_data - Start Definition **/

%macro Table1_data( ui_proptype= );

title2 "UI_PROPTYPE = &ui_proptype";

** Base set of sales obs. **;

data Sales_adj;

  set HsngMon.Sales_clean_&g_rpt_yr._&g_rpt_qtr;
  
  where cluster_tr2000 ~= '' and Ward2002 ~= '' and ui_proptype = &ui_proptype and
        put( saledate, dtrngA. ) ~= '';

  owner_occ_sale = 100 * owner_occ_sale;

run;

** Number of sales & median sales price **;

proc summary data=Sales_adj;
  class saledate ward2002;
  var saleprice_adj;
  output out=avg_sales (where=(_type_ in (2,3)) rename=(_freq_=num_sales))
    median=;
  format saledate dtrngA.;

run;

data avg_sales;

  set avg_sales;
  
  ** Calculate sales per year **;
  
  length lbl $ 255;
  
  lbl = put( saledate, dtrngA. );
  
  if index( lbl, 'Q' ) then avg_sales = num_sales;   /** Not annualized **/
  else if index( lbl, '(annual average)' ) then do;
    stryr = input( lbl, 4. );
    endyr = input( substr( lbl, 6, 4 ), 4. );
    avg_sales = num_sales / ( ( endyr - stryr ) + 1 );
  end;
  else avg_sales = num_sales;
  
  saleprice_adj = saleprice_adj / 1000;
  
run;

proc sort data=avg_sales;
  by descending saledate ward2002;

proc print;
 title3 'File = avg_sales';

run;

title3;

** Percent change, median sales price **;

proc summary data=Sales_adj;
  where put( saledate, dtrngB. ) ~= '';
  class saledate ward2002;
  var saleprice_adj;
  output out=qtr_sales (where=(_type_ in (2,3)) rename=(_freq_=num_sales))
    median=;
  format saledate dtrngB.;

run;

proc sort data=qtr_sales;
  by ward2002 saledate;

proc transpose data=qtr_sales out=qtr_sales_tr prefix=price;
  by ward2002;
  id saledate;
  var saleprice_adj;

proc print;
  title3 'File = qtr_sales';
run;

title3;

data sales_chg;

  set qtr_sales_tr;
  
  saledate = 4;
  **** NB: Quarter to quarter change is not annualized *****;
  price_chg = 100 * %annchg( &g_price_b, &g_price_a, 1 );
  output;
  
  saledate = 3;
  price_chg = 100 * %annchg( &g_price_c, &g_price_a, 1 );
  output;

  saledate = 2;
  price_chg = 100 * %annchg( &g_price_d, &g_price_a, 5 );
  output;

  saledate = 1;
  price_chg = 100 * %annchg( &g_price_e, &g_price_a, 10 );
  output;
  
  drop _name_;

run;

proc sort data=sales_chg;
  by descending saledate ward2002;
  
proc print;
  title3 'File = sales_chg';

run;

title3;

** Owner-occupied sales **;

proc tabulate data=Sales_adj format=8.2 noseps out=own_occ_sales;
  *where '01jan2006'd <= saledate < &end_dt;
  *where year( saledate ) = &g_sales_end_yr;
  where put( saledate, lst4qtr. ) ~= '';
  class ui_proptype ward2002;
  class saledate / descending;
  var owner_occ_sale;
  table 
    ui_proptype,
    saledate, 
    owner_occ_sale * mean * ( all='DC' ward2002 )
    / condense ;
  format saledate /*lblA.*/ lst4qtr.;

run;

proc sort data=own_occ_sales;
  by descending saledate ward2002;

proc print data=own_occ_sales;
  title3 'File = own_occ_sales';
  
run;

title2;

%mend Table1_data;

/** End Macro Definition **/

