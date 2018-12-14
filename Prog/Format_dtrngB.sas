/**************************************************************************
 Program:  Format_dtrngB.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  04/07/07
 Version:  SAS 9.1
 Environment:  Windows
 
 Description:  Make sales table format dtrngB.

 Modifications:
  08/05/07  Creates g_price_a - g_price_e macro vars.
**************************************************************************/

/** Macro Format_dtrngB - Start Definition **/

%macro Format_dtrngB( lib=work );

  %global g_price_a g_price_b g_price_c g_price_d g_price_e;

  %let fmtname = dtrngB;

  ** Create dtrngB format **;

  data _cntlin (compress=no);

    length label $ 80;

    retain fmtname "&fmtname" type 'n' sexcl 'n' eexcl 'n' hlo 's ';
    
    format dt0 dt1 mmddyy10.;
    
    end_qtr = qtr( &g_sales_end_dt );
    
    %note_put( macro=Format_dtrngB, msg=fmtname= end_qtr= )
    
    ** Current quarter **;
    
    dt0 = intnx( 'qtr', &g_sales_end_dt, 0, 'beginning' );
    dt1 = intnx( 'qtr', &g_sales_end_dt, 0, 'end' );
    
    start = put( dt0, 8. );
    end = put( dt1, 8. );
    
    label = trim( left( put( dt0, year4. ) ) ) || ' Q' || left( put( dt0, qtr1. ) ); 
    
    call symput( 'g_price_a', 'price' || trim( left( put( dt0, year4. ) ) ) || '_q' || left( put( dt0, qtr1. ) ) );
    
    output;
    
    %note_put( macro=Format_dtrngB, msg=dt0= dt1= label= )
    
    ** Prior quarter **;
    
    dt0 = intnx( 'qtr', &g_sales_end_dt, -1, 'beginning' );
    dt1 = intnx( 'qtr', &g_sales_end_dt, -1, 'end' );
    
    start = put( dt0, 8. );
    end = put( dt1, 8. );
    
    label = trim( left( put( dt0, year4. ) ) ) || ' Q' || left( put( dt0, qtr1. ) ); 
    
    call symput( 'g_price_b', 'price' || trim( left( put( dt0, year4. ) ) ) || '_q' || left( put( dt0, qtr1. ) ) );
    
    output;
    
    %note_put( macro=Format_dtrngB, msg=dt0= dt1= label= )
    
    ** Same quarter 1 year ago **;
    
    dt0 = intnx( 'qtr', &g_sales_end_dt, -1 * 4, 'beginning' );
    dt1 = intnx( 'qtr', &g_sales_end_dt, -1 * 4, 'end' );
    
    start = put( dt0, 8. );
    end = put( dt1, 8. );
    
    label = trim( left( put( dt0, year4. ) ) ) || ' Q' || left( put( dt0, qtr1. ) ); 
    
    call symput( 'g_price_c', 'price' || trim( left( put( dt0, year4. ) ) ) || '_q' || left( put( dt0, qtr1. ) ) );
    
    output;
    
    %note_put( macro=Format_dtrngB, msg=dt0= dt1= label= )
    
    ** Same quarter 5 years ago **;
    
    dt0 = intnx( 'qtr', &g_sales_end_dt, -5 * 4, 'beginning' );
    dt1 = intnx( 'qtr', &g_sales_end_dt, -5 * 4, 'end' );
    
    start = put( dt0, 8. );
    end = put( dt1, 8. );
    
    label = trim( left( put( dt0, year4. ) ) ) || ' Q' || left( put( dt0, qtr1. ) ); 
    
    call symput( 'g_price_d', 'price' || trim( left( put( dt0, year4. ) ) ) || '_q' || left( put( dt0, qtr1. ) ) );
    
    output;
    
    %note_put( macro=Format_dtrngB, msg=dt0= dt1= label= )
    
    ** Same quarter 10 years ago **;
    
    dt0 = intnx( 'qtr', &g_sales_end_dt, -10 * 4, 'beginning' );
    dt1 = intnx( 'qtr', &g_sales_end_dt, -10 * 4, 'end' );
    
    start = put( dt0, 8. );
    end = put( dt1, 8. );
    
    label = trim( left( put( dt0, year4. ) ) ) || ' Q' || left( put( dt0, qtr1. ) ); 
    
    call symput( 'g_price_e', 'price' || trim( left( put( dt0, year4. ) ) ) || '_q' || left( put( dt0, qtr1. ) ) );
    
    output;
    
    %note_put( macro=Format_dtrngB, msg=dt0= dt1= label= )
    
    ** Other dates return blank **;
    
    hlo = 'so';
    label = '';
    
    output;
    
  run;

  %put g_price_a=&g_price_a;
  %put g_price_b=&g_price_b;
  %put g_price_c=&g_price_c;
  %put g_price_d=&g_price_d;
  %put g_price_e=&g_price_e;

  proc format library=&lib cntlin=_cntlin;

  proc format library=&lib fmtlib;
    select &fmtname;

  run;

%mend Format_dtrngB;

/** End Macro Definition **/

