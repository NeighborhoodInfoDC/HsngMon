/**************************************************************************
 Program:  Who_owns_test.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  10/24/06
 Version:  SAS 8.2
 Environment:  Windows with SAS/Connect
 
 Description:  Test ownership categories for Housing Monitor Who Owns
 the Neighborhood focus section.

 Modifications:
**************************************************************************/

%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";
%include "K:\Metro\PTatian\DCData\SAS\Inc\AlphaSignon.sas" /nosource2;

** Define libraries **;
%DCData_lib( HsngMon )
%DCData_lib( RealProp )

%let RegExpFile = Owner type codes & reg expr.xls;
%let MaxExp     = 100;
%let keep_vars  = assess_val class_type_3d tax_rate usecode amttax landarea;

%syslput MaxExp=&MaxExp;
%syslput keep_vars=&keep_vars;

** Read in regular expressions **;

filename xlsfile dde "excel|&_dcdata_path\HsngMon\Prog\2006-4\[&RegExpFile]Sheet1!r2c1:r&MaxExp.c2" lrecl=256 notab;

data RegExp (compress=no);

  length Owncat $ 3 RegExp $ 1000;
  
  infile xlsfile missover dsd dlm='09'x;

  input Owncat RegExp;
  
  if RegExp = '' then delete;
  
  Owncat = put( 1 * Owncat, z3. );

run;

proc print data=RegExp;

** Upload regular expressions **;

rsubmit;

proc upload status=no
  data=RegExp 
  out=RegExp (compress=no);

run;

endrsubmit;

%macro skip;

** Separate out data for owner assignment **;

rsubmit;

data sf_condo_dc (compress=no)
     other       (compress=no);
     
  set RealProp.Ownerpt_2006_09 
   (keep=ssl ui_proptype premiseadd address1 address2 address3 &keep_vars);
   
  length OwnerDC 3;
   
  if indexw( address3, 'DC' ) then OwnerDC = 1;
  else OwnerDC = 0;
     
  if ui_proptype in ( '10', '11' ) and OwnerDC then output sf_condo_dc;
  else output other;
  
  if address2 = '' then address2 = address1;
  
  drop address1 address3;

run;

** Determine owner-occupied SF and condo units **;

** Standardize addresses **;

%DC_geocode(
  data=sf_condo_dc,
  out=premiseadd_std,
  staddr=premiseadd,
  id=ssl,
  ds_label=,
  keep_geo=,
  geo_match=N,
  block_match=N,
  listunmatched=N
)

%DC_geocode(
  data=sf_condo_dc,
  out=address2_std,
  staddr=address2,
  id=ssl,
  ds_label=,
  keep_geo=,
  geo_match=N,
  block_match=N,
  listunmatched=N
)

run;

endrsubmit;

%mend skip;

** Match regular expressions against owner data file **;

rsubmit;

data Test (compress=no);

  set RealProp.Ownerpt_2006_09 (keep=ssl ownername ui_proptype premiseadd address1 address2 address3 &keep_vars);
  
  if not( landarea > 0 ) then landarea = .u;

  ownername = left( compbl( compress( upcase( ownername ), "." ) ) );

  length Owncat1-Owncat&MaxExp $ 3;
  retain Owncat1-Owncat&MaxExp re1-re&MaxExp num_rexp;

  array a_Owncat{*} $ Owncat1-Owncat&MaxExp;
  array a_re{*}     re1-re&MaxExp;

  if _n_ = 1 then do;

    i = 1;

    do until ( eof );
      set RegExp end=eof;
      a_Owncat{i} = Owncat;
      a_re{i} = prxparse( regexp );
      if missing( a_re{i} ) then do;
        putlog "Error" regexp=;
        stop;
      end;
      i = i + 1;
    end;

    num_rexp = i - 1;

    put num_rexp= a_re{1}= a_re{2}=;

  end;

  i = 1;
  match = 0;

  do while ( i <= num_rexp and not match );
    if prxmatch( a_re{i}, ownername ) then do;
      Owncat = a_Owncat{i};
      ownername = propcase( ownername );
      match = 1;
      output;
    end;
    i = i + 1;
  end;

  keep Owncat ssl ownername ui_proptype premiseadd address1 address2 address3 &keep_vars;

run;

/*
proc freq data=Test;
  tables Owncat * ownername / nocum nopercent list missing;

run;

proc sort data=Test out=Test (compress=no);
  by Owncat;
run;
*/

proc download status=no
  data=Test 
  out=HsngMon.Test;

run;

endrsubmit;

proc format;
  picture acres (round)
    low-high = '000,009.99' (mult=2.29568411e-3);
  picture thous (round)
    low-high = '0,000,009.9' (mult=0.01);
  value $owncat
    '010' = 'Private owner-occupied'
    '020' = 'Condominiums and coops'
    '030' = 'Other individuals'
    '040' = 'DC government'
    '050' = 'US government'
    '060' = 'Foreign governments'
    '070' = 'Quasi-public entities'
    '080' = 'Community development corporations/organizations'
    '090' = 'Private universities, colleges, schools'
    '100' = 'Churches, synagogues, temples'
    '110' = 'Corporations, partnership, LLCs, LLPs, associations';

run;

proc freq data=HsngMon.Test;
  tables owncat / missing;
  format owncat $owncat.;
run;

options nodate nonumber;

%fdate()

ods rtf file="&_dcdata_path\HsngMon\Prog\2006-4\Who_owns_test.rtf" style=Styles.Rtf_arial_9pt;

proc tabulate data=HsngMon.Test format=comma8.0 noseps missing;
  where OwnCat in ( '040', '050', '070', '080', '090', '100' );
  class OwnCat Ownername;
  var landarea;
  table
    OwnCat='Owner category = ',
    Ownername=' ' all='\b TOTAL',
    n='Number of parcels'
    landarea='Land area' * ( sum='Sq.\~feet (000s)'*f=thous. sum='Acres'*f=acres. )
    / box='Owner name' rts=60;
  format OwnCat $owncat. ;
  title2 "Real property ownership, 2006";
  footnote1 height=9pt j=l "Revised &fdate";
  footnote2 height=9pt j=r '{Page}\~{\field{\*\fldinst{\pard\b\i0\chcbpat8\qc\f1\fs19\cf1{PAGE }\cf0\chcbpat0}}}';

run;

ods rtf close;

options date number;

signoff;
