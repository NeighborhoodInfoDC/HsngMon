/**************************************************************************
 Program:  Table1b.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  11/03/06
 Version:  SAS 8.2
 Environment:  Windows
 
 Description:  DC Housing Monitor Table 1. 
 Home Sales and Section 8 Housing by Ward, Washington, D.C., 1995-2006 Q2
 
 Part B:
 - Percent units sold, owner occupants (2005 & 2006 Q2)

 Modifications:
**************************************************************************/

%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";

** Define libraries **;
%DCData_lib( HsngMon )

%let end_dt = '01jul2006'd;

*options obs=100;

proc format;
  /** Date ranges for labeling median sales price **/
  value lblA 
    '01apr2006'd -< &end_dt = '2006 Q2'
    '01jan2006'd -< '01apr2006'd = '2006 Q1'
    '01jan2005'd - '31dec2005'd = '2005'
    '01jan2001'd - '31dec2004'd = '2001-2004'
    '01jan1996'd - '31dec2000'd = '1996-2000';


data Sales_adj;

  set HsngMon.Sales_clean_final;
  
  where cluster_tr2000 ~= '' and Ward2002 ~= '';
  
  %dollar_convert( saleprice, saleprice_adj, saledate_yr, 2006 )
  
  owner_occ_sale = 100 * owner_occ_sale;
  
run;


proc tabulate data=Sales_adj format=8.2 noseps;
  where '01jan2005'd <= saledate < &end_dt;
  class ui_proptype saledate ward2002;
  var owner_occ_sale;
  table 
    ui_proptype,
    saledate, 
    owner_occ_sale * mean * ( all='DC' ward2002 )
    / condense ;
  format saledate lblA.;


run;
