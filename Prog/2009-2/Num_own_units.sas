/**************************************************************************
 Program:  Num_own_units.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  04/23/09
 Version:  SAS 9.1
 Environment:  Windows with SAS/Connect
 
 Description:  Create table showing numbers of home ownership units
 (sf, condo, coop) from 2000 - 2008.

 Modifications:
**************************************************************************/

%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";
%include "K:\Metro\PTatian\DCData\SAS\Inc\AlphaSignon.sas" /nosource2;

** Define libraries **;
%DCData_lib( HsngMon )
%DCData_lib( RealProp )

** Start submitting commands to remote server **;

rsubmit;

%let start_yr = 1998;
%let end_yr = 2008;

data Num_own_units (compress=no);

  set RealProp.Num_units_wd02 
      (keep=ward2002 
            units_owner_&start_yr-units_owner_&end_yr 
            units_condo_&start_yr-units_condo_&end_yr 
            units_coop_&start_yr-units_coop_&end_yr
            units_sf_&start_yr-units_sf_&end_yr);

  array owner{*} units_owner_&start_yr-units_owner_&end_yr;
  array ch_owner{*} ch_units_owner_&start_yr-ch_units_owner_&end_yr;
  
  do i = 1 to dim( owner );
    ch_owner{i} = owner{i} - owner{1};
  end;

  array sf{*} units_sf_&start_yr-units_sf_&end_yr;
  array ch_sf{*} ch_units_sf_&start_yr-ch_units_sf_&end_yr;
  
  do i = 1 to dim( sf );
    ch_sf{i} = sf{i} - sf{1};
  end;

  array condo{*} units_condo_&start_yr-units_condo_&end_yr;
  array ch_condo{*} ch_units_condo_&start_yr-ch_units_condo_&end_yr;
  
  do i = 1 to dim( condo );
    ch_condo{i} = condo{i} - condo{1};
  end;

  array coop{*} units_coop_&start_yr-units_coop_&end_yr;
  array ch_coop{*} ch_units_coop_&start_yr-ch_units_coop_&end_yr;
  
  do i = 1 to dim( coop );
    ch_coop{i} = coop{i} - coop{1};
  end;

  format ward2002 $ward02a.;

run;

proc download status=no
  data=Num_own_units 
  out=HsngMon.Num_own_units;

run;

endrsubmit;

** End submitting commands to remote server **;

****** Numbers of units ******;

proc tabulate data=HsngMon.Num_own_units format=comma8.0 noseps missing;
  class ward2002;
  var units_:;
  
  table 
    /** Rows **/
    all='Washington, D.C.' ward2002=' '
    ,
    /** Columns **/
    sum='Ownership units (s.f. + condo + coop)' * ( 
      units_owner_1998
      units_owner_1999
      units_owner_2000
      units_owner_2001
      units_owner_2002
      units_owner_2003
      units_owner_2004
      units_owner_2005
      units_owner_2006
      units_owner_2007
      units_owner_2008
    )
    ;
  label
    units_owner_1998 = '1998'
    units_owner_1999 = '1999'
    units_owner_2000 = '2000'
    units_owner_2001 = '2001'
    units_owner_2002 = '2002'
    units_owner_2003 = '2003'
    units_owner_2004 = '2004'
    units_owner_2005 = '2005'
    units_owner_2006 = '2006'
    units_owner_2007 = '2007'
    units_owner_2008 = '2008'
    ;
    
  table 
    /** Rows **/
    all='Washington, D.C.' ward2002=' '
    ,
    /** Columns **/
    sum='Single-family homes' * ( 
      units_sf_1998
      units_sf_1999
      units_sf_2000
      units_sf_2001
      units_sf_2002
      units_sf_2003
      units_sf_2004
      units_sf_2005
      units_sf_2006
      units_sf_2007
      units_sf_2008
    )
    ;
  label
    units_sf_1998 = '1998'
    units_sf_1999 = '1999'
    units_sf_2000 = '2000'
    units_sf_2001 = '2001'
    units_sf_2002 = '2002'
    units_sf_2003 = '2003'
    units_sf_2004 = '2004'
    units_sf_2005 = '2005'
    units_sf_2006 = '2006'
    units_sf_2007 = '2007'
    units_sf_2008 = '2008'
    ;
    
  table 
    /** Rows **/
    all='Washington, D.C.' ward2002=' '
    ,
    /** Columns **/
    sum='Condominium units' * ( 
      units_condo_1998
      units_condo_1999
      units_condo_2001
      units_condo_2002
      units_condo_2003
      units_condo_2004
      units_condo_2005
      units_condo_2006
      units_condo_2007
      units_condo_2008
    )
    ;
  label
    units_condo_2000 = '1998'
    units_condo_2000 = '1999'
    units_condo_2000 = '2000'
    units_condo_2001 = '2001'
    units_condo_2002 = '2002'
    units_condo_2003 = '2003'
    units_condo_2004 = '2004'
    units_condo_2005 = '2005'
    units_condo_2006 = '2006'
    units_condo_2007 = '2007'
    units_condo_2008 = '2008'
    ;
    
  table 
    /** Rows **/
    all='Washington, D.C.' ward2002=' '
    ,
    /** Columns **/
    sum='Cooperative units' * ( 
      units_coop_1998
      units_coop_1999
      units_coop_2000
      units_coop_2001
      units_coop_2002
      units_coop_2003
      units_coop_2004
      units_coop_2005
      units_coop_2006
      units_coop_2007
      units_coop_2008
    )
    ;
  label
    units_coop_1998 = '1998'
    units_coop_1999 = '1999'
    units_coop_2000 = '2000'
    units_coop_2001 = '2001'
    units_coop_2002 = '2002'
    units_coop_2003 = '2003'
    units_coop_2004 = '2004'
    units_coop_2005 = '2005'
    units_coop_2006 = '2006'
    units_coop_2007 = '2007'
    units_coop_2008 = '2008'
    ;

  title2 "Numbers of ownership units";

