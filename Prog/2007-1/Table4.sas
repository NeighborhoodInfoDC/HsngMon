/**************************************************************************
 Program:  Table4.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  11/26/06
 Version:  SAS 8.2
 Environment:  Windows
 
 Description:  Create Housing Monitor, Winter 06/07, Table 4
 Real property ownership by owner type and ward/cluster.

 Modifications:
**************************************************************************/

%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";
***%include "C:\DCData\SAS\Inc\Stdhead.sas";

** Define libraries **;
%DCData_lib( HsngMon )

%let path = &_dcdata_path\HsngMon\Prog\2006-4;
%let workbook = DC Housing Monitor Winter 2006 tables.xls;
%let sheet = Table 4;
%let first_row = 11;

proc format;
  picture acres (round)
    low-high = '0000009.9' (mult=2.29568411e-4);
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
    '1' = 'Ward 1'
    '2' = 'Ward 2'
    '3' = 'Ward 3'
    '4' = 'Ward 4'
    '5' = 'Ward 5'
    '6' = 'Ward 6'
    '7' = 'Ward 7'
    '8' = 'Ward 8'
    '9' = 'Noncluster area';

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
  
  if cluster_tr2000_mod = '99' then cl_ward2002 = '9';

run;


** Print sample table **;

options nodate nonumber missing='-' orientation=landscape;

%fdate()

ods output table=Table4out;

proc tabulate data=Table4 /*HsngMon.Who_owns_2006_09*/ format=comma10.0 noseps missing;
  class ui_proptype OwnerCat /order=data preloadfmt;
  class cl_ward2002 cluster_tr2000_mod;
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
   cluster_tr2000_mod $2. cl_ward2002 $1.;
  title2 "Real property ownership, Washington, DC, 2006";
  footnote1 height=9pt j=l "DRAFT - NOT FOR CIRCULATION OR CITATION (Revised &fdate)";
  footnote2 height=9pt j=r '{Page}\~{\field{\*\fldinst{\pard\b\i0\chcbpat8\qc\f1\fs19\cf1{PAGE }\cf0\chcbpat0}}}';
  
run;

ods output close;

options date number;

data Table4out;
  set Table4out (drop=_page_ _table_);
  n = _n_;
run;

proc sort data=Table4out;
  by cl_ward2002 cluster_tr2000_mod n;

%File_info( data=Table4out, printobs=100, stats= )

*endsas;

filename xout dde "excel|&path\[&workbook]&sheet!r&first_row.c1:r%eval(&first_row+59)c19" lrecl=512 notab;

data _null_;

  set Table4out (obs=1000000);
  
  col = mod( _n_, 14 );
  
  landarea = max( landarea_res_sum, landarea_non_sum );
  landarea_pct = max( landarea_res_PctSum_000, landarea_res_PctSum_010, landarea_res_PctSum_011, 
                      landarea_non_PctSum_000, landarea_non_PctSum_010, landarea_non_PctSum_011 );

  file xout;
  
  if _n_ = 1 then do;
    put 'Washington, D.C. Total' '09'x '09'x '09'x '09'x @;
  end;
  else if col = 1 then do;
    if cluster_tr2000_mod = '' then put / cl_ward2002 $ward. '09'x '09'x '09'x '09'x @;
    else if cluster_tr2000_mod ~= '99' then put '09'x cluster_tr2000_mod '09'x '09'x cluster_tr2000_mod $clus00s. '09'x @;
    else if cluster_tr2000_mod = '99' then stop;
  end;
  
  select ( col );
    when ( 1 ) put landarea acres. '09'x landarea_Pct '09'x @;
    when ( 2, 3, 4, 5, 6, 7 ) put landarea_Pct '09'x @;
    when ( 8 ) put landarea acres. '09'x landarea_Pct '09'x @;
    when ( 10, 11, 12, 13 ) put landarea_Pct '09'x @;
    when ( 0 ) put landarea_Pct;
    otherwise /* nothing */;
  end;

  %macro skip;
  select ( col );
    when ( 1 ) put landarea_res_Sum acres. '09'x landarea_res_PctSum_000 '09'x @;
    when ( 2, 3, 4, 5, 6, 7 ) put landarea_res_PctSum_000 '09'x @;
    when ( 8 ) put landarea_non_Sum acres. '09'x landarea_non_PctSum_000 '09'x @;
    when ( 10, 11, 12, 13 ) put landarea_non_PctSum_000 '09'x @;
    when ( 0 ) put landarea_non_PctSum_000;
    otherwise /* nothing */;
  end;
  %mend skip;
  
run;

