/**************************************************************************
 Program:  Assisted_units.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  11/29/07
 Version:  SAS 9.1
 Environment:  Windows
 
 Description:  Create counts of assisted units by program.

 Modifications:
  12/05/07 PAT Added date range for end of affordability.
**************************************************************************/

***%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";
%include "C:\DCData\SAS\Inc\Stdhead.sas";

** Define libraries **;
%DCData_lib( HsngMon )
%DCData_lib( Nlihc )

%let MAXPROGS = 8;
%let PUBHSNG  = 1;
%let S8PROG   = 2;
%let LIHTC    = 3;
%let HOME     = 4;
%let CDBG     = 5;
%let HPTF     = 6;
%let TEBOND   = 7;
%let OTHER    = 8;

/*
Public Housing only
Section 8 only
LIHTC only
HOME only
CDBG only
HPTF only
Other single subsidy

LIHTC and Tax Exempt Bond only

Section 8 and other subsidies

All other combinations
*/

proc format;
  value ProgCat (notsorted)
    1 = 'Public Housing only'
    2 = 'Section 8 only'
    9 = 'Section 8 and other subsidies'
    3 = 'LIHTC only'
    4 = 'HOME only'
    5 = 'CDBG only'
    6 = 'HPTF only'
    /*7 = 'Other single subsidy'*/
    8 = 'LIHTC and Tax Exempt Bond only'
    7, 10 = 'All other combinations';
  value ward
    1 = 'Ward 1'
    2 = 'Ward 2'
    3 = 'Ward 3'
    4 = 'Ward 4'
    5 = 'Ward 5'
    6 = 'Ward 6'
    7 = 'Ward 7'
    8 = 'Ward 8';
    

** Remove duplicate program records **;

proc summary data=Nlihc.Preservation_cat nway;
  class NLIHC_ID program;
  id ward ward2002 cluster_tr2000 ssl Proj_Name Proj_Addr_ref;
  var units_tot units_ass poa_end;
  output out=Preservation_cat (drop=_type_ _freq_) max= ;
run;

