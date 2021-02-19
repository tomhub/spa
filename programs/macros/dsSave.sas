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
Save dataset with labels and variables as per given define.xml
md*
*******************************************************************************/
%macro dsSave(
    dsin=workinprogress /*Req. dataset in*/
    ,domain=            /*Req. cdisc domain name*/
    ,dsout=             /*Opt. dataset out, if missing, produces into &defineLibname..&domain */
    ,defineLibname=     /*Opt. defineLocation library name (usually AD or SD. If blank, tries to guess AD or SD based on &domain.)*/
    ,defineFilename=define.xml  /*Req. define.xml filename (could be full path, or just filename. If value contains / or \, pathname("&defineLibname.") is not being used.*/
    ,silent=Y           /*if ne Y then produces additional messages in the log*/
);
    %local failed;
    %let failed=0;
    %if %sysevalf(%superq(dsin)=,boolean) %then %do;
        %put %sysfunc(cats(ER,ROR:)) DSIN is a required paramater and cannot be empty.;
        %let failed = 1;
    %end;
    %else %if not %sysfunc(exist(&dsin.)) %then %do;
        %put %sysfunc(cats(ER,ROR:)) &=dsin. does not exist.;
        %let failed = 1;
    %end;
    
    %if %sysevalf(%superq(domain)=,boolean) %then %do;
        %put %sysfunc(cats(ER,ROR:)) DOMAIN is a required paramater and cannot be empty.;
        %let failed = 1;
    %end;
    
    %if %sysevalf(%superq(defineFilename)=,boolean) %then %do;
        %put %sysfunc(cats(ER,ROR:)) DEFINEFILENAME is a required paramater and cannot be empty.;
        %let failed = 1;
    %end;
    
    %if &failed. %then %do;
        %put %sysfunc(cats(ER,ROR:)) macro has ended.;
        %goto exit;
    %end;
    
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
        %put %sysfunc(cats(NO,TICE:)) using: &pathToDefine.;
    %end;
    
    filename __fn001 "%str(&pathToDefine.)";
    %if %sysfunc(fileref(__fn001)) ne 0 %then %do;
        %put %sysfunc(cats(ER,ROR:)) does not exist: &=pathToDefine.. Check macro parameteres used.;
        filename __fn001 clear;
        %goto exit;
    %end;
    
    %* here could possible do a check not to re-read define.xml each time;
    
    %* get the metadata from define.xml;
    %readDefineXML(
        filename="&defineFileName."
        ,libout=work
        ,forceUpdate=Y
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
    

    %local ds_label dsvars dsattrs;
    %let ds_label = " ";
    %let dsvars =;
    %let dsattrs =;
    data _null_;
        set __ma_variables end=eof;
        where dsname eq "%upcase(&domain.)";
        
        length __atr $32767 __vars $32767;
        retain __atr ' ' __vars ' ';
        
        if datatype not in ('date' 'text' 'integer') then put 'ER' 'ROR: update: dsSave macro: ' datatype=;
        
        __vars = catx(' ', __vars, varname);
        
        __atr = catx(' ', __atr
            ,'attrib'
            ,varname
            ,ifc(not missing(itemDescriptionEN), 'label='||quote(strip(itemDescriptionEN)), trimn(' '))
            ,ifc(datatype in ('date' 'text') and not missing(length), 'length=$'||strip(length), trimn(' '))
            ,ifc(datatype in ('date') and missing(length), 'length=$40', trimn(' '))
            ,ifc(datatype in ('text') and missing(length), 'length=$200', trimn(' '))
            ,ifc(not missing(def_displayFormat), 'format='||strip(def_displayFormat), trimn(' '))
        );
        __atr = trim(__atr)||';';
        if eof then do;
            call symputx('ds_label', quote(strip(dslabelen)));
            call symputx('dsvars', __vars);
            call symputx('dsattrs', __atr);
        end;
    run;
    
    %local dssort ignore;
    
    %let dssort = ;
    proc sql noprint;
        select distinct
            keysequence
            ,ordernumber
            ,varname
                into :ignore, :ignore, :dssort separated by ' '
            from __ma_variables
                where dsname eq "%upcase(&domain.)" and not missing(keysequence)
                order by keysequence, ordernumber, varname
        ;
    quit;
    
    data &dsout(label=%sysfunc(symget(ds_label)));
        &dsattrs.
        set &dsin.;
        keep &dsvars;
    run;
    
    %if not %sysevalf(%superq(dssort)=,boolean) %then %do;
        proc sort data=&dsout. out=&dsout.(label=%sysfunc(symget(ds_label)));
            by &dssort.;
        run;
    %end;
    
    %exit:
%mend dsSave;
/** Example call:
%dsSave(
    dsin=adsl01
    ,dsout=adsl_fin
    ,defineFileName=%sysfunc(pathname(ad))/define.xml
    ,domain=adsl
    ,silent=N
);
*/