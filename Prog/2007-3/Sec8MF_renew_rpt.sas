/**************************************************************************
 Program:  Sec8MF_renew_rpt.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  08/19/05
 Version:  SAS 8.2
 Environment:  Windows
 
 Description:  Report showing recently renewed Sec. 8 MF projects.

 Modifications:
**************************************************************************/

%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";
***%include "C:\DCData\SAS\Inc\Stdhead.sas";

** Define libraries **;
%DCData_lib( NAS )
%DCData_lib( HUD )
%DCData_lib( HsngMon )

/** Macro Renew_rpt - Start Definition **/

%macro Renew_rpt(  
  cur_rpt_date = , 
  rpt_title = ,
  rpt_yr = ,
  rpt_qtr = ,
  ta_data = 
);

%let data = HsngMon.S8summary_&rpt_yr._&rpt_qtr;
%let rpt_path = &_dcdata_path\HsngMon\Prog\&rpt_yr-&rpt_qtr;
%let rpt_file = S8renew_&rpt_yr._&rpt_qtr;

%prevqtrs_format( date=&cur_rpt_date, label_prefix=%str(\line\ql\keepn\i Renewed ), month_fmt=monname20. )

proc sort data=&ta_data out=ta_proj_list_new;
  by hud_contract_number;

data Sec8MF_renew;

  merge 
    &data (where=(ren_contracts > 0) 
           in=in1)
    ta_proj_list_new 
      (keep=hud_contract_number ta_cur_provider
       rename=(hud_contract_number=contract_number))
    /*** TEMPORARY MERGE UNTIL OTHER DATA ADDED TO FILE ***/
    Hud.Sec8mf_2007_02_dc 
      (keep=contract_number property_name_text);
  by contract_number;
  
  if in1;
  
  ***if cur_expiration_date > prev_expiration_date;
  
  if missing( cur_expiration_date ) then delete;

  if cur_program_type_name in ('PRAC/202','PRAC/811','UHsngMonstPrj SCHAP','Service Coo') then delete;

  ** Renewed contracts (past four quarters) **;
  
  if cur_expiration_date > prev_expiration_date and
     not( missing( prev_expiration_date ) ) and
     not( missing( put( date_cur_contract, prevqtrs. ) ) ) then do;
   
    exp_ren_date = date_cur_contract;
    
    ren_contract_len = max( intck( 'YEAR', prev_expiration_date, cur_expiration_date ), 1 );

  end;
  else 
    delete;

  %let varlist = contract_term rent_to_FMR_desc assisted_units_count program_type_name;
  
  %let i = 1;
  %let var = %scan( &varlist, &i );
  
  %do %while( &var ~= );
  
    if missing( prev_&var ) then prev_&var = cur_&var;

    %let i = %eval( &i + 1 );
    %let var = %scan( &varlist, &i );

  %end;
  
  property_name_text = left( compbl( compress( property_name_text, "*" ) ) );
  
  contracts = 1;
  
  if cur_total_unit_count > 0 then 
    pct_assisted_units = cur_assisted_units_count / cur_total_unit_count;
  
  ren_contract_len = max( intck( 'YEAR', prev_expiration_date, cur_expiration_date ), 1 );
  
run;

proc sort data=Sec8MF_renew;
  by descending date_cur_contract;

proc means data=Sec8MF_renew sum;
  var contracts cur_assisted_units_count;

** Report date for title **;

%let rpt_date = %sysfunc( putn( &cur_rpt_date, monname. ) ) %sysfunc( putn( &cur_rpt_date, year4. ) );

**** Create report ****;

%note_mput( msg=Creating report for &rpt_date.. )

options missing=' ' /*orientation=landscape*/;
options nodate nonumber nobyline;

%fdate()

/** Macro Line_out - Start Definition **/

%macro Line_out( line_str, ind=Y, keepn=Y );

  %let ind = %upcase( &ind );
  %let keepn = %upcase( &keepn );
  
  %** If &ind=Y, add code for indenting line and adjust line spacing **;

  %if &ind = Y %then %do;
    buff = '\sb0\sa60\~\~' || &line_str;
  %end;
  %else %do;
    buff = &line_str;
  %end;
  
  %** If &keepn=Y, add code for keep paragraph with next **;
  
  %if &keepn = Y %then %do;
    buff = '\keepn' || buff;
  %end;
  
  output;
  rownum + 1;

%mend Line_out;

/** End Macro Definition **/

/** Macro Line_out_3c: Write three column output - Start Definition **/

%macro Line_out_3c( line_str1, line_str2, line_str3, ind=Y, keepn=Y );

  %let ind = %upcase( &ind );
  %let keepn = %upcase( &keepn );
  
  %** If &ind=Y, add code for indenting line and adjust line spacing **;

  %if &ind = Y %then %do;
    buff = '\sb0\sa60\tx2903\tx6503\~\~' || trim( &line_str1 ) || ' \tab ' ||
           trim( &line_str2 ) || ' \tab ' || trim( &line_str3 ) ;
  %end;
  %else %do;
    buff = '\tx2903\tx6503 ' || trim( &line_str1 ) || ' \tab ' ||
           trim( &line_str2 ) || ' \tab ' || trim( &line_str3 ) ;
  %end;
  
  %** If &keepn=Y, add code for keep paragraph with next **;
  
  %if &keepn = Y %then %do;
    buff = '\keepn' || buff;
  %end;
  
  output;
  rownum + 1;

