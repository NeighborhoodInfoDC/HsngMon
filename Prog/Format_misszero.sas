/**************************************************************************
 Program:  Format_misszero.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  11/23/07
 Version:  SAS 9.1
 Environment:  Windows
 
 Description:  Autocall macro to create format misszero.

 Modifications:
**************************************************************************/

/** Macro Format_misszero - Start Definition **/

%macro Format_misszero(  );

  ** Format to convert missing values (.) to 0 in output **;

  proc format;
    value misszero (default=10)
      . = '0';

  run;

%mend Format_misszero;

/** End Macro Definition **/

