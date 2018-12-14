/**************************************************************************
 Program:  Hmda_map.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  08/11/06
 Version:  SAS 8.2
 Environment:  Windows
 
 Description:  Create DBF file for HMDA map by clusters.

 Modifications:
**************************************************************************/

%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";

** Define libraries **;
%DCData_lib( HsngMon )
%DCData_lib( General )

libname dbmsdbf dbdbf "D:\DCData\Libraries\HsngMon\Maps" ver=4 width=12 dec=2
  Hmda_map=Hmda_2006_3;

data dbmsdbf.Hmda_map;

  set HsngMon.Hmda_cltr00 
       (keep=cluster_tr2000 numsubprimemrtgorighomepur_2004 numconvmrtgorighomepurch_2004);
       
  where cluster_tr2000 ~= "99";

  pctsubprime = 100 * numsubprimemrtgorighomepur_2004 / numconvmrtgorighomepurch_2004;
  
  clusnum = 1 * cluster_tr2000;
  
  name = put( cluster_tr2000, $clus00a. );

run;
