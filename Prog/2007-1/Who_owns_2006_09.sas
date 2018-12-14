/**************************************************************************
 Program:  Who_owns_2006_09.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  10/24/06
 Version:  SAS 8.2
 Environment:  Windows with SAS/Connect
 
 Description:  Create ownership categories for Housing Monitor Who Owns
 the Neighborhood focus section.
 
 This Excel workbook must be open before running program:
 D:\Dcdata\Libraries\HsngMon\Prog\2006-4\Owner type codes & reg expr.xls

 Modifications:
  10/30/06  Set LANDAREA to missing if not > 0.  Added TOTAL var.
            All condos & coops in OwnerCat=20.
            All OwnerCat= -> OwnerDC=1.
  11/07/06  Added modified cluster var (cluster_tr2000_mod).
**************************************************************************/

%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";
%include "K:\Metro\PTatian\DCData\SAS\Inc\AlphaSignon.sas" /nosource2;

** Define libraries **;
%DCData_lib( HsngMon )
%DCData_lib( RealProp )

%let data       = Ownerpt_2006_09;
%let RegExpFile = Owner type codes & reg expr.xls;
%let MaxExp     = 1000;
%let keep_vars  = assess_val class_type_3d tax_rate usecode amttax mix1txtype landarea;

%syslput MaxExp=&MaxExp;
%syslput keep_vars=&keep_vars;
%syslput data=&data;

** Read in regular expressions **;

filename xlsfile dde "excel|&_dcdata_path\HsngMon\Prog\2006-4\[&RegExpFile]Sheet1!r2c1:r&MaxExp.c2" lrecl=256 notab;

data RegExp (compress=no);

  length OwnerCat $ 3 RegExp $ 1000;
  
  infile xlsfile missover dsd dlm='09'x;

  input OwnerCat RegExp;
  
  if RegExp = '' then stop;
  
  OwnerCat = put( 1 * OwnerCat, z3. );

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

** Separate out data for owner assignment and add geographic identifiers **;

rsubmit;

data sf_condo_dc (compress=no)
     other       (compress=no);
     
  merge
    RealProp.&data 
     (keep=ssl ownername ui_proptype premiseadd address1 address2 address3 hstd_code &keep_vars
      in=inA)
    RealProp.Parcel_geo (drop=cjrtractbl);
  by ssl;
  
  if inA;
   
  ownername = left( compbl( compress( upcase( ownername ), "._" ) ) );

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
  
  length OwnerCat $ 3 OwnerOcc 3;
  
  if premiseadd_std = address2_std or hstd_code in ( '1', '5' ) then
    OwnerOcc = 1;
  else OwnerOcc = 0;

  if OwnerDC and OwnerOcc then OwnerCat = '010';
  
  label 
    OwnerOcc = 'Owner-occupied SF or condo unit'
    OwnerCat = 'Owner type';
      
  if OwnerCat = '010' then output sf_condo_dc_10;
  else output sf_condo_dc_un;

run;

endrsubmit;

** Match regular expressions against owner data file **;

rsubmit;

data other_coded (compress=no);

  set sf_condo_dc_un other;
  by ssl;

  length OwnerCat1-OwnerCat&MaxExp $ 3;
  retain OwnerCat1-OwnerCat&MaxExp re1-re&MaxExp num_rexp;

  array a_OwnerCat{*} $ OwnerCat1-OwnerCat&MaxExp;
  array a_re{*}     re1-re&MaxExp;
  
  ** Load & parse regular expressions **;

  if _n_ = 1 then do;

    i = 1;

    do until ( eof );
      set RegExp end=eof;
      a_OwnerCat{i} = OwnerCat;
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
      OwnerCat = a_OwnerCat{i};
      ownername = propcase( ownername );
      match = 1;
    end;
    i = i + 1;
  end;
  
  ** Cooperatives are owner-occupied (OwnerCat=20), unless special owner **;
  
  if ui_proptype = '12' and OwnerCat not in ( '040', '050', '060', '070', '080', '090', '100' )
  then do;
    OwnerCat = '020';
    OwnerOcc = 1;
  end;
  else if OwnerCat = '' then do;
    OwnerCat = '030';
    OwnerOcc = 0;
  end;
  
  drop i match num_rexp regexp OwnerCat1-OwnerCat&MaxExp re1-re&MaxExp;

run;

endrsubmit;

** Recombine and add geographic identifiers **;

rsubmit;

