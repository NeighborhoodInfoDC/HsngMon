/**************************************************************************
 Program:  Table3.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  04/07/07
 Version:  SAS 9.1
 Environment:  Windows
 
 Description:  Create Housing Monitor table 3.

 Modifications:
**************************************************************************/

***%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";
%include "C:\DCData\SAS\Inc\Stdhead.sas";

** Define libraries **;
%DCData_lib( HsngMon )

*options mprint symbolgen mlogic;

%Init_macro_vars( rpt_yr=2007, rpt_qtr=4 )

%Make_sales_formats( )

%S8ReportDates( hud_file_date='09/25/2007' )

******  Section 8  ******;

%Table_Sec8MF( dde=n, sheet=Table 3, start_row=9 )

run;
