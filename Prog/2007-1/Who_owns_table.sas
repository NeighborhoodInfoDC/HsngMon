/**************************************************************************
 Program:  Who_owns_table.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  10/27/06
 Version:  SAS 8.2
 Environment:  Windows
 
 Description:  Create Who Owns the Neighborhood analysis table 1.

 Modifications:
**************************************************************************/

%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";
***%include "C:\DCData\SAS\Inc\Stdhead.sas";

** Define libraries **;
%DCData_lib( HsngMon )

proc format;
  picture acres (round)
    low-high = '0,000,009.9' (mult=2.29568411e-4);
  value $proptyp
    '10' = '\b Single-Family Residential'
    '11', '12', '13' = '\b Multifamily Residential'
    other = '\b Non-residential';
  value $OwnCat (notsorted)
    '010','020' = 'Owner-occupied'
    '030' = 'Other individuals'
    '050' = 'Federal government'
    '040' = 'DC government'
    '070' = 'Quasi-public entities'
    '080' = 'Community development corporations'
    '110' = 'Corporations, partnerships, associations'
    '111' = 'Nontaxable corporations, partnerships, associations'
    '115' = 'Taxable corporations, partnerships, associations'
    '100' = 'Churches, synagogues, religious'
    '090' = 'Private universities, colleges, schools'
    '060' = 'Foreign governments';
  value ownerdc (notsorted)
    1,9 = 'DC-based'
    0 = 'Non-DC';

run;

** Print sample table **;

options nodate nonumber missing='-';

%fdate()

ods rtf file="&_dcdata_path\HsngMon\Prog\2006-4\Who_owns_table.rtf" style=Styles.Rtf_arial_9pt;

proc tabulate data=HsngMon.Who_owns_2006_09 format=comma10.0 noseps missing;
  class ui_proptype OwnerCat ownerdc /order=data preloadfmt;
  var landarea;
  table 
    ( all='\b Total' OwnerCat ),
    (
      n = 'Number of parcels' 
      sum=' '*landarea='Number of acres'*f=acres.
    ) * ( all='All owners' ownerdc=' ' )
    /indent=3 rts=45 box='\ql Owner type';
  table 
    ui_proptype * ( all='\b Total' OwnerCat ),
    (
      n = 'Number of parcels' 
      sum=' '*landarea='Number of acres'*f=acres.
    ) * ( all='All owners' ownerdc=' ' )
    /indent=3 rts=45 box='\ql Property & owner type';
  format ownerdc ownerdc. landarea acres. ui_proptype $proptyp. OwnerCat $OwnCat.;
  title2 "Real property ownership, Washington, DC, 2006";
  footnote1 height=9pt j=l "DRAFT - NOT FOR CIRCULATION OR CITATION (Revised &fdate)";
  footnote2 height=9pt j=r '{Page}\~{\field{\*\fldinst{\pard\b\i0\chcbpat8\qc\f1\fs19\cf1{PAGE }\cf0\chcbpat0}}}';
  
run;

ods rtf close;

options date number;

