/**************************************************************************
 Program:  Print_ssl.sas
 Library:  ROD
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  04/24/09
 Version:  SAS 9.1
 Environment:  Windows
 
 Description:

 Modifications:
**************************************************************************/

%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";

** Define libraries **;
%DCData_lib( ROD )
%DCData_lib( RealProp )
%DCData_lib( HsngMon )

%let ssl = '0028    2051';

data Foreclosures / view=Foreclosures;

  set
    Rod.Foreclosures_1997
    Rod.Foreclosures_1998
    Rod.Foreclosures_1999
    Rod.Foreclosures_2000
    Rod.Foreclosures_2001 
    Rod.Foreclosures_2002 
    Rod.Foreclosures_2003 
    Rod.Foreclosures_2004 
    Rod.Foreclosures_2005
    Rod.Foreclosures_2006
    Rod.Foreclosures_2007 
    Rod.Foreclosures_2008
    Rod.Foreclosures_2009
  ;
 
run;

title2 "Rod.Foreclosures_history";

data _null_;
  set Rod.Foreclosures_history;
  where ssl in ( &ssl );
  file print;
  put / '--- ' ssl= ' -----------------';
  put (_all_) (= /);
run;


proc print data=Rod.Foreclosures_history;
  where ssl in ( &ssl );
  by ssl;
  id order;
  var firstnotice_date lastnotice_date tdeed_date prev_sale_date post_sale_date next_sale_date outcome_date outcome_code2;
  format post_sale_date mmddyy10.;
run;

proc print data=HsngMon.Foreclosures_qtr_2009_2;
  where ssl in ( &ssl );
  by ssl;
  id dt;
  var firstnotice_date outcome_date start_dt end_dt outcome_code 
      in_foreclosure foreclosure_start foreclosure_sale distressed_sale foreclosure_avoided;
  title2 "HsngMon.Foreclosures_qtr_2009_2";
run;

proc print data=RealProp.Sales_master;
  where ssl in ( &ssl );
  by ssl;
  id sale_num;
  var saledate saleprice ownername_full acceptcode owner_occ_sale;
run;

proc print data=Foreclosures;
  where ssl in ( &ssl );
  by ssl;
  id filingdate;
  var ui_instrument grantee grantor; 
run;

run;
