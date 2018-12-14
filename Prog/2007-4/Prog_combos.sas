/**************************************************************************
 Program:  Prog_combos.sas
 Library:  Nlihc
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  11/29/07
 Version:  SAS 9.1
 Environment:  Windows
 
 Description:  Program combinations.

 Modifications:
**************************************************************************/

***%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";
%include "C:\DCData\SAS\Inc\Stdhead.sas";

** Define libraries **;
%DCData_lib( Nlihc )

%let vars =
    s8 s8lm s8pd s8sa s8othnew s8othrehab lihtc 
    s202 s202dlp74 s202dl s221d3 s221d4 s236da s236 
    cdbg home hptf mckinney pubhsng tebond;
    
data A;

  set Nlihc.Preservation_cat (keep=NLIHC_ID program);

  array a{*} &vars;

  do i = 1 to dim( a );
    a{i} = 0;
  end;

  select ( program );
    when ( '202 Direct Loan/ Elderly/ Pre - 1974' ) s202dlp74 = 1;
    when ( '202/8 Direct Loan/ Elderly-Handicapped' ) s202dl = 1;
    when ( '221(d)(3) BMIR Urban Renewal/ Coop Hsg' ) s221d3 = 1;
    when ( '221(d)(4) Mkt. Rate Mod Inc/ Disp Fams' ) s221d4 = 1;
    when ( '236(j)(1)/ 223(e)/Lower Income Families/Declin. Ar' ) s236da = 1;
    when ( '236(j)(1)/ Lower Income Families' ) s236 = 1;
    when ( 'CDBG' ) cdbg = 1;
    when ( 'HOME' ) home = 1;
    when ( 'Housing Production Trust Fund' ) hptf = 1;
    when ( 'LIHTC' ) lihtc = 1;
    when ( 'McKinney Act Loan' ) mckinney = 1;
    when ( 'Other S8 New' ) s8othnew = 1;
    when ( 'Other S8 Rehab' ) s8othrehab = 1;
    when ( 'PRAC 202/811' ) DELETE;
    when ( 'Public Housing' ) pubhsng = 1;
    when ( 'S8 Loan Mgmt' ) s8lm = 1;
    when ( 'S8 Prop. Disp.' ) s8pd = 1;
    when ( 'S8 State Agency' ) s8sa = 1;
    when ( 'Sec. 202' ) s202 = 1;
    when ( 'Section 8' ) s8 = 1;
    when ( 'Tax-Exempt Bond' ) tebond = 1;
    otherwise /** do nothing **/;
  end;

run;

proc summary data=A nway;
  class NLIHC_ID;
  var &vars;
  output out=B (drop=_type_ _freq_) sum=;
  
run;

proc means data=B n sum min max;

proc print data=B;
  where s236da > 1 or s236 > 1;
  id NLIHC_ID;

data B2;

  set B;

  num_progs = sum( of &vars );
  
  s8_progs = sum( of s8: );
  
run;

proc print data=B2;
  where num_progs >= 5;
  id NLIHC_ID;
  var &vars;
run;

proc summary data=B nway;
  class &vars;
  output out=C (drop=_type_);

data Prog_combos;

  set C;
  
  num_progs = sum( of &vars );
  
  s8_progs = sum( of s8: );
  
run;

proc sort data=Prog_combos;
  by descending num_progs descending s8_progs descending _freq_;

proc print data=Prog_combos noobs;
  *where num_progs > 1;
  var num_progs s8_progs _freq_ &vars;

run;

proc means data=Prog_combos n sum min max;

