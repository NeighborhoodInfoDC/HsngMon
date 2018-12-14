/**************************************************************************
 Program:  S8preservation_test.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  01/28/08
 Version:  SAS 9.1
 Environment:  Windows
 
 Description:  Test S8 preservation report.

 Modifications:
**************************************************************************/

***%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";
%include "C:\DCData\SAS\Inc\Stdhead.sas";

** Define libraries **;
%DCData_lib( HsngMon )

** Define libraries **;
%DCData_lib( HsngMon )
%DCData_lib( HUD )

%Init_macro_vars( rpt_yr=2008, rpt_qtr=1 )

%S8ReportDates( hud_file_date='12/28/2007' )

%let prev_rpt_file = S8summary_2007_4;

%let dde = n;                          %** Send output to DDE (Y/N) **;

**** Don't change below this line ****;
%let data = Hud.Sec8mf_current_dc;
%let rpt_file = S8summary_&g_rpt_yr._&g_rpt_qtr;
%let rpt_xls  = &rpt_file..xls;
%let map_file = &rpt_file;

%let BLANK = '20'x;    ** Blank character for DDE output **;

%fdate()

** Create report formats **;

%Format_prevqtrs()

%Format_nextqtrs()

%Format_qtrsgrph()

%Format_misszero()


*******************************************
******  Preservation summary report  ******
*******************************************;

%let FILTER = CONTRACT_NUMBER IN ( 'DC390001013', 'DC39K100004', 'DC398023018', 
                                   'DC390005015', 'DC39M000099', 'DC39M000033',
                                   'DC39M000023' );

%let FILTER = CONTRACT_NUMBER IN ( 'DC390014006', 'DC390005015', 'DC39H001005' );

%let FILTER = CONTRACT_NUMBER IN ( 'DC39T802001', 'DC39M000046', 'DC39L000078', 'DC39L000075', 'DC39L000013' );

%S8preservation( dde=&dde )

proc print data=History;
  *where &FILTER;
  id contract_number;
  by contract_number;
  var contract_hist_rec date_cur_contract assisted_units_count total_unit_count;
title2 'File=History';
run;

title2;

%File_info( data=S8losses_det, stats=, printobs=5 )

proc print data=S8losses_det;
  where &FILTER;
  by contract_number;
  id rpt_date;
  var 
    loss_date assisted_units_count active_units 
    expired_units terminated_units lost_units cum_lost_units;
  title2 'File = S8losses_det';
run;

proc print data=S8losses_det;
  where /*year( rpt_date ) = 2004 and*/ lost_units < 0;
  by contract_number;
  id rpt_date;
  var 
    loss_date assisted_units_count active_units 
    expired_units terminated_units lost_units cum_lost_units;
  title2 'Contracts with increase in active units';
run;
