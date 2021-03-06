/**************************************************************************
 Program:  S8summary_2007_4.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  11/20/07
 Version:  SAS 9.1
 Environment:  Windows
 
 Description:  Create summary Sec. 8 MF reports for city, wards, and
 clusters.  Writes to Excel file
   d:\DCData\Libraries\HsngMon\Prog\2007-3\S8summary_2007_4.xls 
 (must be open before running program).

 Modifications:
 11-16-05  Remove PAC/PRAC/202/811 contracts and technical assistance 
           contracts as recommended by Kira Brown.
 04-11-06  Revised categorization of active, expired, renewed contracts.
           Changed cluster var from cluster2000 to cluster_tr2000.
 04-17-06  Output map data for active & upcoming expiring projects.
 03-05-07  Added var IN_CWC_RPT to output data set. 
 11/23/07 PAT Modified lenren format.
              Move report format code to autocall macros.
              Use Init_macro_vars() to create global macros.
**************************************************************************/

***%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";
%include "C:\DCData\SAS\Inc\Stdhead.sas";

** Define libraries **;
%DCData_lib( HsngMon )
%DCData_lib( HUD )

%Init_macro_vars( rpt_yr=2007, rpt_qtr=4 )

%S8ReportDates( hud_file_date='09/25/2007' )

%let prev_rpt_file = S8summary_2007_3;

%let dde = n;                          %** Send output to DDE (Y/N) **;

**** Don't change below this line ****;
%let data = Hud.Sec8mf_current_dc;
%let rpt_file = S8summary_&g_rpt_yr._&g_rpt_qtr;
%let rpt_xls  = &rpt_file..xls;
%let map_file = &rpt_file;

%let BLANK = '20'x;    ** Blank character for DDE output **;

%fdate()

** Create report formats **;

%Format_prevqtrs()

%Format_nextqtrs()

%Format_qtrsgrph()

%Format_misszero()

**************************************
*****   Create data for tables   *****
**************************************;

data HsngMon.&rpt_file;

  set &data;
  
  in_cwc_rpt = 1;

  ** Remove PAC/PRAC/202/811 contracts and technical assistance contracts 
  ** as recommended by Kira Brown;
  
  if cur_program_type_name in ('PRAC/202','PRAC/811','UHsngMonstPrj SCHAP','Service Coo') then delete;
  
  if cur_tracs_status = 'T' and not( missing( date_cur_contract ) ) and
       date_cur_contract < cur_expiration_date and 
       not( missing( put( date_cur_contract, prevqtrs. ) ) ) then do;
  
    ** Terminated contracts **;
    
    ***NB: NEED TO CHECK IF DATE_CUR_CONTRACT IS THE CORRECT DATE TO USE FOR A TERMINATION ***;
    
    rpt_status = 4;
    exp_contracts = 1;
    exp_units = cur_assisted_units_count;
    exp_ren_date = date_cur_contract;

    act_contracts = 0;
    act_units = 0;

    upt_contracts = 0;
    upt_units = 0;

    upg_contracts = 0;
    upg_units = 0;

    ren_contracts = 0;
    ren_units = 0;

  end;
  else if missing( cur_expiration_date ) then do;
    
    ***delete;
    in_cwc_rpt = 0;
    
  end;
  else if cur_expiration_date >= intnx( 'qtr', &g_s8_rpt_dt, 0, 'beginning' ) then do;
  
    ** Active contracts **;
  
    rpt_status = 3;
    act_contracts = 1;
    act_units = cur_assisted_units_count;

    if not( missing( put( cur_expiration_date, qtrsgrph. ) ) ) then do;
     
      ** Upcoming expiring (graphs - next 10 years) **;
      
      upg_contracts = 1;
      upg_units = cur_assisted_units_count;
      
      if not( missing( put( cur_expiration_date, nextqtrs. ) ) ) then do;

        ** Upcoming expiring (tables - next four quarters) **;
        
        upt_contracts = 1;
        upt_units = cur_assisted_units_count;
        
      end;
      else do;

        upt_contracts = 0;
        upt_units = 0;
        
      end;

    end;
    else do;
    
      ** Active contracts not expiring in the next 10 years **;
    
      upg_contracts = 0;
      upg_units = 0;

      upt_contracts = 0;
      upt_units = 0;

    end;
    
    if cur_expiration_date > prev_expiration_date and
       not( missing( prev_expiration_date ) ) and
       not( missing( put( date_cur_contract, prevqtrs. ) ) ) then do;
            
      ** Renewed contracts (past four quarters) **;
      
      rpt_status = 2;
      ren_contracts = 1;
      ren_units = cur_assisted_units_count;
      exp_ren_date = date_cur_contract;
      
      ren_contract_len = max( intck( 'YEAR', prev_expiration_date, cur_expiration_date ), 1 );

    end;
    else do;

      ren_contracts = 0;
      ren_units = 0;
    
    end;
    
    exp_contracts = 0;
    exp_units = 0;
        
  end;
  else if not( missing( put( cur_expiration_date, prevqtrs. ) ) ) then do;
    
    ** Expired contracts (past four quarters) **;
    
    rpt_status = 4;
    exp_contracts = 1;
    exp_units = cur_assisted_units_count;
    exp_ren_date = cur_expiration_date;

    act_contracts = 0;
    act_units = 0;

    upt_contracts = 0;
    upt_units = 0;

    upg_contracts = 0;
    upg_units = 0;

    ren_contracts = 0;
    ren_units = 0;

  end;
  else do;
  
    ** Outdated expired projects **;
  
    ***delete;
    in_cwc_rpt = 0;
  end;
     
  format in_cwc_rpt dyesno. rpt_status s8ui4cat.;
  
  label 
    rpt_status = "Contract status as of report date (&g_s8_rpt_dt_fmt)"
    in_cwc_rpt = "Projects included in city, ward & cluster reports";

