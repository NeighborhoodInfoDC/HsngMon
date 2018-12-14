/**************************************************************************
 Program:  Compare_s8summary.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  11/23/07
 Version:  SAS 9.1
 Environment:  Windows
 
 Description:  Compare most recent S8summary data sets.

 Modifications:
**************************************************************************/

***%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";
%include "C:\DCData\SAS\Inc\Stdhead.sas";

** Define libraries **;
%DCData_lib( HsngMon )

%let start_date = '01jan2000'd;

  data S8losses_2007_4 (compress=no);

    set HsngMon.S8summary_2007_4;
    
    if cur_tracs_status = 'T' then 
      loss_date = min( date_cur_ui_status, cur_expiration_date );
    else
      loss_date = cur_expiration_date;
      
    if loss_date >= &start_date;
    
    format loss_date mmddyy10.;
   
  run;  


  data S8losses_2007_3 (compress=no);

    set HsngMon.S8summary_2007_3;
    
    if cur_tracs_status = 'T' then 
      loss_date = min( date_cur_ui_status, cur_expiration_date );
    else
      loss_date = cur_expiration_date;
      
    if loss_date >= &start_date;
    
    format loss_date mmddyy10.;
   
  run;  



proc compare base=S8losses_2007_4 compare=S8losses_2007_3 maxprint=(40,32000);
  id contract_number;

run;
