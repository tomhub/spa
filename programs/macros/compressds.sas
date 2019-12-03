/*******************************************************************************
Copyright (c) 2019 Tomas Demčenko

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
Change char var lengths in the dataset to max value length
### Change Log:
2019-11-28
* Based on: https://github.com/tomhub/SAS/blob/master/utilities/compressds.sas
* Code refactored, handles anyvarname.
md*
*******************************************************************************/
%macro compressds(
    dsin=   /*input dataset, required*/
    ,dsout= /*output dataset, if blank, &dsin. will be the output dataset.*/
    ,vars=  /*variables to proceed*/
    ,exclude_vars=  /*variables to exclude*/
    ,silent=Y   /*if Y: more messages in the log*/
);
    %* Check if required parameter is non-missing;
    %if %sysevalf(%superq(dsin)=,boolean) %then %do;
        %put %sysfunc(cats(ER,ROR:)) Macro parameter DSIN cannot be blank.;
        %return;
    %end;

    %* Check if &DSIN exists..;
    %if not %sysfunc(exist(&dsin)) %then %do;
        %put %sysfunc(cats(ER,ROR:)) Dataset &=dsin. does not exist.;
        %return;
    %end;

    %* Define output dataset;
    %if %sysevalf(%superq(dsout)=,boolean) or &dsin. eq &dsout. %then %do;
        %let dsout=&dsin.;
        %if &silent. ne Y %then %put %sysfunc(cats(NO,TICE:)) DSOUT==DSIN, &=dsin.;
    %end;
    
    data __compressds01;
        set &dsin.
            (
                %if not %sysevalf(%superq(vars)=,boolean) %then %do;
                    keep=&vars.;
                %end;
                %if not %sysevalf(%superq(exclude_vars)=,boolean) %then %do;
                    drop=&exclude_vars.;
                %end;
                obs=1
            )
        ;
    run;
    
    %local dsid rc nobs nvars __vars_to_modify i;
    %let __vars_to_modify=;
    %let dsid = %sysfunc(open(__compressds01));
    %let nobs = %sysfunc(attrn(&dsid., NOBS));
    %let nvars = %sysfunc(attrn(&dsid., NVARS));
    %do i = 1 %to &nvars.;
        %if %sysfunc(vartype(&dsid., &i.)) eq C %then %let __vars_to_modify = 1;
    %end;
    %let rc = %sysfunc(close(&dsid.));
    
    %if &__vars_to_modify. eq 1 %then %do;
        data _null_;
            set __compressds01(keep=_character_);
            length _____vars $32767;
            array ____vars(*) $ _character_;
            do i = 1 to dim(____vars) - 1;
                _____vars = catx(' ', _____vars, quote(vname(____vars(i)))||'n');
            end;
            call symputx('__vars_to_modify', _____vars);
            call symputx('nvars', i-1);
        run;
    %end;
    %do i = 1 %to &nvars.;
        %local __len&i;
    %end;
    proc datasets nolist library=work;
        delete __compressds01;
        run;
    quit;
    %local nothingtodo;
    %let nothingtodo = 0;
    %if &nobs. eq 0 or &nvars. eq 0 %then %let nothingtodo = 1;

    %* make a copy if dsin ne dsout.;
    %if &dsin. ne &dsout. %then %do;
        data &dsout.;
    %end;
    %else %do;
        data _null_;
    %end;
        set &dsin. end=__eof;
    %if &nothingtodo. %then %do;
        %if &silent. ne Y %then %put %sysfunc(cats(NO,TICE:)) nothing else to do.;
    %end;
    %else %do;
        array __vars_to_modify {*} $ &__vars_to_modify.;
        array __lens{*} %do i=1 %to &nvars; __len&i %end; ;
    
        %* Minimum length for blank variables is 1 *;
        retain %do i=1 %to &nvars; __len&i %end; 1;
        drop %do i=1 %to &nvars; __len&i %end; __k;
    
        do __k = 1 to dim(__vars_to_modify);
            __lens[__k] = max(__lens[__k], length(trim(__vars_to_modify[__k])));
        end;
    
        if __eof then do;
            drop __t;
            length __t $32767;
            do __k = 1 to dim(__vars_to_modify);
                __t = catx(',', __t, quote(vname(__vars_to_modify(__k)))||'n char('||strip(put(__lens[__k], best.))||')');
            end;
            call symputx('__vars_to_modify', __t);
        end;
    %end;
    run;
    
    %if &nothingtodo. %then %do;
        %if &silent. ne Y %then %put %sysfunc(cats(NO,TICE:)) nothing to do.;
        %return;
    %end;

    %* Set var length to maximum value lenght*;
    proc sql noprint;
        alter table &dsout.
            modify &__vars_to_modify.;
        ;
    quit;

    %exit:
%mend compressds;
/* Usage example:
options mprint;
data a;
length b 'as"das, d'n $20;
b =' 1235646444';
c  = 1;
'as"das, d'n = "123 41";
keep c;
output;
output;
run;
%compressds(dsin=a,dsout=b);
%compressds(dsin=b);
/**/