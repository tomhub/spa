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
Simple check if values in variable match CT values in define.xml
md*
*******************************************************************************/

%macro checkVarCT(
    domain=             /*Req. cdisc domain name*/
    ,dsin=              /*Req. dataset name to use as input*/
    ,var=               /*Req. variable name*/
    ,defineLibname=     /*Opt. defineLocation library name (usually AD or SD. If blank, tries to guess AD or SD based on &domain.)*/
    ,defineFilename=define.xml  /*Req. define.xml filename (could be full path, or just filename. If value contains / or \, pathname("&defineLibname.") is not being used.*/
    ,silent=Y
);

    %local _option_validvarname;
    %let _option_validvarname = %sysfunc(getoption(validvarname));
    option validvarname=any;

    %metadata(
        defineFilename=%str(&defineFilename.)
        ,domain=&domain.
        ,defineLibname=&defineLibname.
        ,silent=&silent.
    );
    option validvarname=&_option_validvarname.;
    
    %local ctoid;
    data _null_;
        set __ma_variables(keep=dsname varname codelistoid);
        where dsname eq "%upcase(&domain.)"
            and varname eq "%upcase(&var.)"
        ;
        call symputx('ctoid', quote(strip(codelistoid)));
    run;

    %if %sysevalf(%superq(ctoid)=,boolean) %then %do;
        %put %sysfunc(cats(WA,RNING:)) codelist not found for &=domain. &=var..;
        %goto exit;
    %end;

    proc sql noprint;
        create table __checkVarCT01 as
            select distinct
                CodeListItemRank as rank
                ,CodeListItemOrderNumber as order
                ,CodeListItemDecodeEn as decode
                ,CodeListItemName as &var.
            from __ad_codelists(where=(CodeListOID eq &ctoid.))
                outer union corresponding
            select distinct
                CodeListItemRank as rank
                ,CodeListItemOrderNumber as order
                ,CodeListItemName as &var.
            from __ad_codelistsenum(where=(CodeListOID eq &ctoid.))
        ;
    quit;

    data _null_;
        set &dsin. end=eof;
        if _N_ eq 1 then do;
            declare hash hdefineval(dataset: '__checkVarCT01');
            hdefineval.defineKey("&var.");
            hdefineval.defineData("&var.");
            hdefineval.defineDone();

            declare hash hnondefval();
            hnondefval.defineKey("&var.");
            hnondefval.defineData("&var.");
            hnondefval.defineDone();
        end;

        _rc = hdefineval.check();
        if _rc then do;
            _rc = hnondefval.check();
            if _rc then _rc = hnondefval.add();
        end;

        if eof then hnondefval.output(dataset: '__checkVarCT02');
    run;

    data _null_;
        set __checkVarCT02;
        if _N_ eq 1 then do;
            put 'WA' "RNING: non-defined value for: domain=&domain. varname=&var.:";
        end;
        put &var.=;
    run;

    %exit:
%mend checkVarCT;
