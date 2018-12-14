/**************************************************************************
 Program:  Sec8MF_expired_rpt.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  09/25/07
 Version:  SAS 9.1
 Environment:  Windows
 
 Description:  Report showing recently expired Sec. 8 MF projects.

 Modifications:
**************************************************************************/

%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";
***%include "C:\DCData\SAS\Inc\Stdhead.sas";

** Define libraries **;
%DCData_lib( HsngMon )
%DCData_lib( NAS )
%DCData_lib( HUD )

%Init_macro_vars( rpt_yr=2008, rpt_qtr=1 )

%S8ReportDates( hud_file_date='12/28/2007' )

/** Macro Expired_rpt - Start Definition **/

%macro Expired_rpt(  
 cur_rpt_date = , 
 rpt_title = ,
 rpt_yr = ,
 rpt_qtr = ,
 ta_data = 
);

%let data = HsngMon.&g_s8_rpt_file;
%let rpt_path = &_dcdata_path\HsngMon\Prog\&g_rpt_yr-&g_rpt_qtr;
%let rpt_file = S8expired_&g_rpt_yr._&g_rpt_qtr;

%prevqtrs_format( date=&g_s8_rpt_dt, label_prefix=%str(\line\ql\keepn\i Expired ), month_fmt=monname20. )

proc sort data=&ta_data out=ta_proj_list_new;
  by hud_contract_number;

data SEC8MF;

  merge 
    &data (in=in1 where=(exp_contracts > 0))
    ta_proj_list_new 
      (keep=hud_contract_number ta_cur_provider
       rename=(hud_contract_number=contract_number))
    /*** TEMPORARY MERGE UNTIL OTHER DATA ADDED TO FILE ***/
    /*
    Hud.Sec8mf_2007_07_dc 
      (keep=contract_number property_name_text program_type_name owner_: mgmt_:)*/;
  by contract_number;
  
  if in1;
  
  ***if cur_expiration_date > prev_expiration_date;
  
  if cur_program_type_name in ('PRAC/202','PRAC/811','UHsngMonstPrj SCHAP','Service Coo') then delete;

  ** Expired contracts **;

  ******if not( missing( cur_expiration_date ) ) and not( missing( put( cur_expiration_date, prevqtrs. ) ) );
  
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
  
  ** Quarter **;
  
  Expir_qtr = put( cur_expiration_date, yyq. );
  
  ** Reformat text to proper case **;

  array a{*} cur_owner_name mgmt_agent_org_name mgmt_agent_address_line1 mgmt_agent_city_name;
  
  do i = 1 to dim( a );
    a{i} = propcase( a{i} );
  end;

run;

proc means data=SEC8MF sum;
  var contracts cur_assisted_units_count;
  title2 "Total Expirations/Terminations";
  
proc freq data=SEC8MF;
  tables cur_tracs_status cur_ui_status;
run;

title2;


** Report date for title **;

%let rpt_date = %sysfunc( putn( &g_s8_rpt_dt, monname. ) ) %sysfunc( putn( &g_s8_rpt_dt, year4. ) );

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

proc sort data=SEC8MF;
  by descending cur_expiration_date;

data detail_dat (keep=cur_expiration_date buff rownum);

  retain tot_assisted_units tot_contracts;

  length buff $ 200;

  set SEC8MF;
  by descending Expir_qtr;
  
  if first.Expir_qtr then do;
    tot_assisted_units = 0;
    tot_contracts = 0;
  end;

  rownum = 1;
  
  tot_assisted_units = tot_assisted_units + cur_assisted_units_count;
  tot_contracts = tot_contracts + 1;

  %line_out( 
    '\b ' || trim( cur_address_line1_text ) || ", Washington, DC " || trim( zip_code ) ||
    '\b0\~ / Contract no.: ' || contract_number,
    ind=n
  )
  %line_out( "Name:  " || put( property_name_text, $s8pgmnm. ) )
  
  if ward2002 ~= '' then do;

    %line_out( put( ward2002, $ward02a. ) || " / " || 
               put( anc2002, $anc02a. ) || " / " ||
               trim( put( cluster_tr2000, $clus00a. ) ) || " (" || 
                 left( trim( put( cluster_tr2000, $clus00s. ) ) ) || ") / " ||
               put( geo2000, $geo00a. ) )
             
  end;
  
  %line_out( "Expired:  " || trim( put( cur_expiration_date, mmddyy10. ) ) ||
             "  /  TRACS status:  " || trim( left( put( cur_tracs_status, $S8STAT. ) ) ) )
  
  %line_out( 
    "Num. assisted units: " || 
    trim( left( put( cur_assisted_units_count, comma8.0 ) ) ) ||
    " (" || left( trim( cur_rent_to_fmr_desc ) ) ||
    ") / " || "Total units: " || trim( left( put( cur_total_unit_count, comma8.0 ) ) )
  )
  %line_out( "Program: " || cur_program_type_name )
  %line_out( 
    "Owner:  " || 
    compbl( 
      trim( cur_owner_name ) || ", " || 
      trim( owner_address_line1 ) || ", " ||
      trim( owner_city_name ) || ", " ||
      trim( owner_state_code ) || " " ||
      trim( owner_zip_code )  || " " ||
      "/ Tel: " || trim( owner_main_phone_number_text )
    )
  )
  
  if not( missing( mgmt_agent_org_name ) ) then do;
    %line_out( 
      "Manager: " ||
      compbl( 
        trim( mgmt_agent_org_name ) || ", " || 
        trim( mgmt_agent_address_line1 ) || ", " ||
        trim( mgmt_agent_city_name ) || ", " ||
        trim( mgmt_agent_state_code ) || " " ||
        trim( mgmt_agent_zip_code ) || " " ||
        "/ Tel: " || trim( mgmt_agent_main_phone_number )
      )
    )
  end;
  
  %line_out( "Tenants being assisted by: " || trim( left( ta_cur_provider ) ) )

  %line_out( " ", keepn=n )         /** Blank line for end of property record **/
  
  if last.Expir_qtr then do;
   %line_out( "\line\b TOTAL EXPIRED CONTRACTS FOR QUARTER = " || trim( left( put( tot_contracts, comma8. ) ) ) ||
              "  /  ASSISTED UNITS = " || trim( left( put( tot_assisted_units, comma10. ) ) ), keepn=n )
  end;
  
run;

ods rtf file="&rpt_path\&rpt_file..rtf" style=Styles.Rtf_arial_9pt;
ods listing close;

proc report data=detail_dat list nowd noheader;
  by descending cur_expiration_date;
  column buff;
  define buff / display;
  format cur_expiration_date prevqtrs.;
  title1 height=11pt 'Section 8 Multifamily Report: Contract Expirations (past four quarters)';
  title2 height=11pt "District of Columbia Housing Monitor: &rpt_title";
  ***title3 height=11pt 'Washington, D.C.';
  title3 height=11pt ' ';
  title4 height=9pt "\b0\i #byval( cur_expiration_date )";
  footnote1 height=9pt '\b0\i NeighborhoodInfo DC (www.NeighborhoodInfoDC.org)';
  footnote2 height=9pt j=r "\b0\i Created &fdate";
  footnote3 height=9pt j=r '\b0\i {Page}\~{\field{\*\fldinst{\b0\i PAGE }}}\~{\b0\i of}\~{\field{\*\fldinst{\b0\i NUMPAGES }}}';
  
run;

ods rtf close;
ods listing;

%mend Expired_rpt;

/** End Macro Definition **/

%Expired_rpt( ta_data=Nas.ta_proj_list_2007_07 )

