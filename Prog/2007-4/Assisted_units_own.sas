/**************************************************************************
 Program:  Assisted_units_own.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  11/30/07
 Version:  SAS 9.1
 Environment:  Windows
 
 Description:  Merge assisted units data with who owns the
neighborhood.

 Modifications:
**************************************************************************/

%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";
***%include "C:\DCData\SAS\Inc\Stdhead.sas";

** Define libraries **;
%DCData_lib( HsngMon )
%DCData_lib( RealProp )

proc sort data=HsngMon.Assisted_units out=Assisted_units;
  by ssl;

data HsngMon.Assisted_units_own;

  merge 
    Assisted_units (in=in1) 
    RealProp.Who_owns 
      (keep=ssl OwnerCat ownername address2_std hstd_code ui_proptype 
            premiseadd_std OwnerDC OwnerOcc);
  by ssl;
  
  if in1;
  
  ** Correction: 1111 MASSACHUSETTS AVE NW **;
  
  if NLIHC_ID = 'NL000238' then do;
    ui_proptype = '13';
    OwnerCat = '030';
  end;
  
  ** Correction: 410 M STREET, S. E. **;
  
  if NLIHC_ID = 'NL000058' then do;
    OwnerCat = '070';
  end;
  
  *if OwnerCat = '' then OwnerCat = '999';
  
  format OwnerCat $OwnCat.;
  
run;

%File_info( data=HsngMon.Assisted_units_own, freqvars=OwnerCat )

proc print data=HsngMon.Assisted_units_own;
  where ProgCat = 1 and put( OwnerCat, $OwnCat. ) not in ( 'DC government', 'US government' );
  id NLIHC_ID;
  var ui_proptype ssl Proj_Addr_ref premiseadd_std ownername address2_std hstd_code OwnerDC OwnerOcc OwnerCat;
  format OwnerCat $OwnCat.;
  title2 'Public Housing only but not owned by DC/US govs.';
  
run;

proc print data=HsngMon.Assisted_units_own;
  where put( OwnerCat, $OwnCat. ) = 'Multifamily owner-occupied';
  id NLIHC_ID;
  var ui_proptype ssl Proj_Addr_ref premiseadd_std ownername address2_std hstd_code OwnerDC OwnerOcc;
  title2 'OwnerCat = Multifamily owner-occupied';
  
run;

proc print data=HsngMon.Assisted_units_own;
  where missing( OwnerCat );
  id NLIHC_ID;
  var ssl ward2002 Proj_Addr_ref;
  title2 'Missing OwnerCat';
  
run;

title2;

proc format;
  value ProgCat (notsorted)
    1 = 'Public Housing only'
    2 = 'Section 8 only'
    9 = 'Section 8 and other subsidies'
    3 = 'LIHTC only'
    4 = 'HOME only'
    5 = 'CDBG only'
    6 = 'HPTF only'
    /*7 = 'Other single subsidy'*/
    8 = 'LIHTC and Tax Exempt Bond only'
    7, 10 = 'All other combinations';
  value $OwnCatS (notsorted)
    '010' = 'Single-family owner-occupied'
    '020' = 'Cooperative' /*'Multifamily owner-occupied'*/
    '030' = 'Other individuals'
    '040','070' = 'DC government'
    '050' = 'US government'
    '060' = 'Foreign governments'
/*    '070' = 'Quasi-public entities' */
    '080','111' = 'Community dev./nontaxable corps./orgs.'
/*    '080' = 'Community development corporations/organizations'*/
    '090' = 'Private universities, colleges, schools'
    '110' = 'Corporations, partnership, LLCs, LLPs, associations'
/*    '111' = 'Nontaxable corporations, partnerships, associations'*/
    '115' = 'Taxable corporations, partnerships, associations'
    '100' = 'Churches, synagogues, religious'
    ''    = 'Unknown'
    ;
  
options missing='0';

ods rtf file="&_dcdata_path\HsngMon\Prog\2007-4\Assisted_units_own.rtf" style=Styles.Rtf_arial_9pt;

proc tabulate data=HsngMon.Assisted_units_own format=comma10. noseps missing;
  where ProgCat ~= . /*and OwnerCat ~= '999'*/;
  class ProgCat OwnerCat/ preloadfmt order=data;
  var mid_asst_units err_asst_units;
  table 
    /** Rows **/
    all='\b Total' ProgCat=' ',
    /** Columns **/
    sum='Assisted Units' * all=' ' * ( mid_asst_units='Est.' err_asst_units='+/-' )
    sum='Assisted Units by Ownership Category' * OwnerCat=' ' * ( mid_asst_units='Est.' err_asst_units='+/-' )
    ;
  format ProgCat ProgCat. OwnerCat $OwnCatS.;
  
run;

ods rtf close;
  