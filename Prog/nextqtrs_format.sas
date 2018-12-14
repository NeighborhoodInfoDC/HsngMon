/**************************************************************************
 Program:  nextqtrs_format.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  08/30/06
 Version:  SAS 8.2
 Environment:  Windows
 
 Description:  Autocall macro to create nextqtrs. format, next
 &num_qtrs quarters including &date.

 Modifications:
**************************************************************************/

/** Macro nextqtrs_format - Start Definition **/

%macro nextqtrs_format( 
  date=, 
  num_qtrs=4, 
  lib=work, 
  fmtname=nextqtrs, 
  label_prefix=, 
  month_fmt=monname3. 
);

  ** Create quarter/year format for report tables **;
  ** Next &num_qtrs quarters (nextqtrs.)          **;

  data _cntlin;

    length label $ 80;

    retain fmtname "&fmtname" type 'n' sexcl 'n' eexcl 'n' hlo ' ';
    
    ** Missing date value represents Total **;
    
    label = 'Total';
    output;
    
    eexcl = 'y';
    
    do i = 0 to (&num_qtrs) - 1;
    
      dt0 = intnx( 'qtr', &date, i, 'beginning' );
      dt1 = intnx( 'qtr', &date, i + 1, 'beginning' );
      
      format dt0 dt1 mmddyy10.;
    
      start = put( dt0, 8. );
      end = put( dt1, 8. );
      
      label = "&label_prefix" ||
              trim( left( put( dt0, &month_fmt ) ) ) ||
              '-' || 
              trim( left( put( dt1 - 1, &month_fmt ) ) ) ||
              ' ' ||
              left( put( dt0, year4. ) );
      
      output;
    
    end;
    
    hlo = 'o';
    label = '';
    
    output;
    
  run;

  proc format library=&lib cntlin=_cntlin fmtlib;

  run;

%mend nextqtrs_format;

/** End Macro Definition **/

