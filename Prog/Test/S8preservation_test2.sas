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

%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";

** Define libraries **;
%DCData_lib( HsngMon )

** Define libraries **;
%DCData_lib( HsngMon )
%DCData_lib( HUD )

%Init_macro_vars( rpt_yr=2007, rpt_qtr=4 )

%S8ReportDates( hud_file_date='09/25/2007' )

%let prev_rpt_file = S8summary_2007_3;

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

%let FILTER = CONTRACT_NUMBER IN ( 'DC390001013', 'DC39K100004', 'DC398023018', 'DC390005015', 'DC39K100002' );

%S8preservation( dde=&dde )

%File_info( data=S8losses, stats= )

%File_info( data=S8losses_det, stats=, printobs=500 )

proc print data=S8losses_det;
  where &FILTER;
  by contract_number;
  id rpt_date;
  var 
    loss_date cur_assisted_units_count active_units cum_lost_units expired_units
    lost_units terminated_units;
run;


