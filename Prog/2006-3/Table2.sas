/**************************************************************************
 Program:  Table2.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  04/04/06
 Version:  SAS 8.2
 Environment:  Windows
 
 Description:  DC Housing Monitor Table 2.
 Home Sales by Housing Market Typology and Neighborhood Cluster, 
 Washington, D.C., 1995-2005

 Modifications:
  05/03/06 PT  Added condominium sales to table.
               Changed sales/qtr to total sales.
**************************************************************************/

%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";

** Define libraries **;
%DCData_lib( HsngMon )
%DCData_lib( General )

%let outfile = DC Housing Monitor Summer 2006 tables.xls;
%let outpath = D:\DCData\Libraries\HsngMon\Reports\2006-2;

*options obs=100;

data Sales_adj;

  set HsngMon.Sales_clean_final (keep=ui_proptype cluster_tr2000 Ward2002 saleprice saledate_yr);
  
  ** Select only single-family homes with non-missing cluster or ward IDs **;
  
  where ui_proptype in ( '10', '11' ) and cluster_tr2000 ~= '' and Ward2002 ~= '';
  
  ** Create housing market typology variable **;
  
  nbrhd_type = put( cluster_tr2000, $clhmt5f. );
  
  format nbrhd_type $hmt05f. cluster_tr2000 $CLUS00S.;
  
  ** Create var. SALEPRICE_ADJ = sales price in thousands $ 2005 **;
    
  %dollar_convert( saleprice / 1000, saleprice_adj, saledate_yr, 2005 )
  
run;

** Summarize sales by cluster and housing market typology **;

proc summary data=Sales_adj;
  class ui_proptype saledate_yr nbrhd_type cluster_tr2000;
  var saleprice_adj;
  output out=med_price (where=(_type_ in (12,14,15)) rename=(_freq_=num_sales))
    median=;

run;

** Transpose data to put years in columns           **;
** NB:  Each variable must be transposed separately **;

proc sort data=med_price;
  by ui_proptype nbrhd_type cluster_tr2000 saledate_yr;

*proc print;

proc transpose data=med_price out=num_sales_tr (drop=_name_) prefix=num_sales;
  var num_sales;
  id saledate_yr;
  by ui_proptype nbrhd_type cluster_tr2000;

proc transpose data=med_price out=med_price_tr (drop=_name_) prefix=price;
  var saleprice_adj;
  id saledate_yr;
  by ui_proptype nbrhd_type cluster_tr2000;

** Merge transposed data together **;

data Table2;

  merge num_sales_tr med_price_tr;
  by ui_proptype nbrhd_type cluster_tr2000;
  
  /***** NO LONGER USING SALES PER QUARTER *******
  ** Convert number of sales to avg. sales per quarter **;
  
  array sales{*} num_sales: ;
  
  do i = 1 to dim( sales );
    sales{i} = sales{i} / 4;
  end;
  ****************************************************/
  
  ** Calculate annual pct. price changes **;
  
  chg_price_1995_2005 = 100 * %annchg( price1995, price2005, 2005 - 1995 );
  chg_price_2000_2005 = 100 * %annchg( price2000, price2005, 2005 - 2000 );
  chg_price_2004_2005 = 100 * %annchg( price2004, price2005, 2005 - 2004 );
  
  keep ui_proptype nbrhd_type cluster_tr2000 num_sales: price: chg_price_: ;
  
run;

proc print data=Table2;
  by ui_proptype;

run;


**** Write data to Excel table ****;

/** Macro Output_table2 - Start Definition **/

%macro Output_table2( start_row=, end_row=, where= );

  filename xout dde 
    "excel|&outpath\[&outfile]Table 2!R&start_row.C1:R&end_row.C13" 
    lrecl=512 notab;

  data _null_;

    file xout;
    
    set Table2 (where=(&where));
    by nbrhd_type;
    
    cluster_num = input( cluster_tr2000, 2. );
    
    if nbrhd_type = '' then 
      put 'Washington, D.C. Total' '09'x '09'x '09'x '09'x @;
    else if Cluster_tr2000 = '' then 
      put nbrhd_type '09'x '09'x '09'x '09'x @;
    else
      put '09'x cluster_num '09'x '09'x Cluster_tr2000 '09'x @;
      
    put num_sales1995 '09'x num_sales2000 '09'x num_sales2005 '09'x @;
    put price1995 '09'x price2000 '09'x price2005 '09'x @;
    put chg_price_1995_2005 '09'x chg_price_2000_2005 '09'x chg_price_2004_2005;
    
    if last.nbrhd_type then put;
    
  run;

  filename xout clear;

%mend Output_table2;

/** End Macro Definition **/


** Single-family homes **;

%Output_table2( 
  start_row = 11, 
  end_row = 64, 
  where = nbrhd_type ~= '9' and ui_proptype = '10' 
)

** Condos **;

%Output_table2( 
  start_row = 68, 
  end_row = 77, 
  where = nbrhd_type in ( ' ', '7' ) and ui_proptype = '11' 
)



proc print data=Table2;
  where ui_proptype = '11';
  by ui_proptype;
  id nbrhd_type Cluster_tr2000 ;
  var num_sales1995 num_sales2000 num_sales2005;

run;

