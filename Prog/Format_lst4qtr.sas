/**************************************************************************
 Program:  Format_lst4qtr.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  11/22/07
 Version:  SAS 9.1
 Environment:  Windows
 
 Description:  Make sales table format lst4qtr. (last 4 quarters).

 Modifications:
**************************************************************************/

/** Macro Format_lst4qtr - Start Definition **/

%macro Format_lst4qtr( lib=work, fmtname=lst4qtr, rng_suffix= );

  ** Create lst4qtr format **;

  data _cntlin (compress=no);

    length label $ 80;

    retain fmtname "&fmtname" type 'n' sexcl 'n' eexcl 'n' hlo 's ';
    
    format dt0 dt1 mmddyy10.;
    
    end_qtr = qtr( &g_sales_end_dt );
    
    %note_put( macro=Format_lst4qtr, msg=fmtname= end_qtr= )
    
    ** Last 4 quarters **;
    
    do i = 0 to -3 by -1;
    
      dt0 = intnx( 'qtr', &g_sales_end_dt, i, 'beginning' );
      dt1 = intnx( 'qtr', &g_sales_end_dt, i, 'end' );
      
      start = put( dt0, 8. );
      end = put( dt1, 8. );
      
      label = trim( left( put( dt0, year4. ) ) ) || ' Q' || left( put( dt0, qtr1. ) ); 
      
      output;
      
      %note_put( macro=Format_lst4qtr, msg=dt0= dt1= label= )
    
    end;
    
    ** Other dates return blank **;

    hlo = 'so';
    label = '';
    
    output;
    
  run;

  proc format library=&lib cntlin=_cntlin;

  proc format library=&lib fmtlib;
    select &fmtname;

  run;

%mend Format_lst4qtr;

/** End Macro Definition **/

