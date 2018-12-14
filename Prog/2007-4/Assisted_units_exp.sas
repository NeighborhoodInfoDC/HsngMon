/**************************************************************************
 Program:  Assisted_units_exp.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  12/05/07
 Version:  SAS 9.1
 Environment:  Windows
 
 Description:  Table with assisted housing units by year of subsidy
expiration.

 Modifications:
**************************************************************************/

%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";
***%include "C:\DCData\SAS\Inc\Stdhead.sas";

** Define libraries **;
%DCData_lib( HsngMon )

proc format;
  value ProgCat (notsorted)
    1 = 'Public Housing only'
    2 = 'Section 8 only'
    9 = 'Section 8 and other subsidies'
    3 = 'LIHTC only'
    4 = 'HOME only'
    5 = 'CDBG only'
    6 = 'HPTF only'
    /*7 = 'Other single subsidy'*/
    8 = 'LIHTC and Tax Exempt Bond only'
    7, 10 = 'All other combinations';
  value poa_end
    '01jan2000'd -< '01jan2008'd = '2007 or earlier'
    '01jan2008'd -< '01jan2009'd = '2008'
    '01jan2009'd -< '01jan2010'd = '2009'
    '01jan2010'd -< '01jan2011'd = '2010'
    '01jan2011'd -< '01jan2016'd = '2011-2015'
    '01jan2016'd -< '01jan2021'd = '2016-2020'
    '01jan2021'd -< '01jan2031'd = '2021-2030'
    '01jan2031'd - high = '2031 or later';

options missing='0';

ods rtf file="&_dcdata_path\HsngMon\Prog\2007-4\Assisted_units_exp.rtf" style=Styles.Rtf_arial_9pt;

proc tabulate data=HsngMon.Assisted_units format=comma10. noseps missing;
  where ProgCat ~= . and poa_end_max > 0;
  class ProgCat / preloadfmt order=data;
  class poa_end_max;
  var mid_asst_units err_asst_units;
  table 
    /** Rows **/
    all='\b Total' ProgCat=' ',
    /** Columns **/
    sum='Assisted Units' * all=' ' * ( mid_asst_units='Est.' err_asst_units='+/-' )
    sum='Assisted Units by Expiration of Affordability' * poa_end_max=' ' * ( mid_asst_units='Est.' err_asst_units='+/-' )
    ;
  format ProgCat ProgCat. poa_end_max poa_end.;
  
run;

ods rtf close;
  

run;
