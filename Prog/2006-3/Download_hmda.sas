/**************************************************************************
 Program:  Download_hmda.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  08/07/06
 Version:  SAS 8.2
 Environment:  Windows with SAS/Connect
 
 Description:  Reformat and download HMDA data for Housing Monitor 
 reports.
 Fall 2006

 Modifications:
  08/24/06  Added high-cost loan vars. for 2004.
            Added NumMrtgOrigRaceNotProvided for all years.
**************************************************************************/

%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";
%include "K:\Metro\PTatian\DCData\SAS\Inc\AlphaSignon.sas" /nosource2;

** Define libraries **;
%DCData_lib( HsngMon )
%DCData_lib( HMDA )
%DCData_lib( RealProp )

** Get additional HMDA variables **;

rsubmit;

*options obs=100;

/** Macro Compile_HMDA - Start Definition **/

%macro Compile_HMDA( start_yr, end_yr );

  data HMDA;
  
    set
    
      %do yr = &start_yr %to &end_yr;
      
        %if &yr >= 1995 and &yr <= 2002 %then %do;
      
          %** 1995 to 2002 **;
      
          Hmda.Hmda_sum_&yr._was
            (where=(geo2000=:"11")
             keep=geo2000 year 
                  mrtgorigmeddollaramthomepurch  /* Median amount of mortgage loans for home purchase ($) */
                  nummrtgpurchdenial  /* Denials of conventional home purchase loans */
                  nummrtgpurchapps  /* Conventional home purchase mortgage loan applications */
                  nummrtgorighomepurch  /* Mortgage loans for home purchase */
                  numconvmrtgorighomepurch  /* Conventional mortgage loans for home purchase */
                  numsubprimemrtgorighomepurch  /* Conventional home purchase mortgage loans by subprime lenders */
                  nummrtgorigtotal  /* Owner-occupied home purchase mortgage loans */
                  medianmrtginc  /* Median borrower income for owner-occupied home purchase loans */
                  nummrtgorigblack  /* Owner-occupied home purchase mortgage loans to Black borrowers */
                  nummrtgorigwhite  /* Owner-occupied home purchase mortgage loans to White borrowers */
                  nummrtgorighisp /* Owner-occupied home purchase mortgage loans to Hispanic borrowers */
                  nummrtgorigasianpi  /* Values Owner-occupied home purchase mortgage loans to Asians */
                  nummrtgorigwithrace /* Owner-occupied home purchase loans where borrower race is known */
                  NumMrtgOrigRaceNotProvided /* Owner-occupied home purchase loans where borrower race is missing */
             )
             
        %end;
        %else %if &yr = 2003 or &yr = 2004 %then %do;
        
          %** 2003 & 2004 (new format) **;
        
          Hmda.Hmda_sum_&yr._was
            (where=(geo2000=:"11")
             rename=(
               MrtgOrigMedAmtHomePurch1_4m=mrtgorigmeddollaramthomepurch 
               NumMrtgPurchDenial=nummrtgpurchdenial 
               DenMrtgPurchDenial=nummrtgpurchapps 
               NumMrtgOrigHomePurch1_4m=nummrtgorighomepurch 
               NumConvMrtgOrigHomePurch=numconvmrtgorighomepurch 
               NumSubprimeConvOrigHomePurch=numsubprimemrtgorighomepurch 
               MrtgOrigPurchOwner1_4m=nummrtgorigtotal 
               MedianMrtgInc1_4m=medianmrtginc 
               NumMrtgOrigBlack=nummrtgorigblack 
               NumMrtgOrigWhite=nummrtgorigwhite 
               NumMrtgOrigHisp=nummrtgorighisp
               NumMrtgOrigAsianPI=nummrtgorigasianpi 
               nummrtgorigwithrace=nummrtgorigwithrace
             )
             keep=geo2000 year 
                  MrtgOrigMedAmtHomePurch1_4m /* Median amount of mortgage loans for home purchase ($) */
                  NumMrtgPurchDenial /* Denials of conventional home purchase loans */
                  DenMrtgPurchDenial /* Conventional home purchase mortgage loan applications */
                  NumMrtgOrigHomePurch1_4m /* Mortgage loans for home purchase */
                  NumConvMrtgOrigHomePurch /* Conventional mortgage loans for home purchase */
                  NumSubprimeConvOrigHomePurch /* Conventional home purchase mortgage loans by subprime lenders */
                  MrtgOrigPurchOwner1_4m /* Owner-occupied home purchase mortgage loans */
                  MedianMrtgInc1_4m /* Median borrower income for owner-occupied home purchase loans */
                  NumMrtgOrigBlack /* Owner-occupied home purchase mortgage loans to Black borrowers */
                  NumMrtgOrigWhite /* Owner-occupied home purchase mortgage loans to White borrowers */
                  NumMrtgOrigHisp /* Owner-occupied home purchase mortgage loans to Hispanic borrowers */
                  NumMrtgOrigAsianPI /* Owner-occupied home purchase mortgage loans to Asians */
                  nummrtgorigwithrace /* Owner-occupied home purchase loans where borrower race is known */
                  NumMrtgOrigRaceNotProvided /* Number of owner-occupied home purchase mortgage loan originations 
                                                to borrowers for 1 to 4 family dwellings and manufactured homes 
                                                whose race is not provided */
                  NumMrtgOrigHomePurch_F /* Number of owner-occupied home purchase mortgage loan originations to female borrowers for 1 to 4 family dwellings and manufactured homes */
                  NumMrtgOrigHomePurch_sex /* Number of owner-occupied home purchase mortgage loan originations with gender information for 1 to 4 family dwellings and manufactured homes */
                  %if &yr = 2004 %then %do;
                    NumHighCostConvOrigPurch /* Conventional home purchase mortgage loan originations for 1 to 4 family dwellings and manufactured homes with high interest rates */
                    DenHighCostConvOrigPurch /* Conventional home purchase mortgage loan originations for 1 to 4 family dwellings and manufactured homes with interest rate information */
                  %end;
             )
        %end;
        
      %end;
      
      ;
    by geo2000 year;
    
    /*
    TotalLoansByRace = sum( of 
      NumMrtgOrigAsianPI NumMrtgOrigBlack NumMrtgOrigHisp
      NumMrtgOrigWhite NumMrtgOrigAmerInd NumMrtgOrigOther
      NumMrtgOrigMxd NumMrtgOrigRaceNotProvided
    );
    */
    
    ** Investor loans **;
    
    NumMrtgInvest = nummrtgorighomepurch - nummrtgorigtotal;

    ** Adjust mortgage amounts to thousand $ 2006 **;
    
    %dollar_convert( mrtgorigmeddollaramthomepurch / 1000, mrtgmedhomepur_adj, year, 2006 )
    %dollar_convert( medianmrtginc / 1000, medianmrtginc_adj, year, 2006 )
    
    drop mrtgorigmeddollaramthomepurch medianmrtginc;
    
    rename numsubprimemrtgorighomepurch=numsubprimemrtgorighomepur;
    
  run;
  
  %let var_list = 
    mrtgmedhomepur_adj nummrtgpurchdenial
    nummrtgpurchapps nummrtgorighomepurch
    numconvmrtgorighomepurch numsubprimemrtgorighomepur
    nummrtgorigtotal medianmrtginc_adj nummrtgorigblack
    nummrtgorigwhite nummrtgorighisp nummrtgorigasianpi
    nummrtgorigwithrace NumMrtgOrigRaceNotProvided NumMrtgInvest
    NumMrtgOrigHomePurch_F NumMrtgOrigHomePurch_sex
    NumHighCostConvOrigPurch DenHighCostConvOrigPurch;
    
  %let ds_list = ;
    
  %let i = 1;
  %let var = %scan( &var_list, &i );
  
  %do %until ( &var = );
  
    proc transpose data=Hmda out=ds_&var (drop=_name_ _label_) prefix=&var._;
      var &var;
      id year;
      by geo2000;
    run;
    
    %let ds_list = &ds_list ds_&var;

    %let i = %eval( &i + 1 );
    %let var = %scan( &var_list, &i );

  %end;
  
  data Hmda_tr00;
  
    merge &ds_list Realprop.Num_units_tr00 (keep=geo2000 units_sf_condo_:);
    by geo2000;
    
  run;
  
