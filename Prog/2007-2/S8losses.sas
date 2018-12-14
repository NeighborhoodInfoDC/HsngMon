/**************************************************************************
 Program:  S8losses.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  03/03/07
 Version:  SAS 9.1
 Environment:  Windows
 
 Description:  Determine number of lost Section 8 units.

 Modifications:
**************************************************************************/

%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";
***%include "C:\DCData\SAS\Inc\Stdhead.sas";

** Define libraries **;
%DCData_lib( HsngMon )
%DCData_lib( HUD )

%let hud_file_date = '02/06/2007';

%let rpt_yr = 2007;
%let rpt_qtr = 2;
%let rpt_file = S8summary_&rpt_yr._&rpt_qtr;

%let rpt_path = &_dcdata_path\HsngMon\Prog\&rpt_yr-&rpt_qtr;
%let rpt_file = S8summary_&rpt_yr._&rpt_qtr;
%let rpt_xls  = &rpt_file..xls;

%let LOSS_REPORT_LAG_DAYS = 180;

%let BLANK = '20'x;    ** Blank character for DDE output **;

** Report starting and ending dates **;

%let start_date = '01jan2000'd;

data _null_;
  
  hud_file_sas_dt = input( &hud_file_date, mmddyy10. );
  put hud_file_sas_dt= mmddyy10.;
  
  end_date = intnx( 'qtr', hud_file_sas_dt - &LOSS_REPORT_LAG_DAYS, -1, 'end' );
  
  put end_date= mmddyy10.;
  
  call symput( 'end_date', end_date );

run;  

%put start_date=&start_date end_date=&end_date;

data S8losses (compress=no);

  set HsngMon.&rpt_file;
  ***where contract_number in ( 'DC390001009' 'DC390001010', 'DC39H001007' );
  
  if cur_tracs_status = 'T' then 
    loss_date = min( date_cur_ui_status, cur_expiration_date );
  else
    loss_date = cur_expiration_date;
    
  if loss_date >= &start_date;
  
  format loss_date mmddyy10.;
 
run;  

/*
proc tabulate data=S8losses format=comma10.0 noseps missing;
  class cur_tracs_status;
  var cur_assisted_units_count;
  table all='Total' cur_tracs_status=' ',
    n='Contracts' sum='Assisted Units'*cur_assisted_units_count=' ';
run;
  
proc print data=S8losses;
  id contract_number;
  var ward2002 loss_date cur_tracs_status date_cur_ui_status date_cur_contract cur_expiration_date cur_assisted_units_count;

run;
*/

proc print data=S8losses;
  where not( cur_assisted_units_count > 0 );
  id contract_number;
  var ward2002 loss_date cur_tracs_status date_cur_ui_status date_cur_contract cur_expiration_date cur_assisted_units_count;
  title2 '***** Projects with missing assisted unit count *****';
run;

title2;

data S8losses_det (compress=no);

  i = 0;
  dt0 = intnx( 'qtr', &start_date, i, 'beginning' );
  
  set S8losses (keep=contract_number ward2002 loss_date cur_assisted_units_count cur_tracs_status);
  
  active_contract = 1;
  active_units = cur_assisted_units_count;
  
  cum_lost_contract = 0;
  cum_lost_units = 0;
  
  do while( dt0 <= &end_date );

    dt1 = intnx( 'qtr', dt0, 0, 'end' );
    dt2 = intnx( 'qtr', dt0, 1, 'end' );
    
    if dt0 <= loss_date <= dt1 then do;

      if cur_tracs_status = 'T' then do;
        terminated_contract = 1;
        terminated_units = cur_assisted_units_count;
      end;
      else do;
        expired_contract = 1;
        expired_units = cur_assisted_units_count;
      end;
      
    end;
    else do;
    
      terminated_contract = 0;
      terminated_units = 0;
      expired_contract = 0;
      expired_units = 0;
    
    end;
    
    if loss_date < dt0 then do;
      active_contract = 0;
      active_units = 0;
      cum_lost_contract = 1;
      cum_lost_units = cur_assisted_units_count;
    end;
    
    lost_contracts = expired_contract + terminated_contract;
    lost_units = expired_units + terminated_units;

    rpt_date = dt0;
    rpt_date_yr = year( rpt_date );
    
    output;

    i = i + 1;
    dt0 = intnx( 'qtr', &start_date, i, 'beginning' );

  end;
  
  keep contract_number ward2002 rpt_date rpt_date_yr loss_date active_: expired_: terminated_: lost_: cum_lost_: ;
  
  format rpt_date mmddyy10.;
  
run;

/*
proc print;
  id contract_number;
  by contract_number;
  var ward2002 rpt_date loss_date active_: expired_: terminated_: lost_: cum_lost_: ;
run;
*/

proc summary data=S8losses_det nway;
  class rpt_date rpt_date_yr;
  var active_: expired_: terminated_: lost_: cum_lost_: ;
  output out=S8losses_tbl (drop=_type_ _freq_) sum=;
run;

***proc print;

run;


** Create output data for report **;

/** Macro Write_dde - Start Definition **/

%macro Write_dde( sheet=, range=, data=, var=, fopt=notab );

  filename xlsFile dde "excel|&rpt_path\[&rpt_xls]&sheet!&range" lrecl=256 &fopt;

  data _null_;

    set HsngMon.&rpt_file;
    
    file xlsFile;
    
    %*put &var;
    
    %let i = 1;
    %let v = %scan( &var, &i );
    
    %do %while ( &v ~= );
      put &v '09'x @;
      %let i = %eval( &i + 1 );
      %let v = %scan( &var, &i );
    %end;
    
    put;
    
  run;

  filename xlsFile clear;

%mend Write_dde;

/** End Macro Definition **/

***** NB:  Need to write preservation date range to Titles!B8 *****;



** Active/Lost chart **;

proc summary data=S8losses_det nway;
  class rpt_date rpt_date_yr;
  var active_units cum_lost_units lost_units expired_units terminated_units;
  output out=S8losses_chart (drop=_type_ _freq_) sum=;
run;


***proc print data=S8losses_chart ;

run;

%Write_dde( sheet=Preservation, range=r6c12:r31c14, data=S8losses_chart, 
  var=rpt_date_yr active_units cum_lost_units )
  
** Units by year **;

proc summary data=S8losses_chart;
  class rpt_date_yr;
  var active_units lost_units expired_units terminated_units;
  output out=S8losses_year 
    max(active_units)=
    sum(lost_units expired_units terminated_units)= ;
run;

proc format;
  value rptyr
    . = 'Total'
    2006 = '2006 Q1-Q2';

data S8losses_year;
  set S8losses_year;
  if rpt_date_yr = . then active_units = .;
  format rpt_date_yr rptyr.;
run;

options missing='-';

proc sort data=S8losses_year;
  by descending _type_ rpt_date_yr;

/*
proc print data=S8losses_year;
  format rpt_date_yr rptyr.;
run;
*/

%Write_dde( sheet=Preservation, range=r27c2:r34c7, data=S8losses_year, 
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

***proc print;

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
  
***proc print;

%Write_dde( sheet=Preservation, range=r39c2:r47c7, data=S8losses_ward, 
  var=ward2002 active_units &BLANK lost_units expired_units terminated_units )
  


