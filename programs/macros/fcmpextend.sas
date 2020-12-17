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
PROC FCMP functions and subroutines
### Change Log:
2020-12-17 added rmcatxdups()
md*
*******************************************************************************/

%macro fcmpextend(init=once, outlib=work.fcmpextend.spa);

    %global _g_fcmpextend;
    %if &init. eq once %then %do;
        %if %sysevalf(%superq(_g_fcmpextend)=%upcase(&outlib.)) %then %goto exit;
    %end;
    
    %let _g_fcmpextend=%upcase(&outlib.);

    proc fcmp outlib=&outlib.;
    
        %* function to remove duplicates if any (from catx kind of output value);
        %* Note: leading and following spaces will be lost;
        %* Note: ordering will change to ascending;
        %* Arguments: ;
        %* dlm: delimiter string ;
        %* str: string to scan ;
        function rmcatxdups(dlm $, str $) $32767;
            if missing(str) or not index(str, strip(dlm)) then return(strip(str));

            length s0 s $32767;
            s = str;

            declare hash h(duplicate:'r',ordered:'a');
            rc = h.defineKey('s0');
            rc = h.defineData('s0');
            rc = h.defineDone();
            
            %* if dlm is missing, assume it is 1 space;
            ldlm = length(dlm);
            do while(not missing(s));
                dlm_pos = index(s, dlm);
                if dlm_pos eq 0 then do;
                    s0 = s;
                    call missing(s);
                end;
                else do;
                    s0 = substrn(s, 1, dlm_pos-1);
                    s = substrn(s, dlm_pos + ldlm);
                end;
                rc = h.ref(); %* h.check() <> 0 ? h.add() *;
            end;

            declare hiter iter("h");
            rc = iter.first();
            call missing(s);
            do while(rc eq 0);
                s = catx(dlm, s, s0);
                rc = iter.next();
            end;
            return(strip(s));
        endsub;
    run;
    quit;

    options cmplib=%scan(&outlib., 1, %str(.)).%scan(&outlib., 2, %str(.));

    %exit:
%mend fcmpextend;

/* Usage example:
%fcmpextend;

data _null_;
    str = rmcatxdups('!', catx('!', 'one', 'two', three', 'two', 'three', 'one', 'four', 'five'));
run;   

/**/
