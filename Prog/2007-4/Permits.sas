/**************************************************************************
 Program:  Permits.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  11/27/07
 Version:  SAS 9.1
 Environment:  Windows
 
 Description:  Summarize new building permit data.
 First two quarters of 2006 & 2007.

 Modifications:
**************************************************************************/

%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";

** Define libraries **;
%DCData_lib( HsngMon )
%DCData_lib( Bpermits )

proc print data=Bpermits.Bpermits_2006 n='Permits = ';
  where put( issued_date, qtr. ) in ( '1', '2' ) and permit_type = 'NEW BUILDING' and use in ( 'SFD' );
  id permit_no;
  var issued_date permit_type use units full_addr;
  sum units;
  title2 'Single-Family, 2006';
run;


proc print data=Bpermits.Bpermits_2006 n='Permits = ';
  where put( issued_date, qtr. ) in ( '1', '2' ) and permit_type = 'NEW BUILDING' and use in ( 'MFD' );
  id permit_no;
  var issued_date permit_type use units full_addr;
  sum units;
  title2 'Multifamily, 2006';
run;



proc print data=Bpermits.Bpermits_2007 n='Permits = ';
  where put( issued_date, qtr. ) in ( '1', '2' ) and permit_type = 'NEW BUILDING' and use in ( 'SFD' );
  id permit_no;
  var issued_date permit_type use units full_addr;
  sum units;
  title2 'Single-Family, 2007';
run;


proc print data=Bpermits.Bpermits_2007 n='Permits = ';
  where put( issued_date, qtr. ) in ( '1', '2' ) and permit_type = 'NEW BUILDING' and use in ( 'MFD' );
  id permit_no;
  var issued_date permit_type use units full_addr;
  sum units;
  title2 'Multifamily, 2007';
run;

title2;

proc means data=Bpermits.Bpermits_2006 n sum;
  where permit_type = 'NEW BUILDING' and use in ( 'SFD', 'MFD' );
  var units;
  

proc tabulate data=Bpermits.Bpermits_2007 format=comma8.0 noseps missing;
  where put( issued_date, qtr. ) in ( '1', '2' ) and permit_type = 'NEW BUILDING' and use in ( 'SFD', 'MFD' );
  class ward use;
  var units;
  table 
    /** Rows **/
    all='DC'
    ward='Ward'
    ,
    /** Columns **/
    n='Permits'
    units='Units' * sum=' ' * ( all='Total' use )
    units='% Units' * colpctsum=' ' * ( all='Total' use )
    ;
run;
