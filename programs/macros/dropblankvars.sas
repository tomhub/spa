/*******************************************************************************
Copyright (c) 2020 Tomas Demčenko

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
Find and drop blank variables. Uses hashes to (probably) increase efficiency/speed.
md*
*******************************************************************************/
%macro dropEmptyVars(
    dsin=       /*input dataset, required*/
    ,dsout=     /*optional*/
    ,exclude=   /*variables to exclude, space separated*/
    ,silent=Y   /*if N then more verbose messages in the log*/
);
    %local dsid rc nobs nvars;

    %let dsid = %sysfunc(open(&dsin.));
    %let nobs = %sysfunc(attrn(&dsid.,nobs));
    %let nvars = %sysfunc(attrn(&dsid.,nvars));
    %let rc = %sysfunc(close(&dsid.));

    %if %sysevalf(%superq(dsout)=,boolean) %then %do;
        %let dsout = %scan(%superq(dsin), 1, %str(%());
        %if &silent. ne Y %then %put %sysfunc(cats(NO,TICE:)) [&sysmacroname.] output dataset set to: &dsout.;
    %end;

    %if &nobs. eq 0 %then %do;
        %* nothing to do, nothing to proceed;
        %if &silent. ne Y %then %put %sysfunc(cats(NO,TICE:)) [&sysmacroname.] &=dsin. got 0 obs, nothing to drop.;
        %nothingtodo:
        data &dsout.;
            set &dsin.;
        run;
        %return;
    %end;

    %if not %sysevalf(%superq(exclude)=,boolean) %then %let exclude = %qupcase(%str(&exclude.));
    
    %let dsid = %sysfunc(open(&dsin.));
    %local i vchars vnums nvchars nvnums;
    %let vchars = ;
    %let nvchars = 0;
    %let vnums = ;
    %let nvnums = 0;

    %do i = 1 %to &nvars.;
        %if %sysfunc(indexw(%upcase(%str(&exclude.)), %sysfunc(varname(&dsid., &i.)))) eq 0 %then %do;
            %if %sysfunc(vartype(&dsid., &i.)) eq C %then %let vchars = &vchars. %sysfunc(varname(&dsid., &i.));
            %else %let vnums = &vnums. %sysfunc(varname(&dsid., &i.));
        %end;
    %end;

    %let nvchars = %sysfunc(countw(&vchars.));
    %let nvnums = %sysfunc(countw(&vnums.));
    %let rc = %sysfunc(close(&dsid.));

    %if nvchars eq 0 and nvnums eq 0 %then %do;
        %if &silent. ne Y %then %put %sysfunc(cats(NO,TICE:)) [&sysmacroname.] all vars in excluded= list, nothing to drop.;
        %goto nothingtodo;
    %end;

    data _null_;
        set &dsin. end=_____eof;
        length _______v $32; %* variable name to store;
        array _______c(*) $ &vchars.;
        array _______n(*) &vnums.;

        if _N_ eq 1 then do;
            %if &nvchars. > 0 %then %do;
                declare hash ______hc(); %* character variable position in _______c(*);
                ______hc.defineKey('_______p');
                ______hc.defineData('_______p');
                ______hc.defineDone();
                do _______p = 1 to dim(_______c);
                    ______hc.add();
                end;
                declare hiter _____hic('______hc');
            %end;

            %if &nvnums. > 0 %then %do;
                declare hash ______hn(); %* numeric variable position in _______n(*);
                ______hn.defineKey('_______p');
                ______hn.defineData('_______p');
                ______hn.defineDone();
                do _______p = 1 to dim(_______n);
                    ______hn.add();
                end;
                declare hiter _____hin('______hn');
            %end;

            declare hash ______ha(); %* stores variable names that contain at least 1 non-missing value;
            ______ha.defineKey('_______v');
            ______ha.defineData('_______v');
            ______ha.defineDone();
            
            declare hiter _____hia('______ha');
        end;

        %if &nvchars. > 0 %then %do;
            ______rc = _____hic.first();
            do while(______rc eq 0);
                if not missing(_______c(_______p)) then do;
                    _______v = vname(_______c(_______p));
                    ______ha.add();
                    ______rp = _______p; %* retain position for removal step;
                    ______rc = _____hic.next();
                    ______hc.remove(key:______rp);
                end;
                else ______rc = _____hic.next();
            end;
        %end;

        %if &nvnums. > 0 %then %do;
            ______rc = _____hin.first();
            do while(______rc eq 0);
                if not missing(_______n(_______p)) then do;
                    _______v = vname(_______n(_______p));
                    ______ha.add();
                    ______rp = _______p; %* retain position for removal step;
                    ______rc = _____hin.next();
                    ______hn.remove(key:______rp);
                end;
                else ______rc = _____hin.next();
            end;
        %end;

        if _____eof or
            (%if &nvchars. > 0 %then ______hc.num_items eq 0;
             %if &nvnums. > 0 and nvchars > 0 %then and;
             %if &nvnums. > 0 %then ______hn.num_items eq 0;
        ) then do;
            length _______f $32767;
            call missing(_______f);
            ______rc = _____hia.first();
            do while(______rc eq 0);
                _______f = catx(' ', _______f, _______v);
                ______rc = _____hia.next();
            end;
            call symputx('keep_vars', _______f);
            
            %* for debugging;
            %if &silent. ne Y %then %do;
                %local to_drop;
                %let to_drop =;
                call missing(_______f);

                if ______hc.num_items > 0 then do;
                    ______rc = _____hic.first();
                    do while(______rc eq 0);
                        _______f = catx(' ', _______f, vname(_______c(_______p)));
                        ______rc = _____hic.next();
                    end;
                end;

                if ______hn.num_items > 0 then do;
                    ______rc = _____hin.first();
                    do while(______rc eq 0);
                        _______f = catx(' ', _______f, vname(_______n(_______p)));
                        ______rc = _____hin.next();
                    end;
                end;
                call symputx('to_drop', _______f);
            %end;
            stop;
        end;
    run;
    
    data &dsout.;
        set &dsin.(keep=&exclude. &keep_vars.);
    run;

    %if &silent. ne Y %then %do;
        %put %sysfunc(cats(NO,TICE:)) [&sysmacroname.] &=dsin. variables to keep:;
        %put %sysfunc(cats(NO,TICE:)) [&sysmacroname.] &=exclude.;
        %put %sysfunc(cats(NO,TICE:)) [&sysmacroname.] &=keep_vars.;
        %put %sysfunc(cats(NO,TICE:)) [&sysmacroname.] variables dropped: &to_drop.;
    %end;
%mend dropEmptyVars;
/**
Example call:
%dropEmptyVars(
    dsin=test
    ,dsout=test_out
);
/**/