%mend Compile_HMDA;

%Compile_hmda( 1995, 2004 )

proc contents data=Realprop.Num_units_tr00;
run;

****  Convert HMDA indicators to city, ward & housing market typology levels ****;

** City **;

/*
proc summary data=Hmda_tr00;
  var nummrtgpurchdenial:
      nummrtgpurchapps: nummrtgorighomepurch:
      numconvmrtgorighomepurch: numsubprimemrtgorighomepur:
      nummrtgorigtotal: nummrtgorigblack:
      nummrtgorigwhite: nummrtgorighisp: nummrtgorigasianpi:
      units_sf_condo_:
      nummrtgorigwithrace: NumMrtgOrigRaceNotProvided: NumMrtgInvest:
      medianmrtginc_adj: mrtgmedhomepur_adj:;
  output out=Hmda_city
    sum( nummrtgpurchdenial:
         nummrtgpurchapps: nummrtgorighomepurch:
         numconvmrtgorighomepurch: numsubprimemrtgorighomepur:
         nummrtgorigtotal: nummrtgorigblack:
         nummrtgorigwhite: nummrtgorighisp: nummrtgorigasianpi:
         nummrtgorigwithrace: NumMrtgOrigRaceNotProvided: NumMrtgInvest:
         units_sf_condo_: ) =
     mean( medianmrtginc_adj: mrtgmedhomepur_adj: ) = ;

run;
*/

