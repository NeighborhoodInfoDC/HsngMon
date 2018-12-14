/**************************************************************************
 Program:  Owner_units_series.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  03/25/06
 Version:  SAS 8.2
 Environment:  Windows with SAS/Connect
 
 Description:  Number of ownership units (s.f., condo, coop) by quarter.

 Modifications:
**************************************************************************/

%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";
%include "K:\Metro\PTatian\DCData\SAS\Inc\AlphaSignon.sas" /nosource2;

** Define libraries **;
%DCData_lib( RealProp )

rsubmit;

%let start_dt = '01apr2001'd;
%let end_dt   = '31dec2005'd;

data Parcel_qtr (compress=no);

  set RealProp.Parcel_base (keep=ssl ui_proptype ownerpt_extractdat_first ownerpt_extractdat_last no_units);

  *where ownerpt_extractdat_last < '01jan2006'd;

  i = 0;
  qtr_start_dt = intnx( 'qtr', &start_dt, i, 'beginning' );
  qtr_end_dt = intnx( 'qtr', &start_dt, i, 'end' );

  format qtr_start_dt qtr_end_dt mmddyy10.;

  do until ( qtr_end_dt > &end_dt );

    if ( ownerpt_extractdat_first <= qtr_start_dt <= ownerpt_extractdat_last ) or 
       ( ownerpt_extractdat_first <= qtr_end_dt <= ownerpt_extractdat_last ) or
       ( ownerpt_extractdat_first < qtr_start_dt and qtr_end_dt < ownerpt_extractdat_last )
    then do;

      if ui_proptype in ( '10', '11' ) then units = 1;
      else if ui_proptype in ( '12' ) then units = no_units;

    end;
    else do;
      units = 0;
    end;

    output;

    i = i + 1;
    qtr_start_dt = intnx( 'qtr', &start_dt, i, 'beginning' );
    qtr_end_dt = intnx( 'qtr', &start_dt, i, 'end' );

  end;

  keep ssl ui_proptype qtr_start_dt units /*ownerpt_extractdat_first ownerpt_extractdat_last*/;
                                                                     
run;

/*
proc print;
  id ssl ui_proptype ownerpt_extractdat_first ownerpt_extractdat_last;
  by ssl ui_proptype ownerpt_extractdat_first ownerpt_extractdat_last;

run;
*/

proc summary data=parcel_qtr nway;
  class ui_proptype qtr_start_dt;
  var units;
  output out=sum_qtr (compress=no drop=_freq_ _type_) sum= ;

proc print data=sum_qtr;

run;

proc transpose data=sum_qtr out=sum_qtr_tr (compress=no drop=_name_) prefix=units_;
  var units;
  id qtr_start_dt;
  idlabel qtr_start_dt;
  by ui_proptype;
  format qtr_start_dt yyq.;

proc print data=sum_qtr_tr noobs label;
  id ui_proptype;

run;

proc download status=no
  data=sum_qtr_tr 
  out=sum_qtr_tr;

run;

endrsubmit;

filename fexport "D:\DCData\Projects\HsngMon\Reports\2006-2\Owner_units_series.csv" lrecl=1000;

proc export data=sum_qtr_tr
    outfile=fexport
    dbms=csv replace;

run;

filename fexport clear;

signoff;