run;

%File_info(
  data=HsngMon.&rpt_file,
  contents=Y,
  printobs=0,
  stats=
)


** Print list of active, renewed and expired projects **;

proc print data=HsngMon.&rpt_file;
  where in_cwc_rpt and act_contracts > 0;
  id contract_number;
  var ward2002 date_cur_contract cur_expiration_date prev_expiration_date 
      act_contracts act_units upt_contracts upt_units upg_contracts upg_units;
  sum act_contracts act_units upt_contracts upt_units upg_contracts upg_units;
  format date_cur_contract mmddyy10.;
  title2 'Active Contracts';

proc print data=HsngMon.&rpt_file;
  where in_cwc_rpt and ren_contracts > 0;
  id contract_number;
  var ward2002 exp_ren_date date_cur_contract cur_expiration_date prev_expiration_date 
      ren_contract_len ren_contracts ren_units;
  sum ren_contracts ren_units;
  format exp_ren_date prevqtrs. date_cur_contract mmddyy10.;
  title2 'Renewed Contracts (past 4 quarters)';
  
proc print data=HsngMon.&rpt_file;
  where in_cwc_rpt and exp_contracts > 0;
  id contract_number;
  var cur_ui_status ward2002 exp_ren_date date_cur_contract cur_expiration_date prev_expiration_date 
      exp_contracts exp_units;
  sum exp_contracts exp_units;
  format exp_ren_date prevqtrs. date_cur_contract mmddyy10.;
  title2 'Expired/Terminated Contracts (past 4 quarters)';
  
run;

title2;


******************************
*****   Create reports   *****
******************************;

%macro skip;

/** Macro Write_dde - Start Definition **/

%macro Write_dde( sheet=, range=, data=, var=, fopt=notab, dde=y );

  %let dde = %upcase( &dde );

  %if &dde = Y %then %do;
    filename xlsFile dde "excel|&&g_path\[&rpt_xls]&sheet!&range" lrecl=256 &fopt;
  %end;
  %else %do;
    %let range = %sysfunc( compress( &range, ':' ) );
    filename xlsFile "&&g_path\_tmp_&rpt_xls..&sheet..&range..txt" lrecl=256;
  %end;

  data _null_;

    set &data;
    
    file xlsFile;
    
    %*put &var;
    
    %let i = 1;
    %let v = %scan( &var, &i );
    
    %do %while ( &v ~= );
      put &v '09'x @;
      %let i = %eval( &i + 1 );
      %let v = %scan( &var, &i );
    %end;
    
    put;
    
  run;

  filename xlsFile clear;

