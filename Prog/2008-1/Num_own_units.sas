/**************************************************************************
 Program:  Num_own_units.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  10/17/07
 Version:  SAS 9.1
 Environment:  Windows with SAS/Connect
 
 Description:  Create table showing numbers of home ownership units
(sf, condo, coop) from 2000 - 2006.

 Modifications:
**************************************************************************/

%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";
%include "K:\Metro\PTatian\DCData\SAS\Inc\AlphaSignon.sas" /nosource2;

** Define libraries **;
%DCData_lib( HsngMon )
%DCData_lib( RealProp )

** Start submitting commands to remote server **;

rsubmit;

data Num_own_units (compress=no);

  set RealProp.Num_units_wd02 
      (keep=ward2002 
            units_owner_2000-units_owner_2007 
            units_condo_2000-units_condo_2007 
            units_coop_2000-units_coop_2007
            units_sf_2000-units_sf_2007);

  array owner{*} units_owner_2000-units_owner_2007;
  array ch_owner{*} ch_units_owner_2000-ch_units_owner_2007;
  
  do i = 1 to dim( owner );
    ch_owner{i} = owner{i} - owner{1};
  end;

  array sf{*} units_sf_2000-units_sf_2007;
  array ch_sf{*} ch_units_sf_2000-ch_units_sf_2007;
  
  do i = 1 to dim( sf );
    ch_sf{i} = sf{i} - sf{1};
  end;

  array condo{*} units_condo_2000-units_condo_2007;
  array ch_condo{*} ch_units_condo_2000-ch_units_condo_2007;
  
  do i = 1 to dim( condo );
    ch_condo{i} = condo{i} - condo{1};
  end;

  array coop{*} units_coop_2000-units_coop_2007;
  array ch_coop{*} ch_units_coop_2000-ch_units_coop_2007;
  
  do i = 1 to dim( coop );
    ch_coop{i} = coop{i} - coop{1};
  end;

  format ward2002 $ward02a.;

run;

proc download status=no
  data=Num_own_units 
  out=Num_own_units;

run;

endrsubmit;

** End submitting commands to remote server **;

****** Numbers of units ******;

proc tabulate data=Num_own_units format=comma8.0 noseps missing;
  class ward2002;
  var units_:;
  
  table 
    /** Rows **/
    all='Washington, D.C.' ward2002=' '
    ,
    /** Columns **/
    sum='Ownership units (s.f. + condo + coop)' * ( 
      units_owner_2000
      units_owner_2001
      units_owner_2002
      units_owner_2003
      units_owner_2004
      units_owner_2005
      units_owner_2006
      units_owner_2007
    )
    ;
  label
    units_owner_2000 = '2000'
    units_owner_2001 = '2001'
    units_owner_2002 = '2002'
    units_owner_2003 = '2003'
    units_owner_2004 = '2004'
    units_owner_2005 = '2005'
    units_owner_2006 = '2006'
    units_owner_2007 = '2007';
    
  table 
    /** Rows **/
    all='Washington, D.C.' ward2002=' '
    ,
    /** Columns **/
    sum='Single-family homes' * ( 
      units_sf_2000
      units_sf_2001
      units_sf_2002
      units_sf_2003
      units_sf_2004
      units_sf_2005
      units_sf_2006
      units_sf_2007
    )
    ;
  label
    units_sf_2000 = '2000'
    units_sf_2001 = '2001'
    units_sf_2002 = '2002'
    units_sf_2003 = '2003'
    units_sf_2004 = '2004'
    units_sf_2005 = '2005'
    units_sf_2006 = '2006'
    units_sf_2007 = '2007';
    
  table 
    /** Rows **/
    all='Washington, D.C.' ward2002=' '
    ,
    /** Columns **/
    sum='Condominium units' * ( 
      units_condo_2000
      units_condo_2001
      units_condo_2002
      units_condo_2003
      units_condo_2004
      units_condo_2005
      units_condo_2006
      units_condo_2007
    )
    ;
  label
    units_condo_2000 = '2000'
    units_condo_2001 = '2001'
    units_condo_2002 = '2002'
    units_condo_2003 = '2003'
    units_condo_2004 = '2004'
    units_condo_2005 = '2005'
    units_condo_2006 = '2006'
    units_condo_2007 = '2007';
    
  table 
    /** Rows **/
    all='Washington, D.C.' ward2002=' '
    ,
    /** Columns **/
    sum='Cooperative units' * ( 
      units_coop_2000
      units_coop_2001
      units_coop_2002
      units_coop_2003
      units_coop_2004
      units_coop_2005
      units_coop_2006
      units_coop_2007
    )
    ;
  label
    units_coop_2000 = '2000'
    units_coop_2001 = '2001'
    units_coop_2002 = '2002'
    units_coop_2003 = '2003'
    units_coop_2004 = '2004'
    units_coop_2005 = '2005'
    units_coop_2006 = '2006'
    units_coop_2007 = '2007';

  title2 "Numbers of ownership units";

