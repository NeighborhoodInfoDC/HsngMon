/**************************************************************************
 Program:  Who_owns_2001_10.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  10/24/06
 Version:  SAS 8.2
 Environment:  Windows with SAS/Connect
 
 Description:  Test ownership categories for Housing Monitor Who Owns
 the Neighborhood focus section.
 
 This Excel workbook must be open before running program:
 D:\Dcdata\Libraries\HsngMon\Prog\2006-4\Owner type codes & reg expr.xls

 Modifications:
  10/30/06  Set LANDAREA to missing if not > 0.  Added TOTAL var.
            All condos & coops in OwnCat=20.
            All OwnCat= -> OwnerDC=1.
**************************************************************************/

%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";
%include "K:\Metro\PTatian\DCData\SAS\Inc\AlphaSignon.sas" /nosource2;

** Define libraries **;
%DCData_lib( HsngMon )
%DCData_lib( RealProp )

%let data       = Ownerpt_2001_10a;
%let RegExpFile = Owner type codes & reg expr.xls;
%let MaxExp     = 100;
%let keep_vars  = assess_val class_type tax_rate usecode amttax landarea;

%syslput MaxExp=&MaxExp;
%syslput keep_vars=&keep_vars;
%syslput data=&data;

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

run;

** Upload regular expressions **;

rsubmit;

proc upload status=no
  data=RegExp 
  out=RegExp (compress=no);

run;

endrsubmit;

** Separate out data for owner assignment **;

rsubmit;

data sf_condo_dc (compress=no)
     other       (compress=no);
     
  set RealProp.&data 
   (keep=ssl ownername ui_proptype premiseadd address1 address2 address3 hstd_code &keep_vars);
   
  if not( landarea > 0 ) then landarea = .u;
  
  retain Total 1;
  
  length OwnerDC 3;
   
  if address3 ~= '' then do;
    if indexw( address3, 'DC' ) then OwnerDC = 1;
    else OwnerDC = 0;
  end;
  else OwnerDC = 9;
     
  if address2 = '' then address2 = address1;
  
  if ui_proptype in ( '10', '11' ) and OwnerDC then output sf_condo_dc;
  else output other;
  
  label
    Total = 'Total'
    OwnerDC = 'DC-based owner';
  
  drop address1;

run;

endrsubmit;

** Standardize addresses for SF & condo units **;

rsubmit;

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

** Determine owner-occupied SF and condo units **;

rsubmit;

data sf_condo_dc_10 (compress=no) 
     sf_condo_dc_un (compress=no);

  merge
    premiseadd_std
    address2_std (keep=ssl address2_std);
  by ssl;
  
  length OwnCat $ 3;

  if OwnerDC and
    ( premiseadd_std = address2_std or hstd_code in ( '1', '5' ) ) then 
      OwnCat = '010';
      
  if OwnCat = '010' then output sf_condo_dc_10;
  else output sf_condo_dc_un;

run;

endrsubmit;

** Match regular expressions against owner data file **;

rsubmit;

data other_coded (compress=no);

  set sf_condo_dc_un other;
  by ssl;

  ownername = left( compbl( compress( upcase( ownername ), "." ) ) );

  length Owncat1-Owncat&MaxExp $ 3;
  retain Owncat1-Owncat&MaxExp re1-re&MaxExp num_rexp;

  array a_Owncat{*} $ Owncat1-Owncat&MaxExp;
  array a_re{*}     re1-re&MaxExp;
  
  ** Load & parse regular expressions **;

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

    *put num_rexp= a_re{1}= a_re{2}=;

  end;

  i = 1;
  match = 0;

  do while ( i <= num_rexp and not match );
    if prxmatch( a_re{i}, ownername ) then do;
      Owncat = a_Owncat{i};
      ownername = propcase( ownername );
      match = 1;
    end;
    i = i + 1;
  end;
  
  if ui_proptype = '12' and OwnCat not in ( '040', '050', '060', '070', '080', '090', '100' )
  then OwnCat = '020';
  else if OwnCat = '' then OwnCat = '030';
  
  drop i match num_rexp regexp Owncat1-Owncat&MaxExp re1-re&MaxExp;

run;

endrsubmit;

/*
proc freq data=Test;
  tables Owncat * ownername / nocum nopercent list missing;

run;

proc sort data=Test out=Test (compress=no);
  by Owncat;
run;
*/

** Recombine and download final file **;

rsubmit;

data Who_owns_2001_10 (compress=no);

  set sf_condo_dc_10 other_coded;
  by ssl;
  
  ** Assume OwnerDC=1 for government & quasi-gov. owners **;
  
  if OwnCat in ( '040', '050', '060', '070' ) then OwnerDC = 1;
  
  ** All condos in OwnCat = 20 **;
  
  if ui_proptype = '11' and OwnCat not in ( '040', '050', '060', '070', '080', '090', '100' )
  then OwnCat = '020';
      
run;

proc download status=no
  data=Who_owns_2001_10 
  out=HsngMon.Who_owns_2001_10 (label="Who owns the neighborhood analysis file, source &data");

run;

endrsubmit;

%File_info( data=HsngMon.Who_owns_2001_10, printobs=5 )

proc format;
  picture acres (round)
    low-high = '000,009.99' (mult=2.29568411e-3);
  picture thous (round)
    low-high = '0,000,009.9' (mult=0.01);
  value $proptyp
    '10' = 'Single-Family Residential'
    '11', '12', '13' = 'Multifamily Residential'
    other = 'Non-residential';
  value $owncat
    '010' = 'Single-family owner-occupied'
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

proc freq data=HsngMon.Who_owns_2001_10;
  tables OwnCat OwnerDC;
  format OwnCat $owncat.;
run;

** Missing land area **;

proc tabulate data=HsngMon.Who_owns_2001_10 format=comma8.0 noseps missing;
  class ui_proptype owncat /order=data preloadfmt;
  var total landarea;
  table 
    ui_proptype=' ' * owncat=' ',
    total=' ' * sum='Total'
    landarea = 'Land area' * ( n='Nonmissing' nmiss='Missing' )
    /indent=3 rts=45;
  format ui_proptype $proptyp. owncat $owncat.;
  title2 'Missing land area';

run;

** List owner names for selected owner types **;

options nodate nonumber;

%fdate()

ods rtf file="&_dcdata_path\HsngMon\Prog\2006-4\Who_owns_2001_10.rtf" style=Styles.Rtf_arial_9pt;

proc tabulate data=HsngMon.Who_owns_2001_10 format=comma8.0 noseps missing;
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
  title2 "Real property ownership, 2001";
  footnote1 height=9pt j=l "Source: &data / revised: &fdate";
  footnote2 height=9pt j=r '{Page}\~{\field{\*\fldinst{\pard\b\i0\chcbpat8\qc\f1\fs19\cf1{PAGE }\cf0\chcbpat0}}}';

run;

ods rtf close;

options date number;

signoff;