%mend Write_dde;

/** End Macro Definition **/

%mend skip;

%note_mput( msg=Creating report for &g_rpt_title )
    
%Write_dde( dde=&dde, sheet=Titles, range=r1c2:r1c2, data=S8ReportDates, var=rpt_date )
%Write_dde( dde=&dde, sheet=Titles, range=r2c2:r2c2, data=S8ReportDates, var=as_of )
%Write_dde( dde=&dde, sheet=Titles, range=r3c2:r3c2, data=S8ReportDates, var=past_4 )
%Write_dde( dde=&dde, sheet=Titles, range=r4c2:r4c2, data=S8ReportDates, var=next_4 )
%Write_dde( dde=&dde, sheet=Titles, range=r5c2:r5c2, data=S8ReportDates, var=hud_date )
%Write_dde( dde=&dde, sheet=Titles, range=r6c2:r6c2, data=S8ReportDates, var=hud_file )
%Write_dde( dde=&dde, sheet=Titles, range=r7c2:r7c2, data=S8ReportDates, var=rpt_update )

%macro skip;

**************************************
*****  Create mapping data file  *****
**************************************;

** Upcoming expiring **;

libname dbmsdbf dbdbf "D:\DCData\Libraries\HsngMon\Maps" ver=4 width=12 dec=2
  upexp=&map_file._expiring 
  upexp_q1=&map_file._exp_q1 
  upexp_q2=&map_file._exp_q2
  upexp_q3=&map_file._exp_q3
  upexp_q4=&map_file._exp_q4
  oth_act=&map_file._other_act
  ;

data 
  dbmsdbf.upexp (drop=act_contracts upt_contracts)
  dbmsdbf.oth_act (drop=expir_qtr act_contracts upt_contracts);

  merge 
    HsngMon.&rpt_file 
      (keep=contract_number cur_expiration_date cur_assisted_units_count
            act_contracts upt_contracts 
            cur_address_line1_text
       in=in1)
    Hud.Sec8mf_2006_02_dc (keep=contract_number x_coord y_coord in=in2);
  by contract_number;
  
  if in1;
  
  expir_qtr = put( cur_expiration_date, nextqtrs. );
  
  if upt_contracts > 0 then output dbmsdbf.upexp;
  else if act_contracts > 0 then output dbmsdbf.oth_act;
  
  *if not in2 then put (_all_) (=);
  
run;

%mend skip;


**************************
*****  City Summary  *****
**************************;

** Current Active **;

proc summary data=HsngMon.&rpt_file;
  where in_cwc_rpt;
  var act_contracts act_units;
  output out=CurrentActive sum= ;

%Write_dde( dde=&dde, sheet=City, range=r7c3:r7c4, data=CurrentActive, 
            var=act_contracts act_units )

** Renewals/Expirations past 4 quarters **;

proc summary data=HsngMon.&rpt_file completetypes;
  where in_cwc_rpt;
  *where not( missing( put( exp_ren_date, prevqtrs. ) ) );
  class exp_ren_date / descending preloadfmt;
  var exp_contracts exp_units ren_contracts ren_units;
  output 
    out=RenewExpir (where=(not( missing( put( exp_ren_date, prevqtrs. ) ) ) ) )
    sum= ;
  format 
    exp_ren_date prevqtrs. 
    exp_contracts exp_units ren_contracts ren_units misszero.;

*proc print;

** Renewals (next 4 quarters) **;

%Write_dde( dde=&dde, sheet=City, range=r58c2:r62c4, data=RenewExpir, fopt=notab, 
            var=exp_ren_date ren_contracts ren_units )

** Expirations (past 4 quarters) **;

%Write_dde( dde=&dde, sheet=City, range=r73c2:r77c4, data=RenewExpir, fopt=notab, 
            var=exp_ren_date exp_contracts exp_units )

** Length of renewal **;

