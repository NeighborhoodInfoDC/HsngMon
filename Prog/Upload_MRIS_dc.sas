/**************************************************************************
 Program:  Upload_MRIS_dc.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  08/07/06
 Version:  SAS 8.2
 Environment:  Windows with SAS/Connect
 
 Description:  Upload & register latest MRIS monthly data for DC.
 
 NB: Update the revisions = macro variable before submitting.

 Modifications:
**************************************************************************/

%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";
%include "K:\Metro\PTatian\DCData\SAS\Inc\AlphaSignon.sas" /nosource2;

** Define libraries **;
%DCData_lib( HsngMon )

rsubmit;

%let revisions = %str(Updated through June 2009.);

proc upload status=no
  data=HsngMon.MRIS_monthly_dc 
  out=HsngMon.MRIS_monthly_dc;

x "purge [dcdata.hsngmon]MRIS_monthly_dc.*";

run;

%Dc_update_meta_file(
  ds_lib=HsngMon,
  ds_name=MRIS_monthly_dc,
  creator_process=Read_MRIS_dc.sas,
  restrictions=None,
  revisions=&revisions
)

run;

endrsubmit;

signoff;
