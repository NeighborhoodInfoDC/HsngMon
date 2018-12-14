/**************************************************************************
 Program:  Table_Sec8MF.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  10/01/07
 Version:  SAS 9.1
 Environment:  Windows
 
 Description:  Autocall macro to create "Housing Units in Section 8
 Multifamily Projects" table.

 Modifications:
  11/22/07 PAT Added DDE= parameter, to switch from DDE to ASCII output.
**************************************************************************/

/** Macro Table_Sec8MF - Start Definition **/

%macro Table_Sec8MF( sheet=, start_row=, cur_rpt_date=, dde=Y );

/*
  %let s8_data = HsngMon.S8summary_&g_rpt_yr._&g_rpt_qtr;
  %let cur_rpt_date_fmt = %sysfunc( putn( &g_s8_rpt_dt, mmddyy. ) );
*/

  %Format_misszero()

  ** Current active units **;

  proc summary data=HsngMon.&g_s8_rpt_file completetypes;
    where in_cwc_rpt;
    class ward2002 / preloadfmt;
    var act_units;
    output out=WardCurrentActive sum= ;
    format ward2002 $ward02a. act_units misszero.;

  proc print data=WardCurrentActive ;
  run;
  
  %Table1_output( sheet=&sheet, start_row=&start_row, var=act_units, data=WardCurrentActive, 
     rowlbl="Current active units (as of &g_s8_rpt_dt_fmt)", dde=&dde )

  ** Renewals, Expirations, Expiring **;

  proc summary data=HsngMon.&g_s8_rpt_file completetypes;
    where in_cwc_rpt;
    class ward2002 / preloadfmt;
    var ren_units exp_units upt_units;
    output out=WardRenExp sum= ;
    format 
      ward2002 $ward02a. 
      ren_units exp_units upt_units misszero.;

  proc print data=WardRenExp;
  run;
  
  %Table1_output( sheet=&sheet, start_row=%eval(&start_row + 2), var=upt_units, data=WardRenExp, 
     rowlbl="Upcoming expiring (&g_s8_next_4q_lbl)", dde=&dde )

  %Table1_output( sheet=&sheet, start_row=%eval(&start_row + 4), var=ren_units, data=WardRenExp, 
     rowlbl="Renewals (&g_s8_past_4q_lbl)", dde=&dde )
     
  %Table1_output( sheet=&sheet, start_row=%eval(&start_row + 6), var=exp_units, data=WardRenExp, 
     rowlbl="Expirations (&g_s8_past_4q_lbl)", dde=&dde )
     
  ** Lost units **;

/*****
  %let loss_start_date = '01jan2000'd;
  %let loss_end_date = '31dec2006'd;

  data S8losses (compress=no);

    set HsngMon.&g_s8_rpt_file;
    
    if cur_tracs_status = 'T' then 
      loss_date = min( date_cur_ui_status, cur_expiration_date );
    else
      loss_date = cur_expiration_date;
      
    if &loss_start_date <= loss_date <= &loss_end_date;
    
    format loss_date mmddyy10.;
   
  run;  

  proc summary data=S8losses completetypes;
    *where in_cwc_rpt;
    class ward2002 / preloadfmt;
    var cur_assisted_units_count;
    output out=lost_units sum=lost_units;
    format 
      ward2002 $ward02a. 
      cur_assisted_units_count misszero.;
*****/

  proc summary data=S8losses_det completetypes;
    class ward2002 / preloadfmt;
    var lost_units;
    output out=lost_units sum=;
    format 
      ward2002 $ward02a. 
      lost_units misszero.;

  proc print data=lost_units;
  run;

  %Table1_output( sheet=&sheet, start_row=%eval(&start_row + 8), var=lost_units, data=lost_units, 
     rowlbl="Cumulative losses (&g_s8_pres_period_lbl_b)", dde=&dde )

%mend Table_Sec8MF;

/** End Macro Definition **/