%mend Line_out_3c;

/** End Macro Definition **/

proc format;
  picture renterm (round)
    1 = '1 year' (noedit)
    2-high = '009 years'
    other = '' (noedit);
  
data detail_dat (keep=date_cur_contract buff rownum);

  length buff $ 200;

  set Sec8MF_renew;

  rownum = 1;

  %line_out( 
    '\b ' || trim( cur_address_line1_text  ) || ", Washington, DC " || trim( zip_code ) ||
    '\b0\~ / Contract no.: ' || contract_number,
    ind=n
  )
  
  %line_out( "Name:  " || property_name_text )
  
  if ward2002 ~= '' then do;

    %line_out( put( ward2002, $ward02a. ) || " / " || 
               put( anc2002, $anc02a. ) || " / " ||
               trim( put( cluster_tr2000, $clus00a. ) ) || " (" || 
                 left( trim( put( cluster_tr2000, $clus00s. ) ) ) || ") / " ||
               put( geo2000, $geo00a. ) )
             
  end;
  
  %line_out( "TRACS status:  " || trim( left( put( cur_tracs_status, $S8STAT. ) ) ) );

  /*
  length assistance $ 250;
  
  if org_current ~= '' then
    assistance = trim( org_current );
  else if org_past ~= '' then
    assistance = trim( org_past );
  else 
    assistance = '';
  */
  
  %line_out( "\line\~\~Tenants assisted by:  " || ta_cur_provider )

  /*%line_out( "\line\i\tab Old contract \tab New contract" )*/
  
  %line_out( " " )
  %line_out_3c( " ", "\i Old contract", "\i New contract" )
  %line_out_3c( "Program:", prev_program_type_name, cur_program_type_name )
  %line_out_3c( "Assisted units:", left( put( prev_assisted_units_count, comma8.0 ) ), 
             left( put( cur_assisted_units_count, comma8.0 ) ) )
  %line_out_3c( "Affordability:", prev_rent_to_FMR_desc, cur_rent_to_fmr_desc )
  /*
  %line_out_3c( "Term:", trim( left( put( prev_contract_term, comma8.0 ) ) ) || " months", 
             trim( left( put( cur_contract_term, comma8.0 ) ) ) || " months" )
  */
  %line_out_3c( "Expiration date:", put( prev_expiration_date, mmddyy10. ), put( cur_expiration_date, mmddyy10. ) )
  /*%line_out_3c( "Length of contract renewal:", "-", trim( left( put( ren_contract_len, comma8.0 ) ) ) || " years" )*/
  %line_out_3c( "Length of contract renewal:", "-", trim( left( put( ren_contract_len, renterm. ) ) ) )
  
  /*
  %line_out( "\line\i\~\~New contract:" )
  %line_out( "Program:  " || cur_program_type_name )
  %line_out( "Assisted units:  " || 
             trim( left( put( cur_assisted_units_count, comma8.0 ) ) ) )
  %line_out( "Affordability:  " || cur_rent_to_fmr_desc )
  %line_out( "Term:  " || trim( left( put( cur_contract_term, comma8.0 ) ) ) || " months" )
  %line_out( "Expiration date:  " || put( cur_expiration_date, mmddyy10. ) )
  */
  
  %line_out( " ", keepn=n )         /** Blank line for end of property record **/

run;

ods rtf file="&rpt_path\&rpt_file..rtf" style=Styles.Rtf_arial_9pt;
ods listing close;

proc report data=detail_dat list nowd noheader;
  by descending date_cur_contract;
  column buff;
  define buff / display;
  format date_cur_contract prevqtrs.;
  title1 height=11pt 'Section 8 Multifamily Report:  Contract Renewals (past four quarters)';
  title2 height=11pt "District of Columbia Housing Monitor: &rpt_title";
  ***title3 height=11pt 'Washington, D.C.';
  title3 height=11pt ' ';
  title4 height=9pt "\b0\i #byval( date_cur_contract )";
  footnote1 height=9pt '\b0\i NeighborhoodInfo DC (www.NeighborhoodInfoDC.org)';
  footnote2 height=9pt j=r "\b0\i Created &fdate";
  footnote3 height=9pt j=r '\b0\i {Page}\~{\field{\*\fldinst{\b0\i PAGE }}}\~{\b0\i of}\~{\field{\*\fldinst{\b0\i NUMPAGES }}}';
  
run;

ods rtf close;
ods listing;

%mend Renew_rpt;

/** End Macro Definition **/

%Renew_rpt(
  cur_rpt_date = '01jan2007'd, 
  rpt_title = Summer 2007,
  rpt_yr = 2007,
  rpt_qtr = 3,
  ta_data = Nas.ta_proj_list_2007_07
)

