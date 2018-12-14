/**************************************************************************
 Program:  Table3.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  02/13/07
 Version:  SAS 9.1
 Environment:  Windows
 
 Description:  HsngMon Table 3. HMDA
 
 Output (must be open before running program):  
   D:\DCData\Libraries\HsngMon\Reports\2007-2\DC Housing Monitor Spring 2007 tables.xls

 Modifications:
  08/11/06  Added pct. lone female borrowers
**************************************************************************/

%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";
***%include "C:\DCData\SAS\Inc\Stdhead.sas";

** Define libraries **;
%DCData_lib( HsngMon )

%let path = &_dcdata_path\HsngMon\Reports\2007-2;
%let workbook = DC Housing Monitor Spring 2007 tables.xls;
%let sheet = Table 3;

*options obs=0;

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
    %let years = 2005 2004 2001_2003 1997_2000; 
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

  &var.2005 = 100 * ( &num.2005 / &den.2005 );
  &var.2004 = 100 * ( &num.2004 / &den.2004 );
  
  if sum( of &den.2001 - &den.2003 ) > 0 then
    &var.2001_2003 = 100 * ( sum( of &num.2001 - &num.2003 ) / sum( of &den.2001 - &den.2003 ) );
    
  if sum( of &den.1997 - &den.2000 ) > 0 then
    &var.1997_2000 = 100 * ( sum( of &num.1997 - &num.2000 ) / sum( of &den.1997 - &den.2000 ) );

%mend Pct_stats;

/** End Macro Definition **/

data Table3 (compress=no);

  set HsngMon.Hmda_2007_2;
  
  ** Number of home purchase loans **;
  
  newmort2005 = nummrtgorighomepurch1_4m_2005;
  newmort2004 = nummrtgorighomepurch1_4m_2004;
  newmort2001_2003 = mean( of nummrtgorighomepurch1_4m_2001 - nummrtgorighomepurch1_4m_2003 );
  newmort1997_2000 = mean( of nummrtgorighomepurch1_4m_1997 - nummrtgorighomepurch1_4m_2000 );
  
  ** Number of home purchase loans per 100 units **;
  
  newmortperunit2005 = 100 * nummrtgorighomepurch1_4m_2005 / units_sf_condo_2005;
  newmortperunit2004 = 100 * nummrtgorighomepurch1_4m_2004 / units_sf_condo_2004;
  newmortperunit2001_2003 = 100 * mean( of nummrtgorighomepurch1_4m_2001 - nummrtgorighomepurch1_4m_2003 ) / units_sf_condo_2003;
  newmortperunit1997_2000 = 100 * mean( of nummrtgorighomepurch1_4m_1997 - nummrtgorighomepurch1_4m_2000 ) / units_sf_condo_2001;
  
  ** Median mortgage amount **;
  
  mrtgmedhomepur_adj_2001_2003 = mean( of mrtgmedhomepur_adj_2001 - mrtgmedhomepur_adj_2003 );
  mrtgmedhomepur_adj_1997_2000 = mean( of mrtgmedhomepur_adj_1997 - mrtgmedhomepur_adj_2000 );
  
  chg_mrgmed2005 = 100 * %annchg( mrtgmedhomepur_adj_2004, mrtgmedhomepur_adj_2005, 1 );
  chg_mrgmed2004 = 100 * %annchg( mrtgmedhomepur_adj_2003, mrtgmedhomepur_adj_2004, 1 );
  chg_mrgmed2001_2003 = 100 * %annchg( mrtgmedhomepur_adj_2001, mrtgmedhomepur_adj_2003, 2003 - 2001 );
  chg_mrgmed1997_2000 = 100 * %annchg( mrtgmedhomepur_adj_1997, mrtgmedhomepur_adj_2000, 2000 - 1997 );
  
  ** Median borrower income **;
  
  medianmrtginc1_4m_a_2001_2003 = mean( of medianmrtginc1_4m_a_2001 - medianmrtginc1_4m_a_2003 );
  medianmrtginc1_4m_a_1997_2000 = mean( of medianmrtginc1_4m_a_1997 - medianmrtginc1_4m_a_2000 );
  
  ** Subprime lending **;
  
  %pct_stats( var=pctsubprime, num=numsubprimeconvorighomepur_, den=NumConvMrtgOrigHomePurch_ )
  
  ** High cost loans **;
  
  %pct_stats( var=pcthighcost, num=NumHighCostConvOrigPurch_, den=DenHighCostConvOrigPurch_ )
  
  ** Investor loans **;
  
  %pct_stats( var=pctinvest, num=NumMrtgInvest_, den=NumMrtgOrigHomePurch1_4m_ )
  
  ** Borrowers by race **;
  
  %pct_stats( var=pctblack, num=NumMrtgOrigBlack_, den=NumMrtgOrigWithRace_ )
  %pct_stats( var=pctwhite, num=NumMrtgOrigWhite_, den=NumMrtgOrigWithRace_ )
  %pct_stats( var=pctHisp, num=NumMrtgOrigHisp_, den=NumMrtgOrigWithRace_ )
  %pct_stats( var=pctasianpi, num=NumMrtgOrigasianpi_, den=NumMrtgOrigWithRace_ )
  
  %pct_stats( var=pctnorace, num=NumMrtgOrigRaceNotProvided_, den=MrtgOrigPurchOwner1_4m_ )
  
  ** Denial rates **;
  
  %pct_stats( var=pctdenied, num=NumMrtgPurchDenial_, den=denmrtgpurchdenial_ )
  
  ** Lone female borrowers **;
  
  %pct_stats( var=pctfemale, num=nummrtgorighomepurch_f_, den=nummrtgorighomepurch_sex_ ) 
  
run;


** Loan Volume and Characteristics **;

%Output_Table3( start_row=12, var=newmort )

%Output_Table3( start_row=18, var=newmortperunit )

%Output_Table3( start_row=24, var=mrtgmedhomepur_adj_ )

%Output_Table3( start_row=30, var=chg_mrgmed )

%Output_Table3( start_row=36, var=pctdenied )

%Output_Table3( start_row=42, var=pctsubprime )

%Output_Table3( start_row=48, var=pcthighcost, num_rows=2 )

** Borrower Characteristics **;

%Output_Table3( start_row=54, var=medianmrtginc1_4m_a_ )

%Output_Table3( start_row=60, var=pctinvest )

%Output_Table3( start_row=66, var=pctblack )

%Output_Table3( start_row=72, var=pctwhite )

%Output_Table3( start_row=78, var=pcthisp )

%Output_Table3( start_row=84, var=pctasianpi )

%Output_Table3( start_row=90, var=pctfemale )

** Race reporting **;

proc print data=Table3 (obs=1);
  var pctnorace: ;
  title2 "Percentage of loans without race reported";
run;

  