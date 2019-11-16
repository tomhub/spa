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
# Description
Setup the project environment area
md*
*******************************************************************************/

%macro setup;

    %* set preferred environment options *;
    options
        ls=max nocenter nodate nonumber
        mprint
        %if &SYSPROCESSNAME. ne %str(Wpslinks Server) %then %do;
            spool
        %end;
        missing = ' '
        nobyline
        pageno=1
        papersize=LETTER
        orientation=landscape
        leftmargin=%sysevalf(3/4)in
        rightmargin=%sysevalf(3/8)in
        topmargin=%sysevalf(3/8)in
        bottommargin=%sysevalf(3/8)in
    ;
    
    %* be clear what the environment is;
    %put _all_;
    
    %*md
    ## Setup the global macro variables:
      * g_path_root: root directory for spa
      * g_path_tmp: temporary location to be used for garbage/intermediate stuff
      * g_path_tlfs: root directory for tlfs
      * g_pgmname: program name that is been executed (it seems Wpslinks Server does not provide this automatically).
    md*;
    
    %global g_path_tmp g_path_root g_path_tlfs g_pgmname;
    
    %* work (temporary) path - expected to be cleaned up upon session clean exit.
      Probably, does not guarantee privacy, security, nor cleaning up.
    ;

    %let g_path_tmp = %sysfunc(pathname(work));
    
    %* root path (g_path_root) - location and name of program being executed;
    
    %if &SYSPROCESSNAME. eq %str(Wpslinks Server) or 1 %then %do;
        %* default;
        %* so this is WPS process: can find root path, but the WPS server
           needs options to be updated:
           Local Server->
               Properties->
                   Code Submission->
                       [Y] Set working directory to program directory on code submission
        ;
        %local fr rc libname;
        %let rc = %sysfunc(libname(_setup, ));
        %let g_path_root = %sysfunc(pathname(_setup));
        %let rc = %sysfunc(libname(_setup));
    %end;
    
    %* neither programs[\/|\\]?$, nor /programs/macros[\/\\]?$ is valid root - remove this suffix;
    %let g_path_root = %sysfunc(prxchange(s/([\\\/]programs[\\\/]?(macros[\\\/]?)?)$//i, 1, %str(&g_path_root)));
        
    %* get the program submitted;
    %if &SYSPROCESSNAME. eq %str(Wpslinks Server) %then %do;
        %* It seems currently WPS Server (Community Licence) does not reveal a program name it has.
        In SAS, this could be sysin option or something else.
        For WPS Server, expect the programs to update this value by themselves.
        *;
        %let g_pgmname=%str(Wpslink Server);
    %end;
    %else %do;
        %put %sysfunc(cats(ER,ROR:)) update me: &=SYSPROCESSNAME.;        
    %end;
    
    %let g_path_tlfs = &g_path_root./tlfs;
    
    %put &=g_path_root;
    %put &=g_path_tmp;
    %put &=g_path_tlfs;
    
    %*md
    * Setup libraries.
    md*;
    %setup_libnames;
    
    %*md
    * Setup miscalenous things.
    md*;
    %setup_misc;
    
    %exit:
%mend setup;
/** Example call:
%setup;
%put &=g_path_root;
*/


