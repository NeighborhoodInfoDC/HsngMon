/**************************************************************************
 Program:  Time_to_foreclosure.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  07/29/09
 Version:  SAS 9.1
 Environment:  Windows
 
 Description:  Average time to foreclosure by year.

 Modifications:
**************************************************************************/

%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";

** Define libraries **;
%DCData_lib( HsngMon )
%DCData_lib( ROD )

data time_to_foreclosure;

  set Rod.Foreclosures_history;
    where ui_proptype in ( '10', '11' ) and outcome_code = 2;
    
  ** Set episode dates **;
  
  if not( missing( firstnotice_date ) ) then start_dt = firstnotice_date;
  else if not( missing( outcome_date ) ) then start_dt = outcome_date - 365;
  
  if not( missing( outcome_date ) ) then end_dt = outcome_date;
  else if not( missing( lastnotice_date ) ) then end_dt = lastnotice_date + 365;
  else if not( missing( firstnotice_date ) ) then end_dt = firstnotice_date + 365;
  
  if missing( start_dt ) or missing( end_dt ) then delete;
  
  if '01jan1999'd <= start_dt < '01apr2009'd;
  
  days = end_dt - start_dt;  

run;

proc format;
  value $prop
    '10' = 'Single-family homes'
    '11' = 'Condominium units'
    '12', '13' = 'Multifamily (Coops/Rental)';
run;

ods rtf file="&_dcdata_path\HsngMon\prog\2009-3\Time_to_foreclosure.rtf" style=Styles.Rtf_arial_9pt;
ods html body="&_dcdata_path\HsngMon\prog\2009-3\Time_to_foreclosure.html" style=Minimal;


options nodate;

** By annual foreclosure starts through 2008-Q2 **;

proc tabulate data=Time_to_foreclosure format=comma10.0 noseps missing;
  where '01jan1999'd <= start_dt < '01jul2008'd;
  class ui_proptype start_dt;
  var days;
  table 
    /** Rows **/
    start_dt=' ',
    /** Columns **/
    n='Properties Going to Foreclosure Sale'
    ( mean='Average Time to Foreclosure (Days)' * days=' ' ) * ( all='\~\~Total' ui_proptype=' ' )
    / box='Foreclosure Start';
  format ui_proptype $prop. start_dt year4.;

run;

** By quarterly foreclosure starts through 2009-Q1 **;

proc tabulate data=Time_to_foreclosure format=comma10.0 noseps missing;
  where '01jan2007'd <= start_dt < '01apr2009'd;
  class ui_proptype start_dt;
  var days;
  table 
    /** Rows **/
    start_dt=' ',
    /** Columns **/
    n='Properties Going to Foreclosure Sale'
    ( mean='Average Time to Foreclosure (Days)' * days=' ' ) * ( all='\~\~Total' ui_proptype=' ' )
    / box='Foreclosure Start';
  format ui_proptype $prop. start_dt yyq.;

run;

ods rtf close;
ods html close;

