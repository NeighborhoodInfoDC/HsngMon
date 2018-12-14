/**************************************************************************
 Program:  Map1.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  11/28/06
 Version:  SAS 8.2
 Environment:  Windows
 
 Description:  Create Map 1. Owner-occ. housing by cluster.
 DC Housing Monitor Winter 2006/2007.

 Modifications:
**************************************************************************/

%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";

** Define libraries **;
%DCData_lib( HsngMon )

libname dbmsdbf dbdbf "D:\DCData\Libraries\HsngMon\Maps" ver=4 width=12 dec=2
  Map1=Map1_2006_4;

*options obs=0;

data Table4;

  set HsngMon.Who_owns_2006_09 
    (keep=ssl cluster_tr2000_mod cl_ward2002 ui_proptype OwnerCat ownerdc 
          landarea landarea_res landarea_non total);

  ** Temporary reclassification of parcel **;
  
  if ssl = 'PAR 00790049' then do;
    cluster_tr2000_mod = '99';
    cl_ward2002 = ' ';
  end;
  
  if ownercat in ( '010','020' ) then 
    landarea_res_ownocc = landarea_res;

run;

proc summary data=Table4 nway;
  class cluster_tr2000_mod;
  var landarea_res_ownocc landarea_res;
  output out=Table4_sum sum= ;

run;

data dbmsdbf.Map1;

  set Table4_sum;
       
  where cluster_tr2000_mod ~= "99";
  
  pctownocc = 100 * landarea_res_ownocc / landarea_res;

  clusnum = 1 * cluster_tr2000_mod;
  
  name = put( cluster_tr2000_mod, $clus00a. );

run;

