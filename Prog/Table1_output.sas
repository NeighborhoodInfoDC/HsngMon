/**************************************************************************
 Program:  Table1_output.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  10/01/07
 Version:  SAS 9.1
 Environment:  Windows
 
 Description:  Autocall macro to write data for Housing Monitor table 1
 to Excel workbook.

 Modifications:
  11/22/07 PAT Added DDE= parameter, to switch from DDE to CSV output.
**************************************************************************/

/** Macro Table1_output - Start Definition **/

%macro Table1_output( start_row=, var=, data=, sheet=Table 1, fmt=dtrngA., rowlbl=, dde=Y );

  %let dde = %upcase( &dde );

  %if &rowlbl = %then %do;
    %let START_COL = 2;
    %let MAX_ROWS = 7;
  %end;
  %else %do;
    %let START_COL = 1;
    %let MAX_ROWS = 1;
  %end;

  %let end_row = %eval( &start_row + &MAX_ROWS - 1 );
  %let end_col = %eval( &START_COL + 9 + 1 );

  %let start_cell = r&start_row.c&START_COL;
  %let end_cell = r&end_row.c&end_col;

  %if &dde = Y %then %do;
    ** DDE output **;
    filename xout dde "excel|&g_path\[&g_table_wbk]&sheet!&start_cell:&end_cell" lrecl=1000 notab;
  %end;
  %else %do;
    ** CSV output **;
    filename xout "&g_path\_tmp_&g_table_wbk..&sheet..&start_cell.&end_cell..txt" lrecl=1000;
  %end;

  data _null_;

    file xout;
    
    set &data end=eof;
    %if &rowlbl = %then %do;
      by descending saledate;
    %end;
    
    %if &rowlbl = %then %do;
      if first.saledate then put saledate &fmt @;
    %end;
    %else %do;
      if _n_ = 1 then put &rowlbl '09'x @;
    %end;
    
    put '09'x &var @;
    
    %if &rowlbl = %then %do;
      if last.saledate then put;
    %end;
    %else %do;
      if eof then put;
    %end;
    
  run;

  filename xout clear;

%mend Table1_output;

/** End Macro Definition **/


