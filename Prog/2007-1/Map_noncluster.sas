/**************************************************************************
 Program:  Map_noncluster.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  11/30/06
 Version:  SAS 8.2
 Environment:  Windows
 
 Description:  Export noncluster parcels w/x-y coordinates for
mapping.

 Modifications:
**************************************************************************/

%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";

** Define libraries **;
%DCData_lib( HsngMon )
%DCData_lib( RealProp )

libname dbmsdbf dbdbf "&_dcdata_path\HsngMon\Maps" ver=4 width=12 dec=2
  map=Map_noncluster;


data dbmsdbf.Map;

  merge 
    HsngMon.Who_owns_2006_09 
      (keep=ssl cluster_tr2000_mod)
    RealProp.Parcel_geo (keep=ssl x_coord y_coord geo2000 geoblk2000);
  by ssl;

  ** Temporary reclassification of parcel **;
  
  if ssl = 'PAR 00790049' then do;
    cluster_tr2000_mod = '99';
    cl_ward2002 = ' ';
  end;
  
  if cluster_tr2000_mod = '99';

run;

