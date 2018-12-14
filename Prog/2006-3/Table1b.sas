/**************************************************************************
 Program:  Table1b.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  04/11/06
 Version:  SAS 8.2
 Environment:  Windows
 
 Description:  DC Housing Monitor Table 1. 
 Home Sales and Section 8 Housing by Ward, Washington, D.C., 1995-2005
 
 Part B:
 - Percent units sold, owner occupants (2004 & 2005)

 Modifications:
**************************************************************************/

%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";

** Define libraries **;
%DCData_lib( HsngMon )

*options obs=100;

data Sales_adj;

  set HsngMon.Sales_clean_final;
  
  where cluster_tr2000 ~= '' and Ward2002 ~= '';
  
  %dollar_convert( saleprice, saleprice_adj, saledate_yr, 2005 )
  
  owner_occ_sale = 100 * owner_occ_sale;
  
run;


proc tabulate data=Sales_adj format=8.2 noseps;
  where 2004 <= year( saledate ) <= 2005;
  class ui_proptype saledate ward2002;
  var owner_occ_sale;
  table 
    ui_proptype,
    saledate, 
    owner_occ_sale * mean * ( all='DC' ward2002 )
    / condense ;
  format saledate year4.;


run;
