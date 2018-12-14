/**************************************************************************
 Program:  Permits.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  11/27/07
 Version:  SAS 9.1
 Environment:  Windows
 
 Description:  Summarize new building permit data.

 Modifications:
**************************************************************************/

%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";

** Define libraries **;
%DCData_lib( HsngMon )
%DCData_lib( Bpermits )

proc print data=Bpermits.Bpermits_2006 n='Permits = ';
  where put( issued_date, qtr. ) = '1' and permit_type = 'NEW BUILDING' and use in ( 'SFD' );
  id permit_no;
  var issued_date permit_type use units full_addr;
  sum units;
run;


proc print data=Bpermits.Bpermits_2006 n='Permits = ';
  where put( issued_date, qtr. ) = '1' and permit_type = 'NEW BUILDING' and use in ( 'MFD' );
  id permit_no;
  var issued_date permit_type use units full_addr;
  sum units;
run;



proc print data=Bpermits.Bpermits_2007 n='Permits = ';
  where put( issued_date, qtr. ) = '1' and permit_type = 'NEW BUILDING' and use in ( 'SFD' );
  id permit_no;
  var issued_date permit_type use units full_addr;
  sum units;
run;


proc print data=Bpermits.Bpermits_2007 n='Permits = ';
  where put( issued_date, qtr. ) = '1' and permit_type = 'NEW BUILDING' and use in ( 'MFD' );
  id permit_no;
  var issued_date permit_type use units full_addr;
  sum units;
run;


proc means data=Bpermits.Bpermits_2006 n sum;
  where permit_type = 'NEW BUILDING' and use in ( 'SFD', 'MFD' );
  var units;
  
