/**************************************************************************
 Program:  Who_owns.sas
 Library:  RealProp
 Project:  DC Data Warehouse
 Author:   P. Tatian
 Created:  10/23/06
 Version:  SAS 9.1
 Environment:  Alpha
 
 Description:  List of owners for Who Owns the Neighborhood analysis.

 Modifications:
**************************************************************************/

%include "[Dcdata]Stdhead.sas";

** Define libraries **;
%DCData_lib( RealProp )

*options obs=100;

data RegExp (compress=no);

  *infile datalines dsd delimiter=' ' obs=7;
  infile datalines pad;

  length code $ 3 regexp $ 1000;

  *input @1 code $3. @5 regexp :$1000.;
  input regexp &;

datalines;
/^FRIENDS MEETING OF /
/[A-Z].* (CHURCH|CRCH|CH)\b/
/[A-Z].* SYNAGOG(UE|)[^A-Z].*/
/[A-Z].* TEMPLE[^A-Z].*/
/[A-Z].* CATHEDRAL[^A-Z].*/
/[A-Z].* CONGREGATION[^A-Z].*/
/[A-Z].* BAPTIST\b/
/[A-Z].* METHODIST/
/SEVENTH( |)DAY/
/\bCATHOLIC\b/
/\bAPOSTOLIC\b/
/\b(ST|SAINT) [A-Z]+ .*\bOF [A-Z]+/
/\bARCHBISHOP\b/
/\b(ARCH|)DIOCESE\b/
/\bDE DIOS\b/
/^CHURCH [A-Z]+/
/\bORTHODOX\b/
/\bMENNONITE\b/
/\bOF GOD\b/
/\bEPISCOPAL\b/
/\bEVANGELI(CAL|STIC)\b/
/\bMINISTR(Y|IES)\b/
/\bCONGREG(ATION(AL|)|)\b/
/HOLY (CHRISTIAN|COMFORTER) /
/\bIGLESIA\b/
/\bISLAMIC\b/
/\bALL SOULS\b/
/\bPENTACOSTAL\b/
/\bMINISTRY\b/
/\bCAPUCHIN\b/
/\bIMMACULATE\b/
/\bSACRED HEART/
/[A-Z]+ .*\bPARISH\b/
/\bVESTRY\b/
/THE APOSTLE/
/\bCHRISTIAN FELLOWSHIP\b/
/\bTABERNACLE\b/
;

proc print;

data Test (compress=no);

  set RealProp.Ownerpt_2006_09 (keep=ssl ownername ui_proptype premiseadd);

  ownername = left( compbl( compress( upcase( ownername ), "._" ) ) );

  length code1-code100 $ 3;
  retain code1-code100 re1-re100 num_rexp;

  array a_code{*} $ code1-code100;
  array a_re{*}     re1-re100;

  if _n_ = 1 then do;

    i = 1;

    do until ( eof );
      set RegExp end=eof;
      a_code{i} = code;
      a_re{i} = prxparse( regexp );
      if missing( a_re{i} ) then do;
        putlog "Error" regexp=;
        stop;
      end;
      i = i + 1;
    end;

    num_rexp = i - 1;

    put num_rexp= a_re{1}= a_re{2}=;

  end;

%macro skip;
  if _n_ = 1 then do;
    retain re1 re2;
    regexp = "/^THE DISTRICT OF COLUMBIA.*/";
    re1 = prxparse( regexp );
    regexp = "/^DISTRICT OF COLUMBIA.*/";
    re2 = prxparse( regexp );
    if missing( re2 ) then do;
      putlog "Error" regexp=;
      stop;
    end;
  end;
    
  if prxmatch( re1, ownername ) or prxmatch( re2, ownername );
%mend skip;

  i = 1;
  match = 0;

  do while ( i <= num_rexp and not match );
    if prxmatch( a_re{i}, ownername ) then do;
      code = a_code{i};
      match = 1;
      output;
    end;
    i = i + 1;
  end;

  keep code ssl ownername ui_proptype premiseadd;

  run;

proc freq data=Test;
  tables ownername / nocum nopercent;

proc print data=Test;
  id ssl;
  var ownername ui_proptype premiseadd;

run;
