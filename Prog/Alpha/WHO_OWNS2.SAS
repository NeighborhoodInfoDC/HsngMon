/**************************************************************************
 Program:  Who_owns.sas
 Library:  RealProp
 Project:  DC Data Warehouse
 Author:   P. Tatian
 Created:  10/23/06
 Version:  SAS 9.1
 Environment:  Alpha
 
 Description:  List of owners for Who Owns the Neighborhood analysis.

 Modifications:
**************************************************************************/

%include "[Dcdata]Stdhead.sas";

** Define libraries **;
%DCData_lib( HsngMon )
%DCData_lib( RealProp )

options obs=1000;

data sf_condo (compress=no);

  set RealProp.Ownerpt_2006_09 (keep=ssl ui_proptype premiseadd address1 address2 address3);
  where ui_proptype in ( '10', '11' ) and indexw( address3, 'DC' );

  if address2 = '' then address2 = address1;

  keep ssl ui_proptype premiseadd address2;
  
run;

options obs=max;

%DC_geocode(
  data=sf_condo,
  out=premise_geo,
  staddr=premiseadd,
  id=ssl,
  ds_label=,
  keep_geo=,
  geo_match=N,
  block_match=N,
  listunmatched=N
)

proc print data=premise_geo (obs=20);

%DC_geocode(
  data=sf_condo,
  out=address2_geo,
  staddr=address2,
  id=ssl,
  ds_label=,
  keep_geo=,
  geo_match=N,
  block_match=N,
  listunmatched=N
)

proc print data=address2_geo (obs=20);

run;


