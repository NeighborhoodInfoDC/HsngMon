/**************************************************************************
 Program:  Temp2.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  10/26/06
 Version:  SAS 8.2
 Environment:  Windows
 
 Description:

 Modifications:
**************************************************************************/

%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";

** Define libraries **;
%DCData_lib( HsngMon )
%DCData_lib( RealProp )

proc format;
  picture acres (round)
    low-high = '0,000,009.9' (mult=2.29568411e-5);
  value $proptyp
    '10' = 'Single-Family Residential'
    '11', '12', '13' = 'Multifamily Residential'
    other = 'Non-residential';
  value $owncat (notsorted)
    '010' = 'Private owner-occupied'
    '030' = 'Other individuals'
    '020' = 'Condominiums & coops'
    '080' = 'Community development corporations'
    '040' = 'DC government'
    '050' = 'Federal government'
    '100' = 'Churches, synagogues, temples'
    '110' = 'Corporations, partnerships, associations'
    '111' = 'Nontaxable corporations, partnerships, associations'
    '115' = 'Taxable corporations, partnerships, associations'
    '090' = 'Universities, colleges'
    '070' = 'Quasi-public entities'
    /*'060' = 'Foreign governments'*/
    other = 'Other';
  value ownerdc (notsorted)
    1 = 'D.C.-based'
    0 = 'Non-D.C.';

run;

proc freq data=HsngMon.Who_owns_2006_09;
  *where OwnerCat = '030' and ui_proptype not =: '1';
  where OwnerCat = '111' /*and ui_proptype not =: '1'*/;
  tables ui_proptype ownername;
run;

/*
proc print data=HsngMon.Who_owns_2006_09 (obs=1000);
  where OwnerCat = '030' and ui_proptype not =: '1';
  id ssl;
  var premiseadd ownername ui_proptype;
run;

