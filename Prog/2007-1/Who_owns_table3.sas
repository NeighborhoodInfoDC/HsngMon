/**************************************************************************
 Program:  Who_owns_table3.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  11/02/06
 Version:  SAS 8.2
 Environment:  Windows
 
 Description:  Who Owns the Neighborhood table.

 Modifications:
**************************************************************************/

%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";

** Define libraries **;
%DCData_lib( HsngMon )

proc format;
  picture acres (round)
    low-high = '0,000,009.9' (mult=2.29568411e-4);
  value $proptyp
    '10', '11', '12', '13' = 'Residential'
    other = 'Nonresid.';
  value $OwnCatA (notsorted)
    '010','020' = '\i Owner-occupied'
    '030' = '\i Other individuals'
    '050','040','070' = '\i Government'
    '080','110','111','115' = '\i For profit/nonprofit'
    '100','090','060' = '\i Other';
  value $OwnCatB (notsorted)
    '010' = 'Single-family'
    '020' = 'Multifamily'
    '030' = 'Other individuals'
    '050' = 'Federal government'
    '040' = 'DC government'
    '070' = 'Quasi-public entities'
    '080' = 'Community development corporations'
    '110' = 'Other corp., partnerships, assoc.'
    '111' = 'Other nontaxable'
    '115' = 'Taxable'
    '100' = 'Churches, synagogues, religious'
    '090' = 'Private universities, colleges, schools'
    '060' = 'Foreign governments';
  value ownerdc (notsorted)
    1,9 = 'DC-based'
    0 = 'Non-DC';

run;



options nodate nonumber missing='-';

%fdate()

ods rtf file="&_dcdata_path\HsngMon\Prog\2006-4\Who_owns_table3.rtf" style=Styles.Rtf_arial_9pt;

proc tabulate data=HsngMon.Who_owns_2006_09 format=comma10.0 noseps missing;
  class ui_proptype OwnerCat OwnerCat_2 /order=data preloadfmt;
  var total landarea;
  table 
    /** Rows **/
    all='\b Total for all owners' OwnerCat * ( all=' ' OwnerCat_2 ),
    /** Columns **/
    total='Parcels' * sum=' ' * ( all='Total' ui_proptype=' ' )
    landarea='Acres' * sum=' ' * ( all='Total' ui_proptype=' ' ) * f=acres.
    /indent=3 rts=45 box='\ql Owner type';
  table 
    /** Rows **/
    all='\b Total for all owners' OwnerCat * ( all=' ' OwnerCat_2 ),
    /** Columns **/
    total='Pct. Parcels' * colpctsum=' ' * ( all='Total' ui_proptype=' ' ) * f=10.1
    landarea='Pct. Acres' * colpctsum=' ' * ( all='Total' ui_proptype=' ' ) * f=10.1
    /indent=3 rts=45 box='\ql Owner type';
  format ui_proptype $proptyp. OwnerCat $OwnCatA. OwnerCat_2 $OwnCatB.;
  title2 "Real property ownership, Washington, DC, 2006";
  footnote1 height=9pt j=l "DRAFT - NOT FOR CIRCULATION OR CITATION (Revised &fdate)";
  footnote2 height=9pt j=r '{Page}\~{\field{\*\fldinst{\pard\b\i0\chcbpat8\qc\f1\fs19\cf1{PAGE }\cf0\chcbpat0}}}';
  
run;

ods rtf close;

options date number;

run;
