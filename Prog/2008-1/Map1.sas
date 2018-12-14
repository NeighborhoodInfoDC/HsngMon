/**************************************************************************
 Program:  Map1.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  02/25/08
 Version:  SAS 9.1
 Environment:  Windows
 
 Description:  Create output data set for mapping assisted units.

 Modifications:
**************************************************************************/

%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";

** Define libraries **;
%DCData_lib( HsngMon )

proc format;
  value RProgCat (notsorted)
    1 = '01Public Housing only'
    2 = '02Section 8 only'
    9 = '03Section 8 and other subsidies'
    3 = '04LIHTC only'
    8 = '05LIHTC and Tax Exempt Bond only'
    4 = '06HOME only'
    5 = '07CDBG only'
    6 = '08HPTF only'
    other = '09All other combinations';

data HsngMon.Map1_2008_1 (compress=no);

  set HsngMon.Assisted_units;
  
  length MapProgCat $ 40;
  
  MapProgCat = put( ProgCat, RProgCat. );

run;

proc freq data=HsngMon.Map1_2008_1;
  tables MapProgCat;
  
run;
