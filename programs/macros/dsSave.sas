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
    ,xpt=Y              /*Y/N: produce xpt ?*/
);
    %local failed _option_validvarname;

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

    %local _option_validvarname;
    %let _option_validvarname = %sysfunc(getoption(validvarname));
    option validvarname=any;

    %metadata(
        defineFilename=%str(&defineFilename.)
        ,domain=&domain.
        ,defineLibname=&defineLibname.
        ,silent=&silent.
    );

    %if %sysevalf(%superq(dsout)=,boolean) %then %do;
        %let dsout = work.&domain.;
    %end;
    %else %do;
        %if not %index(&dsout., %str(.)) %then %do;
            %let dsout = work.&dsout.;
        %end;
    %end;

    %put %sysfunc(cats(NO,TICE:)) producing into: &=dsout.;
    %* prepare place - need to get date/time var lengths based on output dataset;
    %compressds(dsin=&dsin., dsout=&dsout.);

    %local ds_label dsvars dsattrs;
    %let ds_label = " ";
    %let dsvars =;
    %let dsattrs =;
    data _null_;
        set __ma_variables end=eof;
        by ordernumber;
        where dsname eq "%upcase(&domain.)";

        retain dsid;
        if _N_ eq 1 then do;
            dsid = open("&dsout.", 'is');
        end;
        length __atr $32767 __vars $32767;
        retain __atr ' ' __vars ' ';
        
        if datatype not in ('date' 'text' 'integer' 'partialDate' 'float' 'datetime') then put 'ER' 'ROR: update: dsSave macro: ' datatype=;
        
        __vars = catx(' ', __vars, varname);
        
        if varnum(dsid, strip(varname)) then do;
            if vartype(dsid, varnum(dsid, strip(varname))) eq 'C' then do;
                _varlen = varlen(dsid, varnum(dsid, strip(varname)));
            end;
            else _varlen = 8;
        end;
        else _varlen = 1;

        __atr = catx(' ', __atr
            ,'attrib'
            ,varname
            ,ifc(not missing(itemDescriptionEN), 'label='||quote(strip(itemDescriptionEN)), trimn(' '))
            ,ifc(datatype in ('text' 'date' 'datetime' 'partialDate') and not missing(length), 'length=$'||strip(put(length, best.)), trimn(' '))
            ,ifc(datatype in ('text' 'date' 'datetime' 'partialDate') and missing(length), 'length=$'||strip(put(_varlen, best.)), trimn(' '))
            ,ifc(datatype in ('integer' 'float'), 'length=8', trimn(' '))
            ,ifc(not missing('def:displayFormat'n), 'format='||strip('def:displayFormat'n), trimn(' '))
        );
        __atr = trim(__atr)||';';
        if eof then do;
            call symputx('ds_label', quote(strip(dslabelen)));
            call symputx('dsvars', __vars);
            call symputx('dsattrs', __atr);
            _rc = close(dsid);
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


    data &dsout(label=&ds_label.);
        &dsattrs.
        set &dsout.;
        keep &dsvars.;
    run;
    
    %* restore original option*;
    option validvarname=&_option_validvarname.;

    %if not %sysevalf(%superq(dssort)=,boolean) %then %do;
        %* supress sorting attribute from dataset to avoid wa ning in the log*;
        %* with xport library ;
        proc sort data=&dsout. out=&dsout.(label=&ds_label. sortedby=_null_);
            by &dssort.;
        run;

        data _null_;
            set &dsout.;
            by &dssort.;
            if not (first.%scan(&dssort., -1, ' ') and last.%scan(&dssort., -1, ' ')) then do;
                put 'ER' 'ROR: not unique key to sort dataset ex.: '
                    %local i;
                    %let i = 1;
                    %do %while(%scan(&dssort., &i., %str( )) ne %str( ));
                        %scan(&dssort., &i., %str( ))=
                        %let i = %eval(&i. + 1);
                    %end;
                ;
                stop;
            end;
        run;
    %end;

    %if &xpt. eq Y %then %do;
        libname _____xpt xport "%sysfunc(pathname(%scan(&dsout., 1, %str(.))))/&domain..xpt";

        proc copy in=%scan(&dsout., 1, %str(.)) out=_____xpt;
            select %scan(&dsout., 2, %str(.));
        run;
        
        libname _____xpt clear;
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
