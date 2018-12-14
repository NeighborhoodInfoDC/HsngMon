/**************************************************************************
 Program:  Map2&3.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  02/26/07
 Version:  SAS 8.2
 Environment:  Windows
 
 Description:  Create supplemental maps (not in report)
   Map 2. Government-owned res. land by cluster.
   Map 3. Government-owned non-res. land by cluster.
 DC Housing Monitor Winter 2007.

 Modifications:
**************************************************************************/

%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";

** Define libraries **;
%DCData_lib( HsngMon )

libname dbmsdbf dbdbf "D:\DCData\Libraries\HsngMon\Maps" ver=4 width=12 dec=2
  Map23=Map2_3_2006_4;

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
  
  if ownercat in ( '050', '040', '070' ) then do;
    landarea_res_gov = landarea_res;
    landarea_non_gov = landarea_non;
  end;
  else do;
    landarea_res_gov = 0;
    landarea_non_gov = 0;
  end;

run;

proc summary data=Table4 nway;
  class cluster_tr2000_mod;
  var landarea_res_gov landarea_res landarea_non_gov landarea_non;
  output out=Table4_sum sum= ;

run;

proc format;
  picture acres (round)
    low-high = '0,000,009.9' (mult=2.29568411e-4);

proc tabulate data=Table4_sum;
  var landarea_res_gov landarea_res landarea_non_gov landarea_non;
  table landarea_res_gov landarea_res landarea_non_gov landarea_non,
    n sum*f=acres.;
run;

data dbmsdbf.Map23;

  set Table4_sum;
       
  where cluster_tr2000_mod ~= "99";
  
  pctgovres = 100 * landarea_res_gov / landarea_res;
  pctgovnon = 100 * landarea_non_gov / landarea_non;

  clusnum = 1 * cluster_tr2000_mod;
  
  name = put( cluster_tr2000_mod, $clus00a. );

run;