proc format;
  value lenren
    . = 'Total'
    0 <-< 2 = '1 year'
    2 -< 3 = '2 years'
    3 -< 6 = '3-5 years'
    6 -< 10 = '6-9 years'
    10 - high = '10+ years';

proc summary data=HsngMon.&rpt_file completetypes;
  where in_cwc_rpt and ren_contracts > 0;
  class ren_contract_len / preloadfmt;
  var ren_contracts ren_units;
  output 
    out=RenewLen
    sum= ;
  format 
    ren_contract_len lenren. 
    ren_contracts ren_units misszero.;

*proc print;

%Write_dde( dde=&dde, sheet=City, range=r65c2:r70c4, data=RenewLen, fopt=notab, 
            var=ren_contract_len ren_contracts ren_units )


** Upcoming Expiring (table) **;

proc summary data=HsngMon.&rpt_file completetypes;
  where in_cwc_rpt and not( missing( put( cur_expiration_date, nextqtrs. ) ) );
  class cur_expiration_date / preloadfmt;
  var upt_contracts upt_units;
  output 
    out=UpcomingExp 
      (where=(not( missing( put( cur_expiration_date, nextqtrs. ) ) ) ) )
    sum= ;
  format cur_expiration_date nextqtrs. upt_contracts upt_units misszero.;

*proc print;

%Write_dde( dde=&dde, sheet=City, range=r11c2:r15c4, data=UpcomingExp,  
            var=cur_expiration_date upt_contracts upt_units )

** Upcoming Expiring (graphs) **;

proc summary data=HsngMon.&rpt_file completetypes nway;
  where in_cwc_rpt and not( missing( put( cur_expiration_date, qtrsgrph. ) ) );
  class cur_expiration_date / preloadfmt;
  var upg_contracts upg_units;
  output out=UpcomingExpGraph 
    (where=(not( missing( put( cur_expiration_date, qtrsgrph. ) ) ) ) )
    sum= ;
  format cur_expiration_date qtrsgrph. upg_contracts upg_units misszero.;

%Write_dde( dde=&dde, sheet=City, range=r24c12:r33c14, data=UpcomingExpGraph,  
            var=cur_expiration_date upg_contracts upg_units )


***********************************
******  Ward summary report  ******
***********************************;

** Ward format **;

data _cntlin (compress=no);

  set General.Ward2002 end=eof;
  
  length fmt_label $ 8;
  
  fmt_label = Ward2002;
  
  output;
  
  if eof then do;
    ward2002 = ' ';
    fmt_label = 'Total';
    output;
  end;

run;

%Data_to_format(
  FmtLib=work,
  FmtName=$wards,
  Data=_cntlin,
  Value=ward2002,
  Label=fmt_label,
  OtherLabel=,
  DefaultLen=5,
  MaxLen=.,
  MinLen=.,
  Print=N
  )

** Report date for title **;

%Write_dde( dde=&dde, sheet=Ward, range=r2c1:r2c3, data=S8ReportDates, var=rpt_date )

** Current active **;

proc summary data=HsngMon.&rpt_file completetypes;
  where in_cwc_rpt;
  class ward2002 / preloadfmt;
  var act_contracts act_units;
  output out=WardCurrentActive sum= ;
  format ward2002 $wards. act_contracts act_units misszero.;

*proc print;

%Write_dde( dde=&dde, sheet=Ward, range=r10c1:r18c3, data=WardCurrentActive, 
            var=ward2002 act_contracts act_units )

** Renewals, Expirations, Expiring **;

proc summary data=HsngMon.&rpt_file completetypes;
  where in_cwc_rpt;
  class ward2002 / preloadfmt;
  var ren_contracts ren_units exp_contracts exp_units 
      upt_contracts upt_units;
  output out=WardRenExp sum= ;
  format 
    ward2002 $wards.
    ren_contracts ren_units exp_contracts exp_units 
    upt_contracts upt_units misszero.;

*proc print;

%Write_dde( dde=&dde, sheet=Ward, range=r10c5:r18c12, data=WardRenExp, 
            var=ren_contracts ren_units &BLANK exp_contracts exp_units 
                &BLANK upt_contracts upt_units )


