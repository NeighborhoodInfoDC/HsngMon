/**************************************************************************
 Program:  Who_owns_table4.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  11/02/06
 Version:  SAS 8.2
 Environment:  Windows
 
 Description:  Create Who Owns the Neighborhood table.

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
    other = 'Non-resid.';
  value $OwnCatA (notsorted)
    '010','020' = 'Owner- occ.'
    '030' = 'Other indiv.'
    '050','040','070' = 'Govern- ment'
    '080','111' = 'Non- taxable'
    '115' = 'Taxable'
    /*'080','110' = 'Profit/ Nonprofit'*/
    '100','090','060' = 'Other';
  value $ward (notsorted)
    '1' = '\b Ward 1'
    '2' = '\b Ward 2'
    '3' = '\b Ward 3'
    '4' = '\b Ward 4'
    '5' = '\b Ward 5'
    '6' = '\b Ward 6'
    '7' = '\b Ward 7'
    '8' = '\b Ward 8'
    ' ' = ' ';

run;


data Table4;
  set HsngMon.Who_owns_2006_09 
    (keep=ssl cluster_tr2000_mod cl_ward2002 ui_proptype OwnerCat ownerdc 
          landarea landarea_res landarea_non total);

  ** Temporary reclassification of parcel **;
  
  if ssl = 'PAR 00790049' then do;
    cluster_tr2000_mod = '99';
    cl_ward2002 = ' ';
  end;

run;


** Print sample table **;

options nodate nonumber missing='-' orientation=landscape;

%fdate()

ods rtf file="&_dcdata_path\HsngMon\Prog\2006-4\Who_owns_table4.rtf" style=Styles.Rtf_arial_9pt;

proc tabulate data=Table4 /*HsngMon.Who_owns_2006_09*/ format=comma10.0 noseps missing;
  class ui_proptype OwnerCat cl_ward2002 /order=data preloadfmt;
  class cluster_tr2000_mod;
  var total landarea_res landarea_non;
  table 
    /** Rows **/
    all='\b Washington, DC total'
    ( cl_ward2002='\~' ) * ( all=' ' cluster_tr2000_mod ),
    /** Columns **/
    landarea_res='Residential' * (
      sum=' '*f=acres.*all='Total acres'
      rowpctsum='Pct. by owner type'*f=comma5.1
      * ( all='All owners' OwnerCat=' ' ) 
    )
    landarea_non='Non-residential' * (
      sum=' '*f=acres.*all='Total acres'
      rowpctsum='Pct. by owner type'*f=comma5.1
      * ( all='All owners' OwnerCat=' ' ) 
    )
    /indent=3 rts=20 box=' ';
  format ownerdc ownerdc. landarea acres. ui_proptype $proptyp. OwnerCat $owncatA.
   cluster_tr2000_mod $clus00a. cl_ward2002 $ward.;
  title2 "Real property ownership, Washington, DC, 2006";
  footnote1 height=9pt j=l "DRAFT - NOT FOR CIRCULATION OR CITATION (Revised &fdate)";
  footnote2 height=9pt j=r '{Page}\~{\field{\*\fldinst{\pard\b\i0\chcbpat8\qc\f1\fs19\cf1{PAGE }\cf0\chcbpat0}}}';
  
run;

ods rtf close;

options date number;