data Who_owns_2006_09 (compress=no);

  set sf_condo_dc_10 other_coded;
  by ssl;
  
  ** Assume OwnerDC=1 for government & quasi-gov. owners **;
  
  if OwnerCat in ( '040', '050', '060', '070' ) then OwnerDC = 1;
  
  ** All owner-occupied condos in OwnerCat = 20 **;
  
  if ui_proptype = '11' and OwnerOcc then OwnerCat = '020';
  
  ** Separate corporate (110) into for profit & nonprofit by tax status **;
  
  if OwnerCat = '110' then do;
    if mix1txtype = 'TX' then OwnerCat = '115';
    else OwnerCat = '111';
  end;
  
  ** Duplicate OwnerCat variable for tables **;
  
  length OwnerCat_2 $ 3;
  
  OwnerCat_2 = OwnerCat;
  
  label OwnerCat_2 = 'Owner type (duplicate var)';
  
  ** Remove noncluster parcels from tract-based cluster areas **;

  if cluster2000 = '99' then 
    cluster_tr2000_mod = '99';
  else 
    cluster_tr2000_mod = cluster_tr2000;

  ** Duplicate cluster variable for tables **;
  
  cluster_tr2000_mod_2 = cluster_tr2000_mod;
  
  label 
    cluster_tr2000_mod = 'Neighborhood cluster (tract-based, 2000, modified)'
    cluster_tr2000_mod_2 = 'Neighborhood cluster (tract-based, 2000, modified) (duplicate var)';
  
  ** Cluster ward var **;
  
  length cl_ward2002 $ 1;
  
  cl_ward2002 = put( cluster_tr2000_mod, $cl0wd2f. );
  
  label cl_ward2002 = 'Ward (cluster-based)';
  
  ** Residential & non-residential land area for tables **;

  if ui_proptype in ( '10', '11', '12', '13' ) then landarea_res = landarea;
  else landarea_non = landarea;

  ** Recode missing OwnerOcc to 0 **;
  
  if missing( OwnerOcc ) then OwnerOcc = 0;
        
run;

** Download final file **;

proc download status=no
  data=Who_owns_2006_09 
  out=HsngMon.Who_owns_2006_09 (label="Who owns the neighborhood analysis file, source &data");

run;

endrsubmit;

%File_info( data=HsngMon.Who_owns_2006_09, printobs=5, freqvars=mix1txtype )

proc format;
  picture acres (round)
    low-high = '000,009.99' (mult=2.29568411e-3);
  picture thous (round)
    low-high = '0,000,009.9' (mult=0.01);
  value $OwnCat
    '010' = 'Single-family owner-occupied'
    '020' = 'Multifamily owner-occupied'
    '030' = 'Other individuals'
    '040' = 'DC government'
    '050' = 'US government'
    '060' = 'Foreign governments'
    '070' = 'Quasi-public entities'
    '080' = 'Community development corporations/organizations'
    '090' = 'Private universities, colleges, schools'
    '100' = 'Churches, synagogues, religious'
    '110' = 'Corporations, partnership, LLCs, LLPs, associations'
    '111' = 'Nontaxable corporations, partnerships, associations'
    '115' = 'Taxable corporations, partnerships, associations'
    ;

run;

proc freq data=HsngMon.Who_owns_2006_09;
  tables 
    OwnerCat OwnerDC OwnerOcc  
    OwnerCat * ( OwnerDC OwnerOcc )
    / missing list;
  format OwnerCat $OwnCat.;
run;

** List owner names for selected owner types **;

options nodate nonumber;

%fdate()

ods rtf file="&_dcdata_path\HsngMon\Prog\2006-4\Who_owns_2006_09.rtf" style=Styles.Rtf_arial_9pt;

proc tabulate data=HsngMon.Who_owns_2006_09 format=comma8.0 noseps missing;
  where OwnerCat in ( '040', '050', '060', '070', '080', '090', '100' );
  class OwnerCat Ownername;
  var landarea;
  table
    OwnerCat='Owner category = ',
    Ownername=' ' all='\b TOTAL',
    n='Number of parcels'
    landarea='Land area' * ( sum='Sq.\~feet (000s)'*f=thous. sum='Acres'*f=acres. )
    / box='Owner name' rts=60;
  format OwnerCat $OwnCat. ;
  title2 "Real property ownership, Washington, DC, 2006";
  footnote1 height=9pt j=l "Source: &data / revised: &fdate";
  footnote2 height=9pt j=r '{Page}\~{\field{\*\fldinst{\pard\b\i0\chcbpat8\qc\f1\fs19\cf1{PAGE }\cf0\chcbpat0}}}';

run;

ods rtf close;

options date number;

signoff;
