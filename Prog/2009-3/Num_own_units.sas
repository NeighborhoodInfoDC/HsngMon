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

%let start_yr = 1999;
%let end_yr = 2009;

%syslput start_yr=&start_yr;
%syslput end_yr=&end_yr;

** Start submitting commands to remote server **;

rsubmit;

data Num_own_units (compress=no);

  set RealProp.Num_units_wd02 
      (keep=ward2002 
            units_owner_&start_yr-units_owner_&end_yr 
            units_condo_&start_yr-units_condo_&end_yr 
            units_coop_&start_yr-units_coop_&end_yr
            units_sf_&start_yr-units_sf_&end_yr);

  array owner{*} units_owner_&start_yr-units_owner_&end_yr;
  array ch_owner{*} ch_units_owner_&start_yr-ch_units_owner_&end_yr;
  array ych_owner{*} ych_units_owner_&start_yr-ych_units_owner_&end_yr;
  
  do i = 2 to dim( owner );
    ch_owner{i} = owner{i} - owner{1};
    ych_owner{i} = owner{i} - owner{i-1};
  end;

  array sf{*} units_sf_&start_yr-units_sf_&end_yr;
  array ch_sf{*} ch_units_sf_&start_yr-ch_units_sf_&end_yr;
  array ych_sf{*} ych_units_sf_&start_yr-ych_units_sf_&end_yr;
  
  do i = 2 to dim( sf );
    ch_sf{i} = sf{i} - sf{1};
    ych_sf{i} = sf{i} - sf{i-1};
  end;

  array condo{*} units_condo_&start_yr-units_condo_&end_yr;
  array ch_condo{*} ch_units_condo_&start_yr-ch_units_condo_&end_yr;
  array ych_condo{*} ych_units_condo_&start_yr-ych_units_condo_&end_yr;
  
  do i = 2 to dim( condo );
    ch_condo{i} = condo{i} - condo{1};
    ych_condo{i} = condo{i} - condo{i-1};
  end;

  array coop{*} units_coop_&start_yr-units_coop_&end_yr;
  array ch_coop{*} ch_units_coop_&start_yr-ch_units_coop_&end_yr;
  array ych_coop{*} ych_units_coop_&start_yr-ych_units_coop_&end_yr;
  
  do i = 2 to dim( coop );
    ch_coop{i} = coop{i} - coop{1};
    ych_coop{i} = coop{i} - coop{i-1};
  end;

  format ward2002 $ward02a.;

run;

proc download status=no
  data=Num_own_units 
  out=HsngMon.Num_own_units;

run;

endrsubmit;

** End submitting commands to remote server **;

/** Macro List_vars - Start Definition **/

%macro List_vars( prefix=, start=&start_yr, end=&end_yr );

  %do y = &start_yr %to &end_yr;
    &prefix._&y
  %end;

%mend List_vars;

/** End Macro Definition **/


/** Macro Label_vars - Start Definition **/

%macro Label_vars( prefix=, start=&start_yr, end=&end_yr );

  %do y = &start_yr %to &end_yr;
    &prefix._&y = "&y"
  %end;

%mend Label_vars;

/** End Macro Definition **/

options missing='-';

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
      %list_vars( prefix=units_owner )
    )
    / rts=20
    ;
  label
    %label_vars( prefix=units_owner )
    ;
    
  table 
    /** Rows **/
    all='Washington, D.C.' ward2002=' '
    ,
    /** Columns **/
    sum='Single-family homes' * ( 
      %list_vars( prefix=units_sf )
    )
    / rts=20
    ;
  label
    %label_vars( prefix=units_sf )
    ;
    
  table 
    /** Rows **/
    all='Washington, D.C.' ward2002=' '
    ,
    /** Columns **/
    sum='Condominium units' * ( 
      %list_vars( prefix=units_condo )
    )
    / rts=20
    ;
  label
    %label_vars( prefix=units_condo )
    ;
    
  table 
    /** Rows **/
    all='Washington, D.C.' ward2002=' '
    ,
    /** Columns **/
    sum='Cooperative units' * ( 
      %list_vars( prefix=units_coop )
    )
    / rts=20
    ;
  label
    %label_vars( prefix=units_coop )
    ;

  title2 "Numbers of ownership units";

run;

****** Cumulative change in numbers of units ******;

proc tabulate data=HsngMon.Num_own_units format=comma8.0 noseps missing;
  class ward2002;
  var ch_units_:;
  
  table 
    /** Rows **/
    all='Washington, D.C.' ward2002=' '
    ,
    /** Columns **/
    sum='Ownership units (s.f. + condo + coop)' * ( 
      %list_vars( prefix=ch_units_owner )
    )
    / rts=20
    ;
  label
    %label_vars( prefix=ch_units_owner )
    ;
    
  table 
    /** Rows **/
    all='Washington, D.C.' ward2002=' '
    ,
    /** Columns **/
    sum='Single-family homes' * ( 
      %list_vars( prefix=ch_units_sf )
    )
    / rts=20
    ;
  label
    %label_vars( prefix=ch_units_sf )
    ;
    
  table 
    /** Rows **/
    all='Washington, D.C.' ward2002=' '
    ,
    /** Columns **/
    sum='Condominium units' * ( 
      %list_vars( prefix=ch_units_condo )
    )
    / rts=20
    ;
  label
    %label_vars( prefix=ch_units_condo )
    ;
    
  table 
    /** Rows **/
    all='Washington, D.C.' ward2002=' '
    ,
    /** Columns **/
    sum='Cooperative units' * ( 
      %list_vars( prefix=ch_units_coop )
    )
    / rts=20
    ;
  label
    %label_vars( prefix=ch_units_coop )
    ;

  title2 "Cumulative change in numbers of ownership units";

run;

****** Year-to-year change in numbers of units ******;

proc tabulate data=HsngMon.Num_own_units format=comma8.0 noseps missing;
  class ward2002;
  var ych_units_:;
  
  table 
    /** Rows **/
    all='Washington, D.C.' ward2002=' '
    ,
    /** Columns **/
    sum='Ownership units (s.f. + condo + coop)' * ( 
      %list_vars( prefix=ych_units_owner )
    )
    / rts=20
    ;
  label
    %label_vars( prefix=ych_units_owner )
    ;
    
  table 
    /** Rows **/
    all='Washington, D.C.' ward2002=' '
    ,
    /** Columns **/
    sum='Single-family homes' * ( 
      %list_vars( prefix=ych_units_sf )
    )
    / rts=20
    ;
  label
    %label_vars( prefix=ych_units_sf )
    ;
    
  table 
    /** Rows **/
    all='Washington, D.C.' ward2002=' '
    ,
    /** Columns **/
    sum='Condominium units' * ( 
      %list_vars( prefix=ych_units_condo )
    )
    / rts=20
    ;
  label
    %label_vars( prefix=ych_units_condo )
    ;
    
  table 
    /** Rows **/
    all='Washington, D.C.' ward2002=' '
    ,
    /** Columns **/
    sum='Cooperative units' * ( 
      %list_vars( prefix=ych_units_coop )
    )
    / rts=20
    ;
  label
    %label_vars( prefix=ych_units_coop )
    ;

  title2 "Year-to-year change in numbers of ownership units";

run;

signoff;