**************************************
******  Cluster summary report  ******
**************************************;

** Cluster format **;

data _cntlin (compress=no);

  set General.Cluster2000 end=eof;
  
  length fmt_label $ 250;
  
  fmt_label = Cluster2000;
  
  output;
  
  if eof then do;
    Cluster2000 = ' ';
    fmt_label = 'Total';
    output;
  end;

run;

%Data_to_format(
  FmtLib=work,
  FmtName=$cluster,
  Data=_cntlin,
  Value=cluster2000,
  Label=fmt_label,
  OtherLabel=,
  DefaultLen=5,
  MaxLen=.,
  MinLen=.,
  Print=N
  )

** Report date for title **;

%Write_dde( dde=&dde, sheet=Cluster, range=r2c1:r2c1, data=S8ReportDates, var=rpt_date )

** Current active **;

proc summary data=HsngMon.&rpt_file completetypes;
  where in_cwc_rpt;
  class cluster_tr2000 / preloadfmt;
  var act_contracts act_units;
  output out=ClusCurrentActive sum= ;
  format cluster_tr2000 $cluster. act_contracts act_units misszero.;

data ClusCurrentActive;

  set ClusCurrentActive;

  ** Extra cluster var for list of neighborhoods **;
  
  cluster_tr2000_n = cluster_tr2000;
  format cluster_tr2000_n $clus00b.;

run;

*proc print;

%Write_dde( dde=&dde, sheet=Cluster, range=r10c1:r50c4, data=ClusCurrentActive, 
            var=cluster_tr2000 cluster_tr2000_n act_contracts act_units )

** Renewals, Expirations, Expiring **;

proc summary data=HsngMon.&rpt_file completetypes;
  where in_cwc_rpt;
  class cluster_tr2000 / preloadfmt;
  var ren_contracts ren_units exp_contracts exp_units 
      upt_contracts upt_units;
  output out=ClusRenExp sum= ;
  format 
    cluster_tr2000 $cluster. 
    ren_contracts ren_units exp_contracts exp_units 
    upt_contracts upt_units misszero.;

data ClusRenExp;

  set ClusRenExp;

  ** Extra cluster var for list of neighborhoods **;
  
  cluster_tr2000_n = cluster_tr2000;
  format cluster_tr2000_n $clus00b.;

run;

*proc print;

%Write_dde( dde=&dde, sheet=Cluster, range=r10c6:r50c13, data=ClusRenExp, 
            var=ren_contracts ren_units &BLANK exp_contracts exp_units 
                &BLANK upt_contracts upt_units )


*******************************************
******  Preservation summary report  ******
*******************************************;

%S8preservation( dde=n )


*********************************************
*****   Comparison with previous file   *****
*********************************************;

proc format;
  value $report
    'BASE' = "&prev_rpt_file"
    'COMPARE' = "&rpt_file";

** Project address changes **;

proc compare base=HsngMon.&prev_rpt_file compare=HsngMon.&rpt_file maxprint=(100,32000)
             out=result (drop=_obs_ rename=(_type_=Report)) outnoequal outbase outcomp noprint;
  id contract_number ward2002 cluster_tr2000;
  var cur_address_line1_text;
run;

proc print data=result noobs;
   by contract_number;
   id contract_number;
   format report $report.;
   title2 "Project-by-project comparison with previous Section 8 file";
   title3 "Project address changes";
run;

** Project contract status changes **;

proc compare base=HsngMon.&prev_rpt_file compare=HsngMon.&rpt_file maxprint=(100,32000)
             out=result (drop=_obs_ rename=(_type_=Report)) outnoequal outbase outcomp noprint;
  id contract_number ward2002;
  var cur_assisted_units_count rpt_status date_cur_contract cur_expiration_date prev_expiration_date;
run;

proc print data=result noobs;
   by contract_number;
   id contract_number;
   format report $report. 
     date_cur_contract cur_expiration_date prev_expiration_date mmddyy8.;
   title2 "Project-by-project comparison with previous Section 8 file";
   title3 "Project contract status changes";
run;

title2;

