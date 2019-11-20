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
Converts macro character string into date/time
md*
*******************************************************************************/
%macro mdtc2dt(
    dtc=        /*Input date/time character value, */
    ,type=win01 /*win01: accepts "20:04:57 Nov 19 2019" as input */
    ,format=/*Output format*/
);
    %local res;
    %let res=;
    %* seems to be based on locale/os;
    %if %sysevalf(%superq(dtc)=,boolean) %then %do;
        %* nothing to do. *;
        %return;
    %end;
    
    %let type = %sysfunc(lowcase(&type.));
    
    %if &type. eq win01 %then %do;
        %* convert this: 20:04:57 Nov 19 2019 *;
        %let res = %sysfunc(dhms(
            %sysfunc(inputn(%sysfunc(compress(%scan(&dtc., 3, %str( ))%scan(&dtc., 2, %str( ))%scan(&dtc., 4, %str( )))), date9.))
            ,%scan(&dtc., 1, %str(: ))
            ,%scan(&dtc., 2, %str(: ))
            ,%scan(&dtc., 3, %str(: ))
        ));
    %end;
    %else %do;
        %put %sysfunc(cats(ER,ROR:)) type not found: &=type.;
        %return;
    %end;
    
    %* format result if required, or just return the value;
    %if %sysevalf(%superq(format)=,boolean) %then %do;
        &res.
    %end;
    %else %do;
        %sysfunc(putn(&res., &format.))
    %end;
%mend mdtc2dt;

/* example: 
%put %dtc2dt(dtc=20:04:57 Nov 19 2019, format=e8601dt.);
*/