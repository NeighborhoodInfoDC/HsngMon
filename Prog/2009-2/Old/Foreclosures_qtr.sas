/**************************************************************************
 Program:  Foreclosures_qtr.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  04/24/09
 Version:  SAS 9.1
 Environment:  Windows
 
 Description:  Create quarterly foreclosure data set.

 Modifications:
**************************************************************************/

%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";

** Define libraries **;
%DCData_lib( HsngMon )
%DCData_lib( Rod )

%let rpt_start_dt = '01jan1999'd;
%let rpt_end_dt   = '31mar2009'd;
%let out_ds       = HsngMon.Foreclosures_qtr_2009_2;

data &out_ds;

  set Rod.Foreclosures_history (obs=20000000);
  
  ** Set episode dates **;
  
  if not( missing( firstnotice_date ) ) then start_dt = firstnotice_date;
  else if not( missing( outcome_date ) ) then start_dt = outcome_date - 365;
  
  if not( missing( outcome_date ) ) then end_dt = outcome_date;
  else if not( missing( firstnotice_date ) ) then end_dt = firstnotice_date + 365;
  
  if missing( start_dt ) or missing( end_dt ) then delete;
  
  ** Align start and end dates with beginning of quarter **;
  
  start_dt = intnx( 'qtr', start_dt, 0, 'beginning' );
  end_dt = intnx( 'qtr', end_dt, 0, 'beginning' );
  
  put start_dt= end_dt= ;
  
  ** Create obs. for each ssl/episode/qtr **;
  
  in_foreclosure = 1;
  
  dt = intnx( 'qtr', max( start_dt, &rpt_start_dt ), 0, 'beginning' );
  
  do while ( dt <= min( end_dt, &rpt_end_dt ) );
  
    foreclosure_avoided = 0;
    foreclosure_sale = 0;
    distressed_sale = 0;
          
    if dt = start_dt then foreclosure_start = 1;
    else foreclosure_start = 0;
    
    if dt = end_dt then do;
    
      select ( outcome_code );
        when ( 1, 4, 5, 6, .n )
          foreclosure_avoided = 1;
        when ( 2 ) 
          foreclosure_sale = 1;
        when ( 3 )
          distressed_sale = 1;
        otherwise do;
          %warn_put( msg="Unknown outcome code: " _n_= ssl= outcome_code= )
        end;
      end;
      
    end;
      
    output;
    
    dt = intnx( 'qtr', dt, 1, 'beginning' );
              
  end;
  
  format dt start_dt end_dt mmddyy10.;
  
  keep 
    ssl ui_proptype 
    dt firstnotice_date outcome_date start_dt end_dt outcome_code 
    in_foreclosure foreclosure_start foreclosure_sale distressed_sale foreclosure_avoided;
  
run;

proc print data=&out_ds (obs=50);
  by ssl;
  id dt;
  var firstnotice_date outcome_date start_dt end_dt outcome_code 
      in_foreclosure foreclosure_start foreclosure_sale distressed_sale foreclosure_avoided;
run;

** Summarize data for chart **;

proc summary data=&out_ds nway;
  where ui_proptype in ( '10', '11' );
  class dt;
  var in_foreclosure foreclosure_start foreclosure_sale distressed_sale foreclosure_avoided;
  output out=Chart (drop=_type_ _freq_) sum=;
run;

proc print data=Chart;
  id dt;
run;

filename fexport "d:\DCData\Libraries\HsngMon\Prog\2009-2\Chart.csv" lrecl=1000;

proc export data=Chart
    outfile=fexport
    dbms=csv replace;

run;

filename fexport clear;

