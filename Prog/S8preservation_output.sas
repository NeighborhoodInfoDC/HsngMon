/**************************************************************************
 Program:  S8preservation_output.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  11/23/07
 Version:  SAS 9.1
 Environment:  Windows
 
 Description:  Autocall macro to create Section 8 Multifamily Report:
 Preservation Summary.
 
 Modifications:
**************************************************************************/

/** Macro S8preservation_output - Start Definition **/

%macro S8preservation_output( hud_file_date=&g_s8_hud_file_date, report_lag_days=&G_S8_PRES_RPT_LAG_DAYS, start_date=&G_S8_PRES_START_DATE, dde=y );

  %let DEBUG = *;        %** Blank for debugging, * for normal **;

  %let BLANK = '20'x;    %** Blank character for DDE output **;
  
  %let dde = %upcase( &dde );
  
  ** Write report title info **;

  data PreservationTitles (compress=no);
    preservation_per = "&g_s8_pres_period_lbl_a";
    start_date = put( &start_date, mmddyy10. );
  run;

  %Write_dde( dde=&dde, rpt_xls=&g_s8_rpt_xls, sheet=Titles, range=r8c2:r8c2, data=PreservationTitles, var=preservation_per )
  %Write_dde( dde=&dde, rpt_xls=&g_s8_rpt_xls, sheet=Titles, range=r9c2:r9c2, data=PreservationTitles, var=start_date )

  **** Active/Lost chart ****;

  proc summary data=S8losses_det nway;
    class rpt_date rpt_date_yr;
    var active_units cum_lost_units lost_units expired_units terminated_units;
    output out=S8losses_chart (drop=_type_ _freq_) sum=;
  run;

  proc print data=S8losses_chart ;
    title2 'S8losses_chart';

  run;

  %Write_dde( dde=&dde, rpt_xls=&g_s8_rpt_xls, sheet=Preservation, range=r6c12:r200c14, data=S8losses_chart, 
    var=rpt_date_yr active_units cum_lost_units )

  **** Units by year ****;

  proc summary data=S8losses_chart;
    class rpt_date_yr;
    var active_units lost_units expired_units terminated_units;
    output out=S8losses_year 
      max(active_units)=
      sum(lost_units expired_units terminated_units)= ;
  run;

  /** Macro rptyr_fmt - Start Definition **/

  %macro rptyr_fmt;

    proc format;
      value rptyr
        . = "Total"
        %if &g_s8_pres_end_date_qtr = 1 %then %do;
          &g_s8_pres_end_date_yr = "&g_s8_pres_end_date_yr Q1"
        %end;
        %else %if &g_s8_pres_end_date_qtr = 4 %then %do;
          &g_s8_pres_end_date_yr = "&g_s8_pres_end_date_yr"
        %end;
        %else %do;
          &g_s8_pres_end_date_yr = "&g_s8_pres_end_date_yr Q1-Q%left(&g_s8_pres_end_date_qtr)"
        %end;
      ;

  %mend rptyr_fmt;

  /** End Macro Definition **/

  %rptyr_fmt

  data S8losses_year;
    set S8losses_year;
    if rpt_date_yr = . then active_units = .;
    format rpt_date_yr rptyr.;
  run;

  options missing='-';

  proc sort data=S8losses_year;
    by descending _type_ rpt_date_yr;

  proc print data=S8losses_year;
    format rpt_date_yr rptyr.;
    title2 'S8losses_year';
  run;

  %Write_dde( dde=&dde, rpt_xls=&g_s8_rpt_xls, sheet=Preservation, range=r27c2:r35c7, data=S8losses_year, 
    var=rpt_date_yr active_units &BLANK lost_units expired_units terminated_units )

  ** Units by ward **;

  ** Ward format **;

  data _cntlin (compress=no);

    set General.Ward2002 end=eof;
    
    length fmt_label $ 8;
    
    fmt_label = 'Ward ' || left( Ward2002 );
    
    output;
    
    if eof then do;
      ward2002 = ' ';
      fmt_label = 'Total';
      output;
    end;

  run;

  %Data_to_format(
    FmtLib=work,
    FmtName=$wardsb,
    Data=_cntlin,
    Value=ward2002,
    Label=fmt_label,
    OtherLabel=,
    DefaultLen=.,
    MaxLen=.,
    MinLen=.,
    Print=N
    )

  proc summary data=S8losses_det;
    class ward2002 rpt_date;
    var active_units cum_lost_units lost_units expired_units terminated_units;
    output out=S8losses_ward_qtr sum=;
  run;
  
  /**/
  proc print data=S8losses_ward_qtr;
    title2 'S8losses_ward_qtr';
  run;
  /**/

  proc summary data=S8losses_ward_qtr (where=(_type_ in ( 1, 3 ))) nway;
    class ward2002 / missing;
    var active_units lost_units expired_units terminated_units;
    output out=S8losses_ward 
      max(active_units)=
      sum(lost_units expired_units terminated_units)= ;
  run;

  data S8losses_ward;
    set S8losses_ward;
    if missing( ward2002) then _type_ = 0;
    format ward2002 $wardsb.;
  run;

  proc sort data=S8losses_ward;
    by descending _type_ ward2002;
    
  proc print data=S8losses_ward;
    title2 'S8losses_ward';
  run;

  %Write_dde( dde=&dde, rpt_xls=&g_s8_rpt_xls, sheet=Preservation, range=r40c2:r48c7, data=S8losses_ward, 
    var=ward2002 active_units &BLANK lost_units expired_units terminated_units )

%mend S8preservation_output;

/** End Macro Definition **/

