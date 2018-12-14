/**************************************************************************
 Program:  Format_nextqtrs.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  11/23/07
 Version:  SAS 9.1
 Environment:  Windows
 
 Description:  Autocall macro to create Sec. 8 table format nextqtrs.

 Modifications:
**************************************************************************/

/** Macro Format_nextqtrs - Start Definition **/

%macro Format_nextqtrs( num_qtrs=&g_s8_rpt_num_qtrs );

  ** Create quarter/year format for report tables **;
  ** Next &num_qtrs quarters (nextqtrs.)          **;

  data _cntlin;

    length label $ 50;

    retain fmtname 'nextqtrs' type 'n' sexcl 'n' eexcl 'n' hlo ' ';
    
    ** Missing date value represents Total **;
    
    label = 'Total';
    output;
    
    eexcl = 'y';
    
    do i = 0 to (&num_qtrs) - 1;
    
      dt0 = intnx( 'qtr', &g_s8_rpt_dt, i, 'beginning' );
      dt1 = intnx( 'qtr', &g_s8_rpt_dt, i + 1, 'beginning' );
      
      format dt0 dt1 mmddyy10.;
    
      start = put( dt0, 8. );
      end = put( dt1, 8. );
      
      label = trim( left( put( dt0, monname3. ) ) ) ||
              '-' || 
              trim( left( put( dt1 - 1, monname3. ) ) ) ||
              ' ' ||
              left( put( dt0, year4. ) );
      
      output;
    
    end;
    
    hlo = 'o';
    label = '';
    
    output;
    
  run;

  proc format library=work cntlin=_cntlin fmtlib;
    select nextqtrs;

  run;

%mend Format_nextqtrs;

/** End Macro Definition **/

