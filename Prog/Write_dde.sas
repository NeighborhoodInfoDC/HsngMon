/**************************************************************************
 Program:  Write_dde.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  11/23/07
 Version:  SAS 9.1
 Environment:  Windows
 
 Description:  Autocall macro to write data using DDE.

 Modifications:
**************************************************************************/

/** Macro Write_dde - Start Definition **/

%macro Write_dde( rpt_xls=&g_s8_rpt_xls, sheet=, range=, data=, var=, fopt=notab, dde=y );

  %if %upcase( &dde ) = Y %then %do;
    filename xlsFile dde "excel|&&g_path\[&rpt_xls]&sheet!&range" lrecl=256 &fopt;
  %end;
  %else %do;
    %let range = %sysfunc( compress( &range, ':' ) );
    filename xlsFile "&&g_path\_tmp_&rpt_xls..&sheet..&range..txt" lrecl=256;
  %end;

  data _null_;

    set &data;
    
    file xlsFile;
    
    %*put &var;
    
    %let i = 1;
    %let v = %scan( &var, &i );
    
    %do %while ( &v ~= );
      put &v '09'x @;
      %let i = %eval( &i + 1 );
      %let v = %scan( &var, &i );
    %end;
    
    put;
    
  run;

  filename xlsFile clear;

%mend Write_dde;

/** End Macro Definition **/

