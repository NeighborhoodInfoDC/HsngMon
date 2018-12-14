/**************************************************************************
 Program:  Make_sales_formats.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  04/07/07
 Version:  SAS 9.1
 Environment:  Windows
 
 Description:  Make date formats for Housing Monitor report 
 sales tables and figures.

 Modifications:
  11/22/07 PAT Added %Format_lst4qtr()
**************************************************************************/

/** Macro Make_sales_formats - Start Definition **/

%macro Make_sales_formats( lib=work );

  %Format_dtrngA( lib=&lib, fmtname=dtrngA, rng_suffix=(annual average) )

  %Format_dtrngA( lib=&lib, fmtname=lblA, rng_suffix= )
  
  %Format_dtrngB( lib=&lib )
  
  %Format_lblB( lib=&lib )
  
  %Format_lst4qtr( lib=&lib )

%mend Make_sales_formats;

/** End Macro Definition **/

