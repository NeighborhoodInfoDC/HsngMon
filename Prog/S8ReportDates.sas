/**************************************************************************
 Program:  S8ReportDates.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  11/23/07
 Version:  SAS 9.1
 Environment:  Windows
 
 Description:  Autocall macro to create S8ReportDates file and
 global macro vars.

 Modifications:
**************************************************************************/

/** Macro S8ReportDates - Start Definition **/

%macro S8ReportDates( hud_file_date=, pres_report_lag_days=&G_S8_PRES_RPT_LAG_DAYS, pres_start_date=&G_S8_PRES_START_DATE );

  %global 
    g_s8_past_4q_lbl g_s8_next_4q_lbl
    g_s8_pres_end_date g_s8_pres_end_date_qtr g_s8_pres_end_date_yr 
    g_s8_pres_period_lbl_a g_s8_pres_period_lbl_b g_s8_rpt_num_qtrs g_s8_rpt_num_years
    g_s8_hud_file_date
  ; 
  
  %let g_s8_rpt_num_qtrs = 4;
  %let g_s8_rpt_num_years = 9;

  %** Check if hud_file_date supplied **;
  
  %if &hud_file_date = %then %do; 
    %err_mput( macro=S8ReportDates, msg=Value ('mm/dd/yyyy') must be provided for HUD_FILE_DATE=. )
    %goto exit_macro;
  %end;

  ** Write report titles to workbook **;

  data S8ReportDates (compress=no);

    rpt_date = "&g_rpt_title";

    as_of = "(as of &g_s8_rpt_dt_fmt)";
    
    dt0 = intnx( 'qtr', &g_s8_rpt_dt, -(&g_s8_rpt_num_qtrs), 'beginning' );
    dt1 = intnx( 'qtr', &g_s8_rpt_dt, 0, 'beginning' );
    
    past_4 = trim( left( put( dt0, monname3. ) ) ) ||
            ' ' ||
            trim( left( put( dt0, year4. ) ) ) ||
            ' - ' || 
            trim( left( put( dt1 - 1, monname3. ) ) ) ||
            ' ' ||
            left( put( dt1 - 1, year4. ) );
    
    call symput( 'g_s8_past_4q_lbl', past_4 );
    
    dt0 = intnx( 'qtr', &g_s8_rpt_dt, 0, 'beginning' );
    dt1 = intnx( 'qtr', &g_s8_rpt_dt, (&g_s8_rpt_num_qtrs), 'beginning' );
    
    next_4 = trim( left( put( dt0, monname3. ) ) ) ||
            ' ' ||
            trim( left( put( dt0, year4. ) ) ) ||
            ' - ' || 
            trim( left( put( dt1 - 1, monname3. ) ) ) ||
            ' ' ||
            left( put( dt1 - 1, year4. ) );
    
    call symput( 'g_s8_next_4q_lbl', next_4 );

    hud_date = &hud_file_date;
    
    hud_file = "&g_s8_data";
    
    rpt_update = "&fdate";
    
    ***** Preservation report *****;
    
    hud_file_sas_dt = input( &hud_file_date, mmddyy10. );
    put hud_file_sas_dt= mmddyy10.;
    
    pres_end_date = intnx( 'qtr', hud_file_sas_dt - &pres_report_lag_days, -1, 'end' );
    pres_end_date_qtr = qtr( pres_end_date );
    pres_end_date_yr = year( pres_end_date );
    
    put pres_end_date= mmddyy10. pres_end_date_qtr= pres_end_date_yr=;
    
    call symput( 'g_s8_pres_end_date', pres_end_date );
    call symput( 'g_s8_pres_end_date_qtr', pres_end_date_qtr );
    call symput( 'g_s8_pres_end_date_yr', pres_end_date_yr );
    
    ** Preservation period **;
    
    pres_start_date_yr = year( &pres_start_date );
    
    if pres_end_date_qtr = 4 then 
      call symput( 'g_s8_pres_period_lbl_a', put( pres_start_date_yr, 4. ) || ' - ' || 
                   put( pres_end_date_yr, 4. ) 
                 );
    else
      call symput( 'g_s8_pres_period_lbl_a', 
                    put( pres_start_date_yr, 4. ) || ' - ' || put( pres_end_date_yr, 4. ) || 
                      ' Q' || put( pres_end_date_qtr, 1. ) 
                  );
    
    call symput( 'g_s8_pres_period_lbl_b', 
                 put( &pres_start_date, worddate3. ) || ' ' || put( pres_start_date_yr, 4. ) ||
                 ' - ' ||
                 put( pres_end_date, worddate3. ) || ' ' || put( pres_end_date_yr, 4. )
               );
    
  run;
  
  %let g_s8_hud_file_date = &hud_file_date;
  
  %exit_macro:

  %put _global_;
  
%mend S8ReportDates;

/** End Macro Definition **/