title2;

%Transform_geo_data(
    dat_ds_name=Hmda_tr00,
    dat_org_geo=geo2000,
    dat_count_vars=
      nummrtgpurchdenial:
      nummrtgpurchapps: nummrtgorighomepurch:
      numconvmrtgorighomepurch: numsubprimemrtgorighomepur:
      nummrtgorigtotal: nummrtgorigblack:
      nummrtgorigwhite: nummrtgorighisp: nummrtgorigasianpi:
      nummrtgorigwithrace: NumMrtgOrigRaceNotProvided: NumMrtgInvest:
      units_sf_condo_:
      NumHighCostConvOrigPurch: DenHighCostConvOrigPurch:
    ,
    dat_prop_vars=medianmrtginc_adj: mrtgmedhomepur_adj:,
    wgt_ds_name=General.wt_tr00_city,
    wgt_org_geo=geo2000,
    wgt_new_geo=city,
    wgt_id_vars=,
    wgt_wgt_var=popwt,
    out_ds_name=Hmda_city,
    out_ds_label=,
    calc_vars=,
    calc_vars_labels=,
    keep_nonmatch=N,
    show_warnings=10,
    print_diag=Y,
    full_diag=N
  )

** Wards **;

%Transform_geo_data(
    dat_ds_name=Hmda_tr00,
    dat_org_geo=geo2000,
    dat_count_vars=
      nummrtgpurchdenial:
      nummrtgpurchapps: nummrtgorighomepurch:
      numconvmrtgorighomepurch: numsubprimemrtgorighomepur:
      nummrtgorigtotal: nummrtgorigblack:
      nummrtgorigwhite: nummrtgorighisp: nummrtgorigasianpi:
      nummrtgorigwithrace: NumMrtgOrigRaceNotProvided: NumMrtgInvest:
      units_sf_condo_:
      NumHighCostConvOrigPurch: DenHighCostConvOrigPurch:
    ,
    dat_prop_vars=medianmrtginc_adj: mrtgmedhomepur_adj:,
    wgt_ds_name=General.wt_tr00_ward02,
    wgt_org_geo=geo2000,
    wgt_new_geo=ward2002,
    wgt_id_vars=,
    wgt_wgt_var=popwt,
    out_ds_name=Hmda_wd02,
    out_ds_label=,
    calc_vars=,
    calc_vars_labels=,
    keep_nonmatch=N,
    show_warnings=10,
    print_diag=Y,
    full_diag=N
  )

** Clusters **;

%Transform_geo_data(
    dat_ds_name=Hmda_tr00,
    dat_org_geo=geo2000,
    dat_count_vars=
      nummrtgpurchdenial:
      nummrtgpurchapps: nummrtgorighomepurch:
      numconvmrtgorighomepurch: numsubprimemrtgorighomepur:
      nummrtgorigtotal: nummrtgorigblack:
      nummrtgorigwhite: nummrtgorighisp: nummrtgorigasianpi:
      nummrtgorigwithrace: NumMrtgOrigRaceNotProvided: NumMrtgInvest:
      units_sf_condo_:
      NumHighCostConvOrigPurch: DenHighCostConvOrigPurch:
    ,
    dat_prop_vars=medianmrtginc_adj: mrtgmedhomepur_adj:,
    wgt_ds_name=General.wt_tr00_cltr00,
    wgt_org_geo=geo2000,
    wgt_new_geo=cluster_tr2000,
    wgt_id_vars=,
    wgt_wgt_var=popwt,
    out_ds_name=Hmda_cltr00,
    out_ds_label=,
    calc_vars=,
    calc_vars_labels=,
    keep_nonmatch=N,
    show_warnings=10,
    print_diag=Y,
    full_diag=N
  )

** Download data to PC **;

proc download status=no
  inlib=work 
  outlib=HsngMon memtype=(data);
  select hmda_city hmda_wd02 hmda_cltr00 Hmda_tr00;

run;

endrsubmit;

%File_info( data=HsngMon.hmda_tr00, printobs=0 )
%File_info( data=HsngMon.hmda_city, printobs=0 )
%File_info( data=HsngMon.hmda_wd02, printobs=0 )

signoff;

