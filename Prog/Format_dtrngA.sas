/**************************************************************************
 Program:  Format_dtrngA.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  04/07/07
 Version:  SAS 9.1
 Environment:  Windows
 
 Description:  Make sales table format dtrngA.

 Modifications:
**************************************************************************/

/** Macro Format_dtrngA - Start Definition **/

%macro Format_dtrngA( lib=work, fmtname=, rng_suffix= );

  ** Create dtrngA format **;

  data _cntlin (compress=no);

    length label $ 80;

    retain fmtname "&fmtname" type 'n' sexcl 'n' eexcl 'n' hlo 's ';
    
    format dt0 dt1 mmddyy10.;
    
    end_qtr = qtr( &g_sales_end_dt );
    
    %note_put( macro=Format_dtrngA, msg=fmtname= end_qtr= )
    
    ** Quarters of current year **;
    
    do i = 0 to ( end_qtr - 1 );
    
      dt0 = intnx( 'qtr', &g_sales_end_dt, -i, 'beginning' );
      dt1 = intnx( 'qtr', &g_sales_end_dt, -i, 'end' );
      
      start = put( dt0, 8. );
      end = put( dt1, 8. );
      
      label = trim( left( put( dt0, year4. ) ) ) || ' Q' || left( put( dt0, qtr1. ) ); 
      
      output;
      
      %note_put( macro=Format_dtrngA, msg=dt0= dt1= label= )
    
    end;
    
    ** Prior year **;
    
    dt0 = intnx( 'year', &g_sales_end_dt, -1, 'beginning' );
    dt1 = intnx( 'year', &g_sales_end_dt, -1, 'end' );
    
    start = put( dt0, 8. );
    end = put( dt1, 8. );
    
    label = trim( left( put( dt0, year4. ) ) ); 
    
    output;
    
    %note_put( macro=Format_dtrngA, msg=dt0= dt1= label= )
    
    ** 1st year range **;
    
    dt0 = intnx( 'year', &g_sales_end_dt, -5, 'beginning' );
    dt1 = intnx( 'year', &g_sales_end_dt, -2, 'end' );
    
    start = put( dt0, 8. );
    end = put( dt1, 8. );
    
    label = trim( left( put( dt0, year4. ) ) ) || '-' || trim( left( put( dt1, year4. ) ) ) ||
            " &rng_suffix"; 
    
    output;
    
    %note_put( macro=Format_dtrngA, msg=dt0= dt1= label= )
    
    ** 2nd year range **;
    
    dt0 = intnx( 'year', &g_sales_end_dt, -10, 'beginning' );
    dt1 = intnx( 'year', &g_sales_end_dt, -6, 'end' );
    
    start = put( dt0, 8. );
    end = put( dt1, 8. );
    
    label = trim( left( put( dt0, year4. ) ) ) || '-' || trim( left( put( dt1, year4. ) ) ) ||
            " &rng_suffix"; 
    
    output;
    
    %note_put( macro=Format_dtrngA, msg=dt0= dt1= label= )
    
    ** Other dates return blank **;

    hlo = 'so';
    label = '';
    
    output;
    
  run;

  proc format library=&lib cntlin=_cntlin;

  proc format library=&lib fmtlib;
    select &fmtname;

  run;

%mend Format_dtrngA;

/** End Macro Definition **/

