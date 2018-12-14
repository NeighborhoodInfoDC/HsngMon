/**************************************************************************
 Program:  Recheck_expired.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  02/27/07
 Version:  SAS 9.1
 Environment:  Windows
 
 Description:  Recheck expired projects from previous HM report with
latest data.

 Modifications:
**************************************************************************/

%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";
***%include "C:\DCData\SAS\Inc\Stdhead.sas";

** Define libraries **;
%DCData_lib( HsngMon )
%DCData_lib( HUD )

%let rpt_yr = 2007;
%let rpt_qtr = 2;

%let prev_rpt_yr = 2007;
%let prev_rpt_qtr = 1;

data Updated_projects;

  merge
    HsngMon.S8Summary_&rpt_yr._&rpt_qtr
    HsngMon.S8Summary_&prev_rpt_yr._&prev_rpt_qtr (keep=contract_number exp_contracts where=(exp_contracts > 0) in=inPrev);
  by contract_number;
  
  if inPrev;
  
run;

proc print data=Updated_projects noobs n="Contracts = ";
   **by contract_number;
   id contract_number;
   var date_cur_contract ward2002 cur_assisted_units_count rpt_status cur_tracs_status cur_expiration_date prev_expiration_date;
   format /*report $report. */
     date_cur_contract cur_expiration_date prev_expiration_date mmddyy8.;
   title2 "Project-by-project comparison with previous Section 8 file";
   title3 "Project contract status changes (PREVIOUSLY EXPIRED)";
run;

proc freq data=Updated_projects;
  tables  rpt_status / missing;
run;

proc tabulate data=Updated_projects format=comma12.0 noseps missing;
  class  rpt_status;
  var cur_assisted_units_count;
  table
    all='Total'  rpt_status,
    cur_assisted_units_count=' ' * ( n='Contracts' sum='Assisted Units' ) ;

run;

ENDSAS;
/*
proc compare 
  base=HsngMon.S8Summary_&prev_rpt_yr._&prev_rpt_qtr (where=(exp_contracts > 0))
  compare=HsngMon.S8Summary_&rpt_yr._&rpt_qtr 
  maxprint=(40,32000);
  id contract_number ward2002;
  var cur_ui_status cur_tracs_status exp_ren_date date_cur_contract cur_expiration_date prev_expiration_date 
      exp_contracts exp_units;
      

run;
*/

%let prev_rpt_file = S8Summary_&prev_rpt_yr._&prev_rpt_qtr;
%let rpt_file = S8Summary_&rpt_yr._&rpt_qtr;

** Project contract status changes **;

proc format;
  value $report
    'BASE' = 'Winter 07'
    'COMPARE' = 'Spring 07';

proc compare 
  base=HsngMon.&prev_rpt_file (where=(exp_contracts > 0))
  compare=HsngMon.&rpt_file maxprint=(100,32000)
  out=result (drop=_obs_ rename=(_type_=Report)) outnoequal outbase outcomp noprint;
  id contract_number ward2002;
  var cur_assisted_units_count cur_ui_status rpt_status date_cur_contract cur_expiration_date prev_expiration_date;
run;

proc print data=result noobs;
   by contract_number;
   id contract_number;
   format report $report. 
     date_cur_contract cur_expiration_date prev_expiration_date mmddyy8.;
   title2 "Project-by-project comparison with previous Section 8 file";
   title3 "Project contract status changes (PREVIOUSLY EXPIRED)";
run;

title2;

