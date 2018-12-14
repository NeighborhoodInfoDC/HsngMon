/**************************************************************************
 Program:  S8preservation_new.sas
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

/** Macro S8preservation_new - Start Definition **/

%macro S8preservation_new( hud_file_date=&g_s8_hud_file_date, report_lag_days=&G_S8_PRES_RPT_LAG_DAYS, start_date=&G_S8_PRES_START_DATE, dde=y );

  %let DEBUG = *;

  %let BLANK = '20'x;    ** Blank character for DDE output **;
  
  %let dde = %upcase( &dde );
  
  ** Get date of next contract and add to record **;
  
  data Next_contract;
  
    set Hud.Sec8mf_history_dc (keep=contract_number contract_hist_rec date_cur_contract);
    
    where contract_hist_rec > 1;
    
    &DEBUG IF &FILTER;
    
    contract_hist_rec = contract_hist_rec - 1;
    
    rename date_cur_contract=date_next_contract;
    
  run;
  
  /*%File_info( data=Next_contract, stats= ) */
  
  data History;
  
    merge 
      Hud.Sec8mf_history_dc (drop=ward2002)
      Next_contract;
    by contract_number contract_hist_rec;
    
    &DEBUG WHERE &FILTER;
    
  run;

  /*%File_info( data=History, stats= ) */
  
  data S8losses (compress=no);

    merge
      History
      HsngMon.&g_s8_rpt_file 
        (keep=contract_number date_cur_ui_status cur_expiration_date 
              /*date_cur_contract*/ cur_tracs_status cur_assisted_units_count 
              ward2002
         in=inB);
    by contract_number;
    
    if inB;
    
    &DEBUG IF &FILTER;
    
    if cur_tracs_status = 'T' then 
      loss_date = min( date_cur_ui_status, cur_expiration_date );
    else
      loss_date = cur_expiration_date;
      
    if loss_date >= &G_S8_PRES_START_DATE;
    
    format loss_date mmddyy10.;
   
  run;  
  
  
  /** REPORT VARS NEEDED
    active_units
    cum_lost_units
    expired_units
    lost_units
    terminated_units
  **/
  
  /****
  proc print data=S8losses;
    where not( cur_assisted_units_count > 0 );
    id contract_number;
    var ward2002 loss_date cur_tracs_status date_cur_ui_status date_cur_contract cur_expiration_date cur_assisted_units_count;
    title2 '***** Projects with missing assisted unit count *****';
  run;

  title2;
  ****/

  data S8losses_det (compress=no);
  
    &DEBUG PUT / "***** START OF DATA STEP: " _n_= ;
  
    retain i dt0 active_contract active_units cum_lost_contract cum_lost_units 
      terminated_contract terminated_units expired_contract expired_units 
      first_pass contract_change_units prev_assisted_units_count;

    i = 0;
    dt0 = intnx( 'qtr', &start_date, i, 'beginning' );
    
    cum_lost_contract = 0;
    cum_lost_units = 0;
    
    first_pass = 1;
    
    prev_assisted_units_count = .;
    assisted_units_count = .;
    
    ** Loop through all quarters in the report range for a contract **;
    
    do while( dt0 <= &g_s8_pres_end_date );
    
      &DEBUG PUT / "TOP OF DO WHILE LOOP: " i= DT0=;
    
      dt1 = intnx( 'qtr', dt0, 0, 'end' );
      
      expired_contract = 0;
      terminated_contract = 0;
      
      expired_units = 0;
      terminated_units = 0;
      contract_change_units = 0;

      &DEBUG PUT / "BEFORE WHILE SET: " FIRST_PASS= DATE_NEXT_CONTRACT= DT1= LAST.CONTRACT_NUMBER=;
      
      ** Read next contract obs. from history file **;
      
      do while ( 
          first_pass or 
          ( date_next_contract < dt1 and not( missing( date_next_contract ) ) and 
            not( last.contract_number ) )
        );
        
        prev_assisted_units_count = assisted_units_count;

        set S8losses (keep=contract_number date_cur_contract date_next_contract 
                           ward2002 loss_date assisted_units_count cur_tracs_status);
        by contract_number;
        
        &DEBUG PUT / "OBS. READ: " (contract_number date_cur_contract date_next_contract 
                           loss_date assisted_units_count cur_tracs_status last.contract_number) (=);
        
        ** Track units lost (gained) through contract changes **; 
      
        if not first_pass and prev_assisted_units_count ~= assisted_units_count then do;
          contract_change_units = sum( contract_change_units, ( prev_assisted_units_count - assisted_units_count ) );
        end;
        
        ** Need to make sure at first obs. for new contract **;
        
        if first.contract_number then do;
        
          first_pass = 0;
        
        end;
        else do;
        
          if first_pass then assisted_units_count = .;
          
        end;

      end;
      
      &DEBUG PUT / "EXITING WHILE SET";
      
      ** If loss date is after start of current quarter, then count as active **;
      
      if loss_date >= dt0 then do;
        active_contract = 1;
        active_units = assisted_units_count;
      end;
      
      ** Record losses in current quarter **;

      if dt0 <= loss_date <= dt1 then do;

        if cur_tracs_status = 'T' then do;
          terminated_contract = 1;
          terminated_units = contract_change_units + assisted_units_count;
        end;
        else do;
          expired_contract = 1;
          expired_units = contract_change_units + assisted_units_count;
        end;
        
      end;
      else do;
      
        expired_units = contract_change_units;
        
      end;
      
      lost_contracts = expired_contract + terminated_contract;
      lost_units = expired_units + terminated_units;

      rpt_date = dt0;
      rpt_date_yr = year( rpt_date );
      
      output;

      &DEBUG PUT / "OBS. WRITTEN: " (_ALL_) (=);
      
      ** Add to cumulative totals **;
     
      cum_lost_contract = cum_lost_contract + lost_contracts;
      cum_lost_units = cum_lost_units + lost_units;
      
      ** Adjust active counts **;
      
      active_contract = active_contract - lost_contracts;
      active_units = active_units - lost_units;      
      
      ** Increment date to next quarter **;

      i = i + 1;
      dt0 = intnx( 'qtr', &start_date, i, 'beginning' );
      
    end;
    
    *keep contract_number ward2002 rpt_date rpt_date_yr loss_date active_: expired_: terminated_: lost_: cum_lost_: ;
    
    format rpt_date mmddyy10. dt0 dt1 mmddyy8.;
    
  run;
  
  proc summary data=S8losses_det nway;
    class rpt_date rpt_date_yr;
    var active_: expired_: terminated_: lost_: cum_lost_: ;
    output out=S8losses_tbl (drop=_type_ _freq_) sum=;
  run;

  run;

  ** Write report title info **;

  data PreservationTitles (compress=no);
    preservation_per = "&g_s8_pres_period_lbl_a";
    start_date = put( &start_date, mmddyy10. );
  run;

  %Write_dde( dde=&dde, rpt_xls=&g_s8_rpt_xls, sheet=Titles, range=r8c2:r8c2, data=PreservationTitles, var=preservation_per )
  %Write_dde( dde=&dde, rpt_xls=&g_s8_rpt_xls, sheet=Titles, range=r9c2:r9c2, data=PreservationTitles, var=start_date )

  ** Active/Lost chart **;

  proc summary data=S8losses_det nway;
    class rpt_date rpt_date_yr;
    var active_units cum_lost_units lost_units expired_units terminated_units;
    output out=S8losses_chart (drop=_type_ _freq_) sum=;
  run;

  proc print data=S8losses_chart ;
    title2 'S8losses_chart';

  run;

  %Write_dde( dde=&dde, rpt_xls=&g_s8_rpt_xls, sheet=Preservation, range=r6c12:r31c14, data=S8losses_chart, 
    var=rpt_date_yr active_units cum_lost_units )

  ** Units by year **;

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
          &g_s8_pres_end_date_yr = "&g_s8_pres_end_date_yr Q1-Q&g_s8_pres_end_date_qtr"
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

  %Write_dde( dde=&dde, rpt_xls=&g_s8_rpt_xls, sheet=Preservation, range=r27c2:r34c7, data=S8losses_year, 
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

  %Write_dde( dde=&dde, rpt_xls=&g_s8_rpt_xls, sheet=Preservation, range=r39c2:r47c7, data=S8losses_ward, 
    var=ward2002 active_units &BLANK lost_units expired_units terminated_units )

%mend S8preservation_new;

/** End Macro Definition **/

