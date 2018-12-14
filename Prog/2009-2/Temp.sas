/**************************************************************************
 Program:  Temp.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  04/25/09
 Version:  SAS 9.1
 Environment:  Windows
 
 Description:

 Modifications:
**************************************************************************/

***%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";
%include "C:\DCData\SAS\Inc\Stdhead.sas";

** Define libraries **;
%DCData_lib( HsngMon )
%DCData_lib( Rod )


proc format;
  value miss
    0-high = 'Not missing'
    other = 'Missing';

proc freq data=Rod.Foreclosures_history;
  tables outcome_date * post_sale_date / list missing;
  tables firstnotice_date * lastnotice_date / list missing;
  format outcome_date post_sale_date firstnotice_date lastnotice_date miss.;

run;