data Assisted_units;

  set Preservation_cat 
        (keep=NLIHC_ID program ward ward2002 cluster_tr2000 ssl 
              Proj_Name Proj_Addr_ref units_tot units_ass poa_end
         where=(program~='PRAC 202/811'));
  by NLIHC_ID;
  
  retain num_progs total_units min_asst_units max_asst_units asst_units1-asst_units&MAXPROGS
         poa_end_min poa_end_max;

  array a_aunits{&MAXPROGS} asst_units1-asst_units&MAXPROGS;
  
  if first.NLIHC_ID then do;
  
    total_units = .;
    num_progs = 0;
    
    min_asst_units = .;
    mid_asst_units = .;
    max_asst_units = .;
    
    poa_end_min = .;
    poa_end_max = .;

    do i = 1 to &MAXPROGS;
      a_aunits{i} = 0;
    end;
      
  end;
  
  num_progs + 1;
  
  total_units = max( total_units, units_tot, units_ass );
  
  select ( program );
  
    when ( 'Public Housing' ) a_aunits{&PUBHSNG} = units_ass;
    
    when ( 
      'S8 Loan Mgmt',
      'S8 Prop. Disp.',
      'S8 State Agency',
      'Section 8',
      'Other S8 New',
      'Other S8 Rehab'
    ) a_aunits{&S8PROG} = units_ass;
    
    when ( 'LIHTC' ) a_aunits{&LIHTC} = units_ass;
    when ( 'HOME' ) a_aunits{&HOME} = units_ass;
    when ( 'CDBG' ) a_aunits{&CDBG} = units_ass;
    when ( 'Housing Production Trust Fund' ) a_aunits{&HPTF} = units_ass;
    when ( 'Tax-Exempt Bond' ) a_aunits{&TEBOND} = units_ass;
    
    otherwise a_aunits{&OTHER} = sum( units_ass, a_aunits{&OTHER} );
    
  end;
  
  min_asst_units = max( units_ass, min_asst_units );
  
  poa_end_min = min( poa_end, poa_end_min );
  poa_end_max = min( poa_end, poa_end_max );
  
  if last.NLIHC_ID then do;
  
    do i = 1 to &MAXPROGS;
      a_aunits{i} = min( a_aunits{i}, total_units );
    end;

    max_asst_units = min( sum( of asst_units1-asst_units&MAXPROGS ), total_units );
    
    mid_asst_units = mean( min_asst_units, max_asst_units );
    
    if mid_asst_units ~= max_asst_units then err_asst_units = max_asst_units - mid_asst_units;
    
    ** Reporting categories **;
    
    if num_progs = 1 then do;
    
      if a_aunits{&PUBHSNG} > 0 then ProgCat = 1;
      else if a_aunits{&S8PROG} > 0 then ProgCat = 2;
      else if a_aunits{&LIHTC} > 0 then ProgCat = 3;
      else if a_aunits{&HOME} > 0 then ProgCat = 4;
      else if a_aunits{&CDBG} > 0 then ProgCat = 5;
      else if a_aunits{&HPTF} > 0 then ProgCat = 6;
      else if a_aunits{&TEBOND} > 0 or a_aunits{&OTHER} > 0 then ProgCat = 7;
    
    end;
    else do;
    
      if num_progs = 2 and a_aunits{&LIHTC} > 0 and a_aunits{&TEBOND} > 0 then ProgCat = 8;
      else if a_aunits{&S8PROG} > 0 then ProgCat = 9;
      else ProgCat = 10;
      
    end;
    
    select ( NLIHC_ID );
      when ( 'NL000129' ) ssl = '2864    0333';
      when ( 'NL000157' ) ssl = '6156    0119';
      when ( 'NL000191' ) ssl = 'PAR 01600036';
      when ( 'NL000205' ) ssl = '4121    0080';
      when ( 'NL000244', 'NL000245' ) ssl = '1020    0085';
      when ( 'NL000287' ) ssl = '0621    0244';
      when ( 'NL000170' ) ssl = '4049    0033';
      when ( 'NL000280' ) ssl = '5873    0921';
      when ( 'NL000324' ) ssl = '0481    0023';
      when ( 'NL000005' ) ssl = '0363    2002';  /** Condo unit? **/
      when ( 'NL000197' ) ssl = '6219    0006';
      when ( 'NL000215' ) ssl = '3698    0016';
      when ( 'NL000033' ) ssl = '6157    0806';
      when ( 'NL000054' ) ssl = '0540    0109';
      when ( 'NL000109' ) ssl = '5085    0053';
      when ( 'NL000255' ) ssl = '5725    0803';

      when ( 'NL000315' ) ssl = '6210    0039';
      when ( 'NL000354' ) ssl = '2910    0035';
      when ( 'NL000029' ) ssl = '6219    0032';
      when ( 'NL000031' ) ssl = '4544    0179';
      when ( 'NL000046' ) ssl = '2661    0219';
      when ( 'NL000137' ) ssl = '0621    0245';
      when ( 'NL000164' ) ssl = '5908    0005';
      when ( 'NL000202' ) ssl = '5057    0040';
      when ( 'NL000216' ) ssl = '0551    0231';
      when ( 'NL000222' ) ssl = '5057    0039';
      when ( 'NL000234' ) ssl = '5875    0038';
      when ( 'NL000056' ) ssl = '5279    0817';
      when ( 'NL000138' ) ssl = '0525    0840';
      when ( 'NL000148' ) ssl = '5140    0088';
      when ( 'NL000166' ) ssl = '5178    0041';
      when ( 'NL000171' ) ssl = '5359    0324';
      when ( 'NL000247' ) ssl = '5585    0034';
      when ( 'NL000260' ) ssl = '5978    0020';
      when ( 'NL000306' ) ssl = '5969    0005';
      when ( 'NL000335' ) ssl = '5735    0806';
      when ( 'NL000348' ) ssl = 'PAR 02240045';

      otherwise /** Do nothing **/;
    end;
    
    output;
  
  end;
  
  format poa_end_min poa_end_max mmddyy10.;
  
  drop i program units_tot units_ass poa_end;

run;

proc sort data=Assisted_units out=HsngMon.Assisted_units;
  by ProgCat NLIHC_ID;

%File_info( data=HsngMon.Assisted_units, printobs=0, freqvars=ProgCat )

proc print data=HsngMon.Assisted_units n='Projects = ';
  by ProgCat;
  id NLIHC_ID;
  var total_units min_asst_units mid_asst_units max_asst_units asst_units: poa_end_min poa_end_max;
  sum total_units min_asst_units mid_asst_units max_asst_units asst_units: ;
  format ProgCat ProgCat. total_units min_asst_units mid_asst_units max_asst_units asst_units: comma6.0
         poa_end_min poa_end_max mmddyy8.;
run;

ods rtf file="&_dcdata_path\HsngMon\Prog\2007-4\Assisted_units.rtf" style=Styles.Rtf_arial_9pt;

options missing='0';

proc tabulate data=HsngMon.Assisted_units format=comma10. noseps missing;
  where ProgCat ~= .;
  class ProgCat / preloadfmt order=data;
  class ward;
  var mid_asst_units err_asst_units;
  table 
    /** Rows **/
    all='\b Total' ProgCat=' ',
    /** Columns **/
    n='Projects'
    sum='Assisted Units' * ( mid_asst_units='Est.' err_asst_units='+/-' )
    ;
  table 
    /** Rows **/
    all='\b Total' ProgCat=' ',
    /** Columns **/
    sum='Assisted Units by Ward' * ward=' ' * ( mid_asst_units='Est.' err_asst_units='+/-' )
    ;
  format ProgCat ProgCat. ward ward.;
  
run;

ods rtf close;
