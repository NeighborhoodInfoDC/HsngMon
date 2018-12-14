/**************************************************************************
 Program:  Table3.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  04/07/07
 Version:  SAS 9.1
 Environment:  Windows
 
 Description:  Create Housing Monitor table 3 (Section 8 monitoring).

 Modifications:
**************************************************************************/

%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";

** Define libraries **;
%DCData_lib( HsngMon )
%DCData_lib( HUD )

*options mprint symbolgen mlogic;

%Init_macro_vars( rpt_yr=2008, rpt_qtr=1 )

%Make_sales_formats( )

%S8ReportDates( hud_file_date='12/28/2007' )

******  Section 8  ******;

%S8preservation_data()

%Table_Sec8MF( dde=y, sheet=Table 3, start_row=9 )

run;