run;

****** Change in numbers of units ******;

proc tabulate data=Num_own_units format=comma8.0 noseps missing;
  class ward2002;
  var ch_units_:;
  
  table 
    /** Rows **/
    all='Washington, D.C.' ward2002=' '
    ,
    /** Columns **/
    sum='Ownership units (s.f. + condo + coop)' * ( 
      ch_units_owner_2000
      ch_units_owner_2001
      ch_units_owner_2002
      ch_units_owner_2003
      ch_units_owner_2004
      ch_units_owner_2005
      ch_units_owner_2006
      ch_units_owner_2007
    )
    ;
  label
    ch_units_owner_2000 = '2000'
    ch_units_owner_2001 = '2001'
    ch_units_owner_2002 = '2002'
    ch_units_owner_2003 = '2003'
    ch_units_owner_2004 = '2004'
    ch_units_owner_2005 = '2005'
    ch_units_owner_2006 = '2006'
    ch_units_owner_2007 = '2007';
    
  table 
    /** Rows **/
    all='Washington, D.C.' ward2002=' '
    ,
    /** Columns **/
    sum='Single-family homes' * ( 
      ch_units_sf_2000
      ch_units_sf_2001
      ch_units_sf_2002
      ch_units_sf_2003
      ch_units_sf_2004
      ch_units_sf_2005
      ch_units_sf_2006
      ch_units_sf_2007
    )
    ;
  label
    ch_units_sf_2000 = '2000'
    ch_units_sf_2001 = '2001'
    ch_units_sf_2002 = '2002'
    ch_units_sf_2003 = '2003'
    ch_units_sf_2004 = '2004'
    ch_units_sf_2005 = '2005'
    ch_units_sf_2006 = '2006'
    ch_units_sf_2007 = '2007';
    
  table 
    /** Rows **/
    all='Washington, D.C.' ward2002=' '
    ,
    /** Columns **/
    sum='Condominium units' * ( 
      ch_units_condo_2000
      ch_units_condo_2001
      ch_units_condo_2002
      ch_units_condo_2003
      ch_units_condo_2004
      ch_units_condo_2005
      ch_units_condo_2006
      ch_units_condo_2007
    )
    ;
  label
    ch_units_condo_2000 = '2000'
    ch_units_condo_2001 = '2001'
    ch_units_condo_2002 = '2002'
    ch_units_condo_2003 = '2003'
    ch_units_condo_2004 = '2004'
    ch_units_condo_2005 = '2005'
    ch_units_condo_2006 = '2006'
    ch_units_condo_2007 = '2007';
    
  table 
    /** Rows **/
    all='Washington, D.C.' ward2002=' '
    ,
    /** Columns **/
    sum='Cooperative units' * ( 
      ch_units_coop_2000
      ch_units_coop_2001
      ch_units_coop_2002
      ch_units_coop_2003
      ch_units_coop_2004
      ch_units_coop_2005
      ch_units_coop_2006
      ch_units_coop_2007
    )
    ;
  label
    ch_units_coop_2000 = '2000'
    ch_units_coop_2001 = '2001'
    ch_units_coop_2002 = '2002'
    ch_units_coop_2003 = '2003'
    ch_units_coop_2004 = '2004'
    ch_units_coop_2005 = '2005'
    ch_units_coop_2006 = '2006'
    ch_units_coop_2007 = '2007';

  title2 "Cumulative change in numbers of ownership units since 2000";

run;

signoff;
