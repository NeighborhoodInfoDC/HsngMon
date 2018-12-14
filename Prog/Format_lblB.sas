/**************************************************************************
 Program:  Format_lblB.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  04/07/07
 Version:  SAS 9.1
 Environment:  Windows
 
 Description:  Make sales table format lblB.

 Modifications:
**************************************************************************/

/** Macro Format_lblB - Start Definition **/

%macro Format_lblB( lib=work );

  %let fmtname = lblB;

  ** Create lblB format **;

  data _cntlin (compress=no);

    length label $ 80;

    retain fmtname "&fmtname" type 'n' sexcl 'n' eexcl 'n' hlo 's ' start 4;
    
    format dt0 dt1 mmddyy10.;
    
    end_qtr = qtr( &g_sales_end_dt );
    
    %note_put( macro=Format_lblB, msg=fmtname= end_qtr= )
    
    ** Prior to current quarter **;
    
    dt0 = intnx( 'qtr', &g_sales_end_dt, -1, 'beginning' );
    dt1 = intnx( 'qtr', &g_sales_end_dt, 0, 'beginning' );
    
    label = trim( left( put( dt0, year4. ) ) ) || ' Q' || left( put( dt0, qtr1. ) ) || 
            ' - ' ||
            trim( left( put( dt1, year4. ) ) ) || ' Q' || left( put( dt1, qtr1. ) ); 
    
    output;
    
    %note_put( macro=Format_lblB, msg=dt0= dt1= label= )
    
    start = start - 1;
    
    ** Same quarter 1 year ago to current quarter **;
    
    dt0 = intnx( 'qtr', &g_sales_end_dt, -1 * 4, 'beginning' );
    dt1 = intnx( 'qtr', &g_sales_end_dt, 0, 'beginning' );
    
    label = trim( left( put( dt0, year4. ) ) ) || ' Q' || left( put( dt0, qtr1. ) ) || 
            ' - ' ||
            trim( left( put( dt1, year4. ) ) ) || ' Q' || left( put( dt1, qtr1. ) ); 
    
    output;
    
    %note_put( macro=Format_lblB, msg=dt0= dt1= label= )
    
    start = start - 1;
    
    ** Same quarter 5 years ago to current quarter **;
    
    dt0 = intnx( 'qtr', &g_sales_end_dt, -5 * 4, 'beginning' );
    dt1 = intnx( 'qtr', &g_sales_end_dt, 0, 'beginning' );
    
    label = trim( left( put( dt0, year4. ) ) ) || ' Q' || left( put( dt0, qtr1. ) ) || 
            ' - ' ||
            trim( left( put( dt1, year4. ) ) ) || ' Q' || left( put( dt1, qtr1. ) ) ||
            ' (annualized)'; 
    
    output;
    
    %note_put( macro=Format_lblB, msg=dt0= dt1= label= )
    
    start = start - 1;
    
    ** Same quarter 10 years ago to current quarter **;
    
    dt0 = intnx( 'qtr', &g_sales_end_dt, -10 * 4, 'beginning' );
    dt1 = intnx( 'qtr', &g_sales_end_dt, 0, 'beginning' );
    
    label = trim( left( put( dt0, year4. ) ) ) || ' Q' || left( put( dt0, qtr1. ) ) || 
            ' - ' ||
            trim( left( put( dt1, year4. ) ) ) || ' Q' || left( put( dt1, qtr1. ) ) ||
            ' (annualized)'; 
    
    output;
    
    %note_put( macro=Format_lblB, msg=dt0= dt1= label= )
    
    start = start - 1;
    
    ** Other dates return blank **;
    
    hlo = 'so';
    label = '';
    
    output;
    
  run;

  proc format library=&lib cntlin=_cntlin;

  proc format library=&lib fmtlib;
    select &fmtname;

  run;

%mend Format_lblB;

/** End Macro Definition **/

