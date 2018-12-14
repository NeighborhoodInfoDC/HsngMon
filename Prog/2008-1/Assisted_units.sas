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
  02/13/08 PAT Removed properties with lost_rental = 1.
  02/25/08 PAT Added x_coord, y_coord to kept geographies.
**************************************************************************/

%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";
***%include "C:\DCData\SAS\Inc\Stdhead.sas";

** Define libraries **;
%DCData_lib( HsngMon )
%DCData_lib( Nlihc )
%DCData_lib( HUD )

%let MAXPROGS = 8;
%let PUBHSNG  = 1;
%let S8PROG   = 2;
%let LIHTC    = 3;
%let HOME     = 4;
%let CDBG     = 5;
%let HPTF     = 6;
%let TEBOND   = 7;
%let OTHER    = 8;

%let keep_geo = ward ward2002 cluster_tr2000 x_coord y_coord;

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
    8 = 'LIHTC and Tax Exempt Bond only'
    4 = 'HOME only'
    5 = 'CDBG only'
    6 = 'HPTF only'
    /*7 = 'Other single subsidy'*/
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
  value $s8cond (default=50)
    'S8 Loan Mgmt',
    'S8 Prop. Disp.',
    'S8 State Agency',
    'Section 8',
    'Other S8 New',
    'Other S8 Rehab' = 'SECTION 8';

** Remove duplicate program records **;

proc summary data=Nlihc.Preservation_cat nway;
  where not lost_rental;
  class NLIHC_ID program;
  id &keep_geo ssl Proj_Name Proj_Addr_ref property_id source_code;
  var units_tot units_ass poa_end;
  output out=Preservation_cat (drop=_type_ _freq_) max= ;
run;

** Consolidate Section 8 program records **;

proc summary data=Preservation_cat nway;
  class NLIHC_ID program;
  id &keep_geo ssl Proj_Name Proj_Addr_ref property_id source_code;
  var poa_end units_tot units_ass ;
  format program $s8cond.;
  output out=Preservation_cat2 (drop=_type_ _freq_)
    max( poa_end units_tot )=
    sum( units_ass )=;
run;

/*
proc print data=Preservation_cat2;
  id NLIHC_ID program;
  var poa_end units_tot units_ass;
  title2 'File = Preservation_cat2';
run;
*/

** Update catalog with current Section 8 MF data **;

proc summary data=HsngMon.S8summary_2008_1 nway;
  where not missing( property_id );
  class property_id;
  var cur_expiration_date cur_assisted_units_count cur_total_unit_count;
  output out=S8summary (drop=_type_ _freq_)
    max( cur_expiration_date cur_total_unit_count )=
    sum( cur_assisted_units_count )=;
run;

proc sort data=Preservation_cat2;
  by property_id;
  
data Preservation_cat_b;

  merge 
    Preservation_cat2 (in=in1)
    S8summary (where=(not missing( property_id )));
  by property_id;

  if in1;
  
  in_report = 1;
  
  ** Update Section 8 info **;
  
  if source_code = '55' then do;
  
    if not missing( cur_expiration_date ) then poa_end = cur_expiration_date;
    if not missing( cur_assisted_units_count ) then units_ass = cur_assisted_units_count;
    if not missing( cur_total_unit_count ) then units_tot = cur_total_unit_count;
    
    if cur_expiration_date < '01jul2007'd then in_report = 0;
    
  end;
  
run;

/**********************************************************************************
data Preservation_cat_s8;
  set Preservation_cat_b;
  where put( program, $s8cond. ) = 'SECTION 8';
run;

proc sort data=Preservation_cat_s8 nodupkey;
  by property_id;

%Dup_check(
  data=HsngMon.s8summary_2008_1,
  by=property_id,
  id=contract_number cur_program_type_name cur_expiration_date cur_assisted_units_count,
  out=_dup_check,
  listdups=Y,
  count=dup_check_count,
  quiet=N,
  debug=N
)

proc compare base=Preservation_cat_s8 compare=S8summary maxprint=(40,32000) 
  out=diffs outnoequal outbase outcomp;
  id property_id;
  var poa_end units_ass ;
  with cur_expiration_date cur_assisted_units_count;
run;

data diffs2;

  merge 
    diffs (drop=_obs_ in=in1) 
    Preservation_cat_s8 (keep=property_id source_code program)
    ;
  by property_id;
  
  if in1;
  
run;

proc print data=diffs2;
  by property_id;
  id property_id;
run;

ENDSAS;
**********************************************************************************/

/*
proc print data=Preservation_cat_b;
  where not missing( property_id ) and source_code = '55';
  id property_id;
  var source_code poa_end cur_expiration_date units_ass cur_assisted_units_count 
  units_tot cur_total_unit_count;
  title2;
run;

ENDSAS;
*/

** Condense data into one record per project, creating unit counts **;

proc sort data=Preservation_cat_b;
  by NLIHC_ID;

data Assisted_units;

  set Preservation_cat_b 
        (keep=NLIHC_ID program &keep_geo in_report
              ssl Proj_Name Proj_Addr_ref units_tot units_ass poa_end
         where=(program~='PRAC 202/811' and in_report));
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
  
  select ( put( program, $s8cond. ) );
  
    when ( 'Public Housing' ) a_aunits{&PUBHSNG} = units_ass;
    when ( 'SECTION 8' ) a_aunits{&S8PROG} = units_ass;
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

ods rtf file="&_dcdata_path\HsngMon\Prog\2008-1\Assisted_units.rtf" style=Styles.Rtf_arial_9pt;

options nodate nonumber;
options missing='0';

%fdate()

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
  footnote1 height=9pt "Updated &fdate..";
  footnote2 height=9pt j=r '{Page}\~{\field{\*\fldinst{\pard\b\i0\chcbpat8\qc\f1\fs19\cf1{PAGE }\cf0\chcbpat0}}}';
  
run;

ods rtf close;
