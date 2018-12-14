/**************************************************************************
 Program:  Format_qtrsgrph.sas
 Library:  HsngMon
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  11/23/07
 Version:  SAS 9.1
 Environment:  Windows
 
 Description:  Autocall macro to create Sec. 8 table format qtrsgrph.

 Modifications:
**************************************************************************/

/** Macro Format_qtrsgrph - Start Definition **/

%macro Format_qtrsgrph( num_years=&g_s8_rpt_num_years );

  ** Create quarter/year format for report graphs (qtrsgrph.)      **;
  ** Through current calendar year and next &num_years years **;

  data _cntlin;

    retain fmtname 'qtrsgrph' type 'n' sexcl 'n' eexcl 'y' hlo ' ';
    
    is_quarters = 1;
    dt0 = intnx( 'qtr', &g_s8_rpt_dt, 0, 'beginning' );
    dtend = intnx( 'year', &g_s8_rpt_dt, &num_years, 'end' );

    format dt0 dt1 dtend mmddyy10.;
    
    put dt0= dtend=;
      
    do while ( dt0 <= dtend );
    
      dt1 = intnx( 'year', dt0, 1, 'beginning' );
      
      if dt0 ~= intnx( 'year', dt0, 0, 'beginning' ) then
        label = trim( left( put( dt0, monname3. ) ) ) ||
                '-' || 
                trim( left( put( dt1 - 1, monname3. ) ) ) ||
                ' ' ||
                left( put( dt0, year4. ) );
       else
        label = left( put( dt0, year4. ) );
      
      start = put( dt0, 8. );
      end = put( dt1, 8. );
      
      output;

      dt0 = dt1;
    
    end;
    
    hlo = 'o';
    label = '';
    
    output;
    
  run;

  proc format library=work cntlin=_cntlin fmtlib;
    select qtrsgrph;

  run;

%mend Format_qtrsgrph;

/** End Macro Definition **/

