/**************************************************************************
 Program:  Table3.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  08/07/06
 Version:  SAS 8.2
 Environment:  Windows
 
 Description:  HsngMon Table 4. HMDA
 
 Output (must be open before running program):  
   D:\DCData\Libraries\HsngMon\Reports\2006-3\DC Housing Monitor Fall 2006 tables.xls

 Modifications:
  08/11/06  Added pct. lone female borrowers
**************************************************************************/

%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";

** Define libraries **;
%DCData_lib( HsngMon )
%DCData_lib( General )

%let path = D:\DCData\Libraries\HsngMon\Reports\2006-3;
%let workbook = DC Housing Monitor Fall 2006 tables.xls;
%let sheet = Table 3;

/** Macro Output_table3 - Start Definition **/

%macro Output_Table3( start_row=, var=, data=Table3, num_rows=4 );

  %let end_row = %eval( &start_row + ( &num_rows - 1 ) );

  %let start_col = 3;

  %do i = 1 %to 9;

    %let start_cell = r&start_row.c&start_col;
    %let end_cell = r&end_row.c&start_col;
  
    filename xout&i dde "excel|&path\[&workbook]&sheet!&start_cell:&end_cell" lrecl=256;
    
    %let start_col = %eval( &start_col + 1 );
    
  %end;
    
  data _null_;

    set &data;
    
    select ( _n_ );
      when ( 1 ) file xout1;
      when ( 2 ) file xout2;
      when ( 3 ) file xout3;
      when ( 4 ) file xout4;
      when ( 5 ) file xout5;
      when ( 6 ) file xout6;
      when ( 7 ) file xout7;
      when ( 8 ) file xout8;
      when ( 9 ) file xout9;
    end;
    
    %let i = 1;
    %let years = 2004 2003 1999_2002 1995_1998; 
    %let onevar = %scan( &years, &i );
    
    %do %until ( &onevar = );
      put &var&onevar;
      %let i = %eval( &i + 1 );
      %let onevar = %scan( &years, &i );
    %end;
    
  run;

  filename _all_ clear;

%mend Output_Table3;

/** End Macro Definition **/

/** Macro Pct_stats - Start Definition **/

%macro Pct_stats( var=, num=, den= );

  &var.2004 = 100 * ( &num.2004 / &den.2004 );
  &var.2003 = 100 * ( &num.2003 / &den.2003 );
  
  if sum( of &den.1999 - &den.2002 ) > 0 then
    &var.1999_2002 = 100 * ( sum( of &num.1999 - &num.2002 ) / sum( of &den.1999 - &den.2002 ) );
    
  if sum( of &den.1995 - &den.1998 ) > 0 then
    &var.1995_1998 = 100 * ( sum( of &num.1995 - &num.1998 ) / sum( of &den.1995 - &den.1998 ) );

%mend Pct_stats;

/** End Macro Definition **/



data Table3;

  set HsngMon.Hmda_city HsngMon.Hmda_wd02;
  
  newmort2004 = 100 * nummrtgorighomepurch_2004 / units_sf_condo_2004;
  newmort2003 = 100 * nummrtgorighomepurch_2003 / units_sf_condo_2003;
  newmort1999_2002 = 100 * mean( of nummrtgorighomepurch_1999 - nummrtgorighomepurch_2002 ) / units_sf_condo_2002;
  newmort1995_1998 = 100 * mean( of nummrtgorighomepurch_1995 - nummrtgorighomepurch_1998 ) / units_sf_condo_2001;
  
  mrtgmedhomepur_adj_1999_2002 = mean( of mrtgmedhomepur_adj_1999 - mrtgmedhomepur_adj_2002 );
  mrtgmedhomepur_adj_1995_1998 = mean( of mrtgmedhomepur_adj_1995 - mrtgmedhomepur_adj_1998 );
  
  chg_mrgmed2004 = 100 * %annchg( mrtgmedhomepur_adj_2003, mrtgmedhomepur_adj_2004, 1 );
  chg_mrgmed2003 = 100 * %annchg( mrtgmedhomepur_adj_2002, mrtgmedhomepur_adj_2003, 1 );
  chg_mrgmed1999_2002 = 100 * %annchg( mrtgmedhomepur_adj_1999, mrtgmedhomepur_adj_2002, 2002 - 1999 );
  chg_mrgmed1995_1998 = 100 * %annchg( mrtgmedhomepur_adj_1995, mrtgmedhomepur_adj_1998, 1998 - 1995 );
  
  medianmrtginc_adj_1999_2002 = mean( of medianmrtginc_adj_1999 - medianmrtginc_adj_2002 );
  medianmrtginc_adj_1995_1998 = mean( of medianmrtginc_adj_1995 - medianmrtginc_adj_1998 );
  
  %pct_stats( var=pctsubprime, num=numsubprimemrtgorighomepur_, den=numconvmrtgorighomepurch_ )
  
  %pct_stats( var=pcthighcost, num=NumHighCostConvOrigPurch_, den=DenHighCostConvOrigPurch_ )

  %pct_stats( var=pctinvest, num=NumMrtgInvest_, den=nummrtgorighomepurch_ )
  
  %pct_stats( var=pctblack, num=NumMrtgOrigBlack_, den=NumMrtgOrigWithRace_ )
  %pct_stats( var=pctwhite, num=NumMrtgOrigWhite_, den=NumMrtgOrigWithRace_ )
  %pct_stats( var=pctHisp, num=NumMrtgOrigHisp_, den=NumMrtgOrigWithRace_ )
  %pct_stats( var=pctasianpi, num=NumMrtgOrigasianpi_, den=NumMrtgOrigWithRace_ )
  
  %pct_stats( var=pctnorace, num=NumMrtgOrigRaceNotProvided_, den=nummrtgorigtotal_ )
  
  %pct_stats( var=pctdenied, num=nummrtgpurchdenial_, den=nummrtgpurchapps_ )
  
  %pct_stats( var=pctfemale, num=NumMrtgOrigHomePurch_F_, den=NumMrtgOrigHomePurch_sex_ ) 
  
run;

** Loan Volume and Characteristics **;

%Output_Table3( start_row=12, var=newmort )

%Output_Table3( start_row=18, var=mrtgmedhomepur_adj_ )

%Output_Table3( start_row=24, var=chg_mrgmed )

%Output_Table3( start_row=30, var=pctdenied )

%Output_Table3( start_row=36, var=pctsubprime )

%Output_Table3( start_row=42, var=pcthighcost, num_rows=1 )

** Borrower Characteristics **;

%Output_Table3( start_row=47, var=medianmrtginc_adj_ )

%Output_Table3( start_row=53, var=pctinvest )

%Output_Table3( start_row=59, var=pctblack )

%Output_Table3( start_row=65, var=pctwhite )

%Output_Table3( start_row=71, var=pcthisp )

%Output_Table3( start_row=77, var=pctasianpi )

%Output_Table3( start_row=83, var=pctfemale, num_rows=2 )

** Race reporting **;

proc print data=Table3 (obs=1);
  var pctnorace: ;
run;

  