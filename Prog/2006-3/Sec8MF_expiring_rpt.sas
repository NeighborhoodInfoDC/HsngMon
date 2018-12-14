/**************************************************************************
 Program:  Sec8MF_expiring_rpt.sas
 Library:  NAS
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  06/29/05
 Version:  SAS 8.2
 Environment:  Windows
 
 Description:  Report showing upcoming expiring Sec. 8 MF projects.
               Creates S8pipesum_2005_06.rtf and S8pipedet_2005_06.rtf.

 Modifications:
**************************************************************************/

%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";

** Define libraries **;
%DCData_lib( HsngMon )
%DCData_lib( NAS )
%DCData_lib( HUD )

%let cur_rpt_date = '01apr2006'd; 
%let rpt_title = Fall 2006;
/*%let data = Hud.Sec8mf_current_dc_jul06;*/
%let data = Hud.Sec8mf_2006_07_dc;
%let hud_file_date = '7/7/06';
%let num_qtrs = 4;
%let num_years = 9;
%let rpt_path = D:\DCData\Libraries\HsngMon\Reports\2006-3;
%let rpt_name = S8expiring_2006_3;

%let BLANK = '20'x;    ** Blank character for DDE output **;

%let cur_rpt_date_fmt = %sysfunc( putn( &cur_rpt_date, mmddyy. ) );

** Create format for next four quarters **;

%nextqtrs_format( date=&cur_rpt_date, label_prefix=%str(\line\ql\keepn\i Expiring ), month_fmt=monname20. )

/*
proc format;
  value quarters
    '01apr2005'd -< '01jul2005'd = '\line\ql\keepn\iExpiring April - June 2005'
    '01jul2005'd -< '01oct2005'd = '\line\ql\keepn\iExpiring July - September 2005'
    '01oct2005'd -< '01jan2006'd = '\line\ql\keepn\iExpiring October - December 2005'
    '01jan2006'd -< '01apr2006'd = '\line\ql\keepn\iExpiring January - April 2006';
*/    

proc sort data=Nas.ta_proj_list_new out=ta_proj_list_new;
  by hud_contract_number;

data SEC8MF;

  /*set HUD.SEC8MF_2005_05_DC &data;*/
  merge
    &data (in=inHud)
    ta_proj_list_new 
      (keep=hud_contract_number ta_cur_provider
       rename=(hud_contract_number=contract_number));
  by contract_number;
  
  if program_type_name in ('PRAC/202','PRAC/811','UHsngMonstPrj SCHAP','Service Coo') then delete;

  if inHUD and not( missing( tracs_overall_expiration_date ) ) and
     not( missing( put( tracs_overall_expiration_date, nextqtrs. ) ) );
  
  ***where '01apr2005'd <= tracs_overall_expiration_date < '01apr2006'd;
  
  contracts = 1;
  
  quarter = tracs_overall_expiration_date;
  
  format quarter nextqtrs.;
  
  risk = "?";
  
run;
  
proc sort 
  data=SEC8MF;
  by tracs_overall_expiration_date;

options missing=' ' /*orientation=landscape*/;
options nodate nonumber nobyline;

** Summary report **;

ods rtf file="&rpt_path\&rpt_name._sum.rtf" style=Rtf_arial_9pt_grhd;
ods listing close;

proc report data=SEC8MF list nowd split='*';
  column quarter contracts address_line1_text tracs_overall_expiration_date
         /*risk*/ ta_cur_provider assisted_units_count owner_organization_name;
  define quarter / group order=data format=nextqtrs. noprint;
  define contracts / analysis sum noprint;
  define address_line1_text / display 'Address';
  define tracs_overall_expiration_date / display format=mmddyy10. 'Expires';
  /*define risk / display format=$6. 'Expir.*Risk';*/
  define ta_cur_provider / display 'TA Provider';
  define assisted_units_count / analysis sum 'Assisted Units';
  define owner_organization_name / display 'Owner';
  break before quarter / skip;
  break after quarter / ;
  compute before quarter;
    length text $ 80;
    text = left( put( quarter, nextqtrs. ) );
    line text $80.;
  endcomp;
  compute after quarter;
    length text2 $ 80;
    text2 = '\ql\line Quarter total:  ' || trim( left( put( contracts.sum, comma8. ) ) ) ||
           ' contracts with ' || trim( left( put( assisted_units_count.sum, comma8. ) ) ) ||
           ' units.';
    line text2 $80.;
  endcomp;
  title1 height=11pt 'Section 8 Multifamily Report:  Summary of Upcoming Expiring Contracts (next four quarters)';
  title2 height=11pt "District of Columbia Housing Monitor: &rpt_title";
  ***title3 height=11pt 'Washington, D.C.';
  footnote1 height=9pt '\b0\i NeighborhoodInfo DC (www.NeighborhoodInfoDC.org)';
  footnote2 height=9pt j=r "\b0\i Created &fdate";
  footnote3 height=9pt j=r '\b0\i {Page}\~{\field{\*\fldinst{\b0\i PAGE }}}\~{\b0\i of}\~{\field{\*\fldinst{\b0\i NUMPAGES }}}';
  *footnote2 height=9pt j=r '\b0\i {Page}\~{\field{\*\fldinst{\pard\b0\i\chcbpat8\qc\f1\fs19\cf1{PAGE }\cf0\chcbpat0}}}';
  *footnote2 height=9pt j=r '\b0\i {Page}\~{\field{\*\fldinst{\b0\i PAGE }}}\~{\b0\i of}\~{\field{\*\fldinst{\b0\i NUMPAGES }}}';

run;

ods rtf close;
ods listing;

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


**** Detail report ****;
  
data detail_dat (keep=tracs_overall_expiration_date buff rownum);

  length buff $ 200;

  set SEC8MF;

  rownum = 1;

  %line_out( 
    '\b ' || trim( address_line1_text ) || ", Washington, DC " || trim( zip_code ) ||
    '\b0\~ / Contract no.: ' || contract_number,
    ind=n
  )
  
  %line_out( "Name:  " || property_name_text )
  
  %line_out( put( ward2002, $ward02a. ) || " / " || 
             put( anc2002, $anc02a. ) || " / " ||
             trim( put( cluster_tr2000, $clus00a. ) ) || " (" || 
               left( trim( put( cluster_tr2000, $clus00s. ) ) ) || ") / " ||
             put( geo2000, $geo00a. ) )
             
  /*%line_out( "Contract no.:  " || contract_number )*/
  
  %line_out( 
    "Expires:  " || trim( put( tracs_overall_expiration_date, mmddyy10. ) ) 
    /**|| "  " || "\{expiration risk?\}"**/
  )
  
  %line_out( 
    "Num. assisted units: " || 
    trim( left( put( assisted_units_count, comma8.0 ) ) ) ||
    " (" || left( trim( rent_to_FMR_description ) ) ||
    ") / " || "Total units: " || trim( left( put( property_total_unit_count, comma8.0 ) ) )
  )
  %line_out( "Program: " || program_type_name )
  %line_out( 
    "Owner:  " || 
    compbl( 
      trim( owner_organization_name ) || ", " || 
      trim( owner_address_line1 ) || ", " ||
      trim( owner_city_name ) || ", " ||
      trim( owner_state_code ) || " " ||
      trim( owner_zip_code ) 
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
        trim( mgmt_agent_zip_code ) 
      )
    )
  end;
  
  %line_out( "Tenants being assisted by: " || trim( left( ta_cur_provider ) ) )

  %line_out( " ", keepn=n )         /** Blank line for end of property record **/

run;

ods rtf file="&rpt_path\&rpt_name._det.rtf" style=Rtf_arial_9pt;
ods listing close;

proc report data=detail_dat list nowd noheader;
  by tracs_overall_expiration_date;
  column buff;
  define buff / display;
  format 
    tracs_overall_expiration_date nextqtrs.;
  title1 height=11pt 'Section 8 Multifamily Report:  Detail for Upcoming Expiring Contracts (next four quarters)';
  title2 height=11pt "District of Columbia Housing Monitor: &rpt_title";
  ***title3 height=11pt 'Washington, D.C.';
  title4 height=11pt ' ';
  title5 height=9pt "\b0\i #byval( tracs_overall_expiration_date )";
  
run;

ods rtf close;
ods listing;

