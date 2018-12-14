/**************************************************************************
 Program:  Hmda_2007_2.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  02/14/07
 Version:  SAS 9.1
 Environment:  Windows
 
 Description:  Get HMDA data for Housing Monitor report tables &
graphs.

 Modifications:
**************************************************************************/

%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";
***%include "C:\DCData\SAS\Inc\Stdhead.sas";

** Define libraries **;
%DCData_lib( HsngMon )
%DCData_lib( Hmda )
%DCData_lib( RealProp )

*options obs=0;

%let hmda_vars = 
  nummrtgorighomepurch1_4m_: mrtgorigmedamthomepur1_4m_: medianmrtginc1_4m_:
  numsubprimeconvorighomepur_: NumConvMrtgOrigHomePurch_: 
  NumHighCostConvOrigPurch_: DenHighCostConvOrigPurch_:
  NumMrtgOrigHomePurch1_4m_: mrtgorigpurchowner1_4m_:
  NumMrtgOrigBlack_: NumMrtgOrigWhite_: NumMrtgOrigHisp_: NumMrtgOrigasianpi_: 
  nummrtgorigotherx_: NumMrtgOrigWithRace_: NumMrtgOrigRaceNotProvided_:
  NumMrtgPurchDenial_: denmrtgpurchdenial_:
  nummrtgorighomepurch_f_: nummrtgorighomepurch_sex_:
  NumMrtgOrig_:
  ;

data City (compress=no);

  merge 
    Hmda.Hmda_sum_city (keep=city &hmda_vars) 
    RealProp.Units_sum_city (keep=city units_sf_condo_:);
  by city;

run;

data Ward (compress=no);

  merge 
    Hmda.Hmda_sum_wd02 (keep=ward2002 &hmda_vars) 
    RealProp.Units_sum_wd02 (keep=ward2002 units_sf_condo_:);
  by ward2002;

run;

** Combine city and ward data **;

data HsngMon.Hmda_2007_2 (label="HMDA summary data for Housing Monitor, Spring 2007");

  set City Ward;

  ** Median mortgage amount to current dollars **;
  
  array medamt{1997:2005} mrtgorigmedamthomepur1_4m_1997 - mrtgorigmedamthomepur1_4m_2005;
  array medamtad{1997:2005} mrtgmedhomepur_adj_1997 - mrtgmedhomepur_adj_2005;
  
  do i = 1997 to 2005;
    %dollar_convert( medamt{i} / 1000, medamtad{i}, i, 2006 )
  end;

  ** Median borrower income to current dollars **;
  
  array medinc{1997:2005} medianmrtginc1_4m_1997 - medianmrtginc1_4m_2005;
  array medincad{1997:2005} medianmrtginc1_4m_a_1997 - medianmrtginc1_4m_a_2005;
  
  do i = 1997 to 2005;
    %dollar_convert( medinc{i} / 1000, medincad{i}, i, 2006 )
  end;

  ** Investor loans **;
  
  array purch{1997:2005} NumMrtgOrigHomePurch1_4m_1997 - NumMrtgOrigHomePurch1_4m_2005;
  array owner{1997:2005} mrtgorigpurchowner1_4m_1997 - mrtgorigpurchowner1_4m_2005;
  array invest{1997:2005} NumMrtgInvest_1997 - NumMrtgInvest_2005;
  
  do i = 1997 to 2005;
    invest{i} = purch{i} - owner{i};
  end;
  
  drop i;
  
run;

%File_info( data=HsngMon.Hmda_2007_2, printobs=0 )

