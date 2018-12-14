/**************************************************************************
 Program:  Prop_w_notice_tbl.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  07/29/09
 Version:  SAS 9.1
 Environment:  Windows
 
 Description:  Properties w/foreclosure notice issued by type by year/qtr
 
 WINTER 2010

 Modifications:
**************************************************************************/

%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";

** Define libraries **;
%DCData_lib( HsngMon )
%DCData_lib( ROD )
%DCData_lib( RealProp )

%let last_qtr = 3;
%let last_year = 2009;

** Annual totals **;

proc summary data=HsngMon.Foreclosures_1999_2009 nway;
  where ui_instrument = 'F1' and ui_proptype in ( '10', '11', '12', '13' ) and filingdate < '01jan2009'd;
  class filingdate ssl;
  id ui_proptype;
  format filingdate year4.;
  output out=Prop_w_notice_year ;
run;

** Q1 - Q3 totals **;

proc summary data=HsngMon.Foreclosures_1999_2009 nway;
  where ui_instrument = 'F1' and ui_proptype in ( '10', '11', '12', '13' ) and filingdate < '01oct2009'd and
  1 <= qtr( filingdate ) <= &last_qtr.;
  class filingdate ssl;
  id ui_proptype;
  format filingdate year4.;
  output out=Prop_w_notice_qtr ;
run;

proc print data=Prop_w_notice_qtr (obs=100);
run;

proc format;
  value $prop
    '10' = 'Single-family homes'
    '11' = 'Condominium units'
    '12', '13' = 'Multifamily (Coops/Rental)';
run;

ods rtf file="&_dcdata_path\HsngMon\prog\2009-4\Prop_w_notice.rtf" style=Styles.Rtf_arial_9pt;
ods html body="&_dcdata_path\HsngMon\prog\2009-4\Prop_w_notice.html" style=Minimal;

options nodate;

proc tabulate data=Prop_w_notice_year format=comma10.0 noseps missing;
  class ui_proptype filingdate;
  table 
    /** Rows **/
    filingdate=' ',
    /** Columns **/
    ( n='Properties Issued a Notice of Foreclosure Sale' ) * ui_proptype=' '
    / box='Annual';
  format ui_proptype $prop. filingdate year4.;

run;

proc tabulate data=Prop_w_notice_qtr format=comma10.0 noseps missing;
  class ui_proptype filingdate;
  table 
    /** Rows **/
    filingdate=' ',
    /** Columns **/
    ( n='Properties Issued a Notice of Foreclosure Sale' ) * ui_proptype=' '
    / box="First &last_qtr. Quarters";
  format ui_proptype $prop. filingdate year4.;

run;

ods _all_ close;
ods listing;

