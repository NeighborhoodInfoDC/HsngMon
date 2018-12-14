/**************************************************************************
 Program:  Figure4.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  02/14/07
 Version:  SAS 9.1
 Environment:  Windows
 
 Description:  Create data for Figure 4: population changes from HMDA
data.

 Modifications:
**************************************************************************/

%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";
***%include "C:\DCData\SAS\Inc\Stdhead.sas";

** Define libraries **;
%DCData_lib( HsngMon )

options mprint symbolgen mlogic;



/** Macro Figure4 - Start Definition **/

%macro Figure4( vars=, den=, labels=, title=, start_yr=1997, end_yr=2005, out= );

data Figure4 (compress=no);

  set HsngMon.Hmda_2007_2 (where=(not(missing(ward2002))));
  
  %let i = 1;
  %let v = %scan( &vars &den, &i );
  
  %do %while( &v ~= );
    array a_&v{&start_yr:&end_yr} &v._&start_yr-&v._&end_yr;
    %let i = %eval( &i + 1 );
    %let v = %scan( &vars &den, &i );
  %end;
  
/*    
  array a_NumMrtgOrig_vli{1997:2005} NumMrtgOrig_vli_1997-NumMrtgOrig_vli_2005;
  array a_NumMrtgOrig_li{1997:2005} NumMrtgOrig_li_1997-NumMrtgOrig_li_2005;
  array a_NumMrtgOrig_mi{1997:2005} NumMrtgOrig_mi_1997-NumMrtgOrig_mi_2005;
  array a_NumMrtgOrig_hinc{1997:2005} NumMrtgOrig_hinc_1997-NumMrtgOrig_hinc_2005;
  array a_NumMrtgOrig_inc{1997:2005} NumMrtgOrig_inc_1997-NumMrtgOrig_inc_2005;
*/

  %let i = 1;
  %let v = %scan( &vars &den, &i );
  
  do Year = 1997 to 2005;
    %do %while( &v ~= );
      &v = a_&v{Year};
      %let i = %eval( &i + 1 );
      %let v = %scan( &vars &den, &i );
    %end;
  /*
    NumMrtgOrig_vli = a_NumMrtgOrig_vli{Year};
    NumMrtgOrig_li = a_NumMrtgOrig_li{Year};
    NumMrtgOrig_mi = a_NumMrtgOrig_mi{Year};
    NumMrtgOrig_hinc = a_NumMrtgOrig_hinc{Year};
    NumMrtgOrig_inc = a_NumMrtgOrig_inc{Year};
  */
    output;
  end;
  
  keep Ward2002 Year &vars &den ;
  
run;

***proc print;

run;

proc tabulate data=Figure4 out=Figure4_out format=comma8.1 noseps missing;
  class year ward2002;
  var &vars &den;
  table
    all='All Wards' ward2002=' ',
    pctsum<&den>=' ' * (
      &den='Total' &vars
    ),
    year='Percent by Year'
    / indent=3 condense;
  %if &labels ~= %then %do;
    label &labels;
  %end;
  title2 &title;

run;

%if &out ~= %then %do;

data Figure4_exp;
  retain Ward2002 year NumMrtgOrig_vli_PctSum_11 NumMrtgOrig_li_PctSum_11 
         NumMrtgOrig_mi_PctSum_11 NumMrtgOrig_hinc_PctSum_11;
  set Figure4_out;
  where _type_ = '11' and year in ( 1997, 2001, 2005 );
  keep year ward2002 NumMrtgOrig_hinc_PctSum_11 NumMrtgOrig_mi_PctSum_11 
       NumMrtgOrig_li_PctSum_11 NumMrtgOrig_vli_PctSum_11;
run;

filename Fig4 "&_dcdata_path\Hsngmon\Prog\2007-2\Figure4.csv" lrecl=5000;

proc export data=Figure4_exp
    outfile=Fig4
    dbms=csv replace;

run;

filename Fig4 clear;

%end;

%mend Figure4;

/** End Macro Definition **/

%Figure4( title = "Home Purchase Borrowers by HUD Income Categories",
          vars = NumMrtgOrig_hinc NumMrtgOrig_mi NumMrtgOrig_li NumMrtgOrig_vli, 
          den  = NumMrtgOrig_Inc,
          labels =
            NumMrtgOrig_Inc='Total'
            NumMrtgOrig_vli='Very low' 
            NumMrtgOrig_li='Low' 
            NumMrtgOrig_mi='Middle'    
            NumMrtgOrig_hinc='High',
          out=Figure4.csv
)
      
proc print data=Figure4_out;
run;

      
%Figure4( title = "Home Purchase Borrowers by Race/Ethnicity",
          vars = NumMrtgOrigBlack NumMrtgOrigWhite NumMrtgOrigHisp NumMrtgOrigasianpi nummrtgorigotherx, 
          den  = NumMrtgOrigWithRace,
          labels =
            NumMrtgOrigBlack = 'Black'
            NumMrtgOrigWhite = 'White'
            NumMrtgOrigHisp = 'Hispanic'
            NumMrtgOrigasianpi = 'Asian/PI'
            nummrtgorigotherx = 'Other race'
)
      
      