/*******************************************************************************
Copyright (c) 2021 Tomas Demčenko

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
********************************************************************************
*md
### Description
Read define.xml data
md*
*******************************************************************************/
%macro metadata(
    defineFilename=
    ,domain=
    ,defineLibname=
    ,silent=Y
);
    %local pathToDefine;
    %if %sysfunc(kindexc(%superq(defineFilename), %str(\/))) %then %do;
        %let pathToDefine = %str(&defineFilename.);
    %end;
    %else %if %sysevalf(%superq(defineLibname)=,boolean) %then %do;
        %* be smart, guess defineLibname value *;
        %if %length(&domain.) eq 2
            or %upcase(%substr(&domain., 1, 4)) eq SUPP
            or %upcase(&domain.) eq RELREC
        %then %do;
            %let defineLibname = sd;
        %end;
        %else %do;
            %let defineLibname = ad;
        %end;
        %if &silent. ne Y %then %put %sysfunc(cats(NO,TICE:)) assuming define libname: &=defineLibname.;
    %end;
    
    %if %sysevalf(%superq(pathToDefine)=,boolean) %then %do;
        %let pathToDefine = %sysfunc(pathname(&defineLibname., l))/%str(&defineFilename.);
    %end;
    
    %if &silent. ne Y %then %do;
        %put %sysfunc(cats(NO,TICE:)) using: &=pathToDefine.;
    %end;
    
    filename __fn001 "%str(&pathToDefine.)";
    %if %sysfunc(fileref(__fn001)) ne 0 %then %do;
        %put %sysfunc(cats(ER,ROR:)) does not exist: &=pathToDefine.. Check macro parameteres used.;
        filename __fn001;
        %goto exit;
    %end;
   
    %* here could possible do a check not to re-read define.xml each time;

    %* need to allow any to read for define.xml *;
    %local _option_validvarname;
    %let _option_validvarname = %sysfunc(getoption(validvarname));
    option validvarname=any;
    
    %* get the metadata from define.xml;
    %readDefineXML(
        filename="&pathToDefine."
        ,libout=work
        ,forceUpdate=N
        ,silent=N
        ,prefix=__ad_
    );
    
    %* flatten define.xml datasets;
    %prepareMetadata(
        libin=work
        ,libout=work
        ,prefix=__ad_
        ,outprefix=__ma_
    );

    %exit:
%mend metadata;