run;

****** Change in numbers of units ******;

proc tabulate data=HsngMon.Num_own_units format=comma8.0 noseps missing;
  class ward2002;
  var ch_units_:;
  
  table 
    /** Rows **/
    all='Washington, D.C.' ward2002=' '
    ,
    /** Columns **/
    sum='Ownership units (s.f. + condo + coop)' * ( 
      ch_units_owner_1998
      ch_units_owner_1999
      ch_units_owner_2000
      ch_units_owner_2001
      ch_units_owner_2002
      ch_units_owner_2003
      ch_units_owner_2004
      ch_units_owner_2005
      ch_units_owner_2006
      ch_units_owner_2007
      ch_units_owner_2008
    )
    ;
  label
    ch_units_owner_1998 = '1998'
    ch_units_owner_1999 = '1999'
    ch_units_owner_2000 = '2000'
    ch_units_owner_2001 = '2001'
    ch_units_owner_2002 = '2002'
    ch_units_owner_2003 = '2003'
    ch_units_owner_2004 = '2004'
    ch_units_owner_2005 = '2005'
    ch_units_owner_2006 = '2006'
    ch_units_owner_2007 = '2007'
    ch_units_owner_2008 = '2008'
    ;
    
  table 
    /** Rows **/
    all='Washington, D.C.' ward2002=' '
    ,
    /** Columns **/
    sum='Single-family homes' * ( 
      ch_units_sf_1998
      ch_units_sf_1999
      ch_units_sf_2000
      ch_units_sf_2001
      ch_units_sf_2002
      ch_units_sf_2003
      ch_units_sf_2004
      ch_units_sf_2005
      ch_units_sf_2006
      ch_units_sf_2007
      ch_units_sf_2008
    )
    ;
  label
    ch_units_sf_1998 = '1998'
    ch_units_sf_1999 = '1999'
    ch_units_sf_2000 = '2000'
    ch_units_sf_2001 = '2001'
    ch_units_sf_2002 = '2002'
    ch_units_sf_2003 = '2003'
    ch_units_sf_2004 = '2004'
    ch_units_sf_2005 = '2005'
    ch_units_sf_2006 = '2006'
    ch_units_sf_2006 = '2007'
    ch_units_sf_2006 = '2008'
    ;
    
  table 
    /** Rows **/
    all='Washington, D.C.' ward2002=' '
    ,
    /** Columns **/
    sum='Condominium units' * ( 
      ch_units_condo_1998
      ch_units_condo_1999
      ch_units_condo_2000
      ch_units_condo_2001
      ch_units_condo_2002
      ch_units_condo_2003
      ch_units_condo_2004
      ch_units_condo_2005
      ch_units_condo_2006
      ch_units_condo_2007
      ch_units_condo_2008
    )
    ;
  label
    ch_units_condo_1998 = '1998'
    ch_units_condo_1999 = '1999'
    ch_units_condo_2000 = '2000'
    ch_units_condo_2001 = '2001'
    ch_units_condo_2002 = '2002'
    ch_units_condo_2003 = '2003'
    ch_units_condo_2004 = '2004'
    ch_units_condo_2005 = '2005'
    ch_units_condo_2006 = '2006'
    ch_units_condo_2007 = '2007'
    ch_units_condo_2008 = '2008'
    ;
    
  table 
    /** Rows **/
    all='Washington, D.C.' ward2002=' '
    ,
    /** Columns **/
    sum='Cooperative units' * ( 
      ch_units_coop_1998
      ch_units_coop_1999
      ch_units_coop_2000
      ch_units_coop_2001
      ch_units_coop_2002
      ch_units_coop_2003
      ch_units_coop_2004
      ch_units_coop_2005
      ch_units_coop_2006
      ch_units_coop_2007
      ch_units_coop_2008
    )
    ;
  label
    ch_units_coop_1998 = '1998'
    ch_units_coop_1999 = '1999'
    ch_units_coop_2000 = '2000'
    ch_units_coop_2001 = '2001'
    ch_units_coop_2002 = '2002'
    ch_units_coop_2003 = '2003'
    ch_units_coop_2004 = '2004'
    ch_units_coop_2005 = '2005'
    ch_units_coop_2006 = '2006'
    ch_units_coop_2007 = '2007'
    ch_units_coop_2008 = '2008'
    ;

  title2 "Cumulative change in numbers of ownership units since 2000";

run;

signoff;
