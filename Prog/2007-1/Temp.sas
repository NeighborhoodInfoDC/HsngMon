/**************************************************************************
 Program:  Temp.sas
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
    '090' = 'Universities, colleges'
    '070' = 'Quasi-public entities'
    /*'060' = 'Foreign governments'*/
    other = 'Other';
  value ownerdc (notsorted)
    1 = 'D.C.-based'
    0 = 'Non-D.C.';

run;

data TempA;

  set HsngMon.Who_owns_2006_09 (keep=ui_proptype owncat landarea);
  
  if not( landarea > 0 ) then landarea = .u;
  
  total = 1;
  
run;

proc tabulate data=TempA format=comma8.0 noseps missing;
  class ui_proptype owncat /order=data preloadfmt;
  var total landarea;
  table 
    ui_proptype=' ' * owncat=' ',
    total=' ' * sum='Total'
    landarea = 'Land area' * ( n='Nonmissing' nmiss='Missing' )
    /indent=3 rts=45;
  format ui_proptype $proptyp. owncat $owncat.;

endsas;

data Temp (compress=no);

  set HsngMon.Who_owns_2006_09;
  where ui_proptype = '11' and premiseadd_std ~= '';
  
run;

proc sort data=Temp;
  by premiseadd_std;

proc print data=Temp (obs=200);
  by premiseadd_std;
  id premiseadd_std;
  var premiseadd landarea;

run;
