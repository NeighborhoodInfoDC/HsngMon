/**************************************************************************
 Program:  prevqtrs_format.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  08/30/06
 Version:  SAS 8.2
 Environment:  Windows
 
 Description:  Autocall macro to create format prevqtrs., previous
 &num_qtrs quarters starting with quarter prior to &date.

 Modifications:
**************************************************************************/

/** Macro prevqtrs_format - Start Definition **/

%macro prevqtrs_format( 
  date=, 
  num_qtrs=4, 
  lib=work, 
  fmtname=prevqtrs, 
  label_prefix=,
  month_fmt=monname3. 
);

  ** Create quarter/year format for report tables **;
  ** Previous &num_qtrs quarters (prevqtrs.)       **;

  data _cntlin;

    length label $ 80;

    retain fmtname "&fmtname" type 'n' sexcl 'n' eexcl 'n' hlo ' ';
    
    ** Missing date value represents Total **;
    
    label = 'Total';
    output;
    
    eexcl = 'y';
    
    do i = -(&num_qtrs) to -1;
    
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

%mend prevqtrs_format;

/** End Macro Definition **/

