/**************************************************************************
 Program:  S8preservation_data.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  11/23/07
 Version:  SAS 9.1
 Environment:  Windows
 
 Description:  Autocall macro to create Section 8 Multifamily Report:
 Preservation Summary.
 
 Modifications:
  02/01/08 PAT New version that uses project history file 
               (Hud.Sec8mf_history_dc).
  02/12/08 PAT Added more geography vars.
**************************************************************************/

/** Macro S8preservation_data - Start Definition **/

%macro S8preservation_data( hud_file_date=&g_s8_hud_file_date, start_date=&g_s8_pres_start_date, end_date=&g_s8_pres_end_date );

  %let DEBUG = *;        %** Blank for debugging, * for normal **;

  %let BLANK = '20'x;    %** Blank character for DDE output **;
  
  %let geovars = ward2002 geo2000 cluster_tr2000 anc2002;
  
  %let othervars = property_name_text cur_address_line1_text zip_code cur_rent_to_fmr_desc 
                   cur_total_unit_count
                   cur_program_type_name cur_owner_name owner_address_line1 owner_city_name
                   owner_state_code owner_zip_code mgmt_agent_org_name mgmt_agent_address_line1
                   mgmt_agent_city_name mgmt_agent_state_code mgmt_agent_zip_code;
  
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
      Hud.Sec8mf_history_dc (drop=&geovars)
      Next_contract;
    by contract_number contract_hist_rec;
    
    &DEBUG WHERE &FILTER;
    
    ** Corrections **;
    
    select ( contract_number );
      when ( 'DC39L000016' ) do;
        if contract_hist_rec = 1 then assisted_units_count = 36;
      end;
      when ( 'DC39L000013' ) do;
        if contract_hist_rec <= 7 then assisted_units_count = 45;
      end;
      when ( 'DC39L000075' ) do;
        if contract_hist_rec = 1 then do;
          assisted_units_count = 266;
          total_unit_count = 266;
        end;
      end;
      when ( 'DC39L000078' ) do;
        if contract_hist_rec <= 3 then do;
          assisted_units_count = 76;
          total_unit_count = 76;
        end;
      end;
      when ( 'DC39M000046' ) do;
        if contract_hist_rec = 1 then assisted_units_count = 72;
      end;
      when ( 'DC39T802001' ) do;
        if contract_hist_rec = 1 then assisted_units_count = 6;
      end;
      when ( 'DC390005009' ) do;
        if contract_hist_rec <= 3 then assisted_units_count = 97;
      end;
      when ( 'DC39M000033' ) do;
        if contract_hist_rec = 1 then assisted_units_count = 122;
      end;
      otherwise
        /** Do nothing **/;
    end;
    
  run;

  /*%File_info( data=History, stats= ) */
  
  data S8losses (compress=no);

    merge
      History
      /*HsngMon.&g_s8_rpt_file */
      Hud.Sec8mf_current_dc
        (keep=contract_number date_cur_ui_status cur_expiration_date 
              /*date_cur_contract*/ cur_tracs_status cur_assisted_units_count 
              &geovars &othervars
         in=inB);
    by contract_number;
    
    if inB;
    
    &DEBUG IF &FILTER;
    
    if cur_tracs_status = 'T' then 
      loss_date = min( date_cur_ui_status, cur_expiration_date );
    else
      loss_date = cur_expiration_date;
      
    if loss_date >= &start_date;
    
    format loss_date mmddyy10.;
   
  run;  
  
  /****
  proc print data=S8losses;
    where not( cur_assisted_units_count > 0 );
    id contract_number;
    var &geovars &othervars loss_date cur_tracs_status date_cur_ui_status date_cur_contract cur_expiration_date cur_assisted_units_count;
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
    
    do while( dt0 <= &end_date );
    
      &DEBUG PUT / "TOP OF DO WHILE LOOP: " i= DT0= active_units= loss_date=;
    
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
                           &geovars &othervars loss_date assisted_units_count cur_tracs_status);
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
          
          if loss_date >= dt0 then do;
            active_contract = 1;
            active_units = assisted_units_count;
          end;
          else do;
            active_contract = 0;
            active_units = 0;
          end;
        
        end;
        else do;
        
          if first_pass then assisted_units_count = .;
          
        end;

      end;
      
      &DEBUG PUT / "EXITING WHILE SET";
      
      ** If loss date is after start of current quarter, then count as active **;
      /*
      if loss_date >= dt0 then do;
        active_contract = 1;
        active_units = assisted_units_count;
      end;
      */
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
      
      ** Add to cumulative totals **;
     
      cum_lost_contract = cum_lost_contract + lost_contracts;
      cum_lost_units = cum_lost_units + lost_units;
      
      ** Adjust active counts **;
      
      active_contract = active_contract - lost_contracts;
      active_units = active_units - lost_units;      
      
      output;

      &DEBUG PUT / "OBS. WRITTEN: " (_ALL_) (=);
      
      ** Increment date to next quarter **;

      i = i + 1;
      dt0 = intnx( 'qtr', &start_date, i, 'beginning' );
      
    end;
    
    *keep contract_number &geovars &othervars rpt_date rpt_date_yr loss_date active_: expired_: terminated_: lost_: cum_lost_: ;
    
    format rpt_date mmddyy10. dt0 dt1 mmddyy8.;
    
  run;
  
  proc summary data=S8losses_det nway;
    class rpt_date rpt_date_yr;
    var active_: expired_: terminated_: lost_: cum_lost_: ;
    output out=S8losses_tbl (drop=_type_ _freq_) sum=;
  run;

  run;
  
  
%mend S8preservation_data;

/** End Macro Definition **/

