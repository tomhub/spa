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
Run OS/programs outside SAS, pipe any output back. Submit a single command or 
submit multiple commands
md*
*******(***********************************************************************/
%macro batchrun(
    cmd=        /*command to run, dsin will be ignored: command length could be limited.*/
    ,dsin=      /*if cmd is missing, dsin is expected to have CMD variable with commands to run.*/
    ,interpreter= /*interpreter to use for the commands, ex. bash or perl or python. Applicable only when &dsin. is being used.*/
    ,dsout=     /*if &dsout. is missing then the output will be put in the log, otherwise stored in the dataset &dsout.*/
    ,silent=Y   /*if ne Y, then be more verbose*/
);
    %if %sysevalf(%superq(cmd)=,boolean) and %sysevalf(%superq(dsin)=,boolean) %then %do;
        %put %sysfunc(cats(ER,ROR:)) CMD and DSIN are both empty, one is expected.;
        %return;
    %end;
    
    %if %sysevalf(%superq(dsout)=,boolean) %then %do;
        %if &silent. ne Y %then %do;
            %put %sysfunc(cats(NO,TICE:)) DSOUT is blank, output from the command directed into the log.;
        %end;
        %let dsout = _NULL_;
    %end;
    
    %if not %sysevalf(%superq(cmd)=,boolean) %then %do;
        filename _fcmdrun pipe "%quote(&cmd.) 2>&1";
    %end;
    %else %do;
        %if not %sysfunc(exist(&dsin.)) %then %do;
            %put %sysfunc(cats(ER,ROR:)) &=DSIN. does not exist.;
            %return;
        %end;
        
        %local dsid cmdvar rc cmdvartype bom_opt;
        %let dsid = %sysfunc(open(&dsin.));
        %let cmdvar = %sysfunc(varnum(&dsid., cmd));
        %if &cmdvar. > 0 %then %do;
            %let cmdvartype = %sysfunc(vartype(&dsid., &cmdvar.));
        %end;
        
        %let rc = %sysfunc(close(&dsid.));
        
        %if &cmdvar. < 1 %then %do;
            %put %sysfunc(cats(ER,ROR:)) &=dsin. does not have CMD variable.;
            %return;
        %end;
        %else %if &cmdvartype. ne C %then %do;
            %put %sysfunc(cats(ER,ROR:)) &=dsin. CMD variable is not character: &=cmdvartype.;
            %return;
        %end;
        
        %local ext;
        %let ext=;
        %let bom_opt=;
        %if %sysevalf(%superq(interpreter)=,boolean) %then %do;
            %if &sysscpl. eq X64_WIN10PRO %then %do;
                %let bom_opt = %sysfunc(getoption(bomfile));
                %if &silent. ne Y %then %do;
                    %put %sysfunc(cats(NO,TICE:)) no INTERPRETER given and this seems to be windows: run commands as batch file.;
                %end;
                %let ext = .bat;
                %let interpreter=;
                %if %upcase(&bom_opt.) eq NOBOMFILE %then %do;
                    %let bom_opt=;
                %end;
            %end;
            %else %do;
                %put %sysfunc(cats(ER,ROR:)) &=sysscpl. not implemented.;
            %end;
        %end;
        %else %do;
            %put %sysfunc(cats(ER,ROR:)) &=interpreter. not implemented.;
            %return;
        %end;

        %if not %sysevalf(%superq(bom_opt)=,boolean) %then %do;
            option nobomfile;
        %end;
        filename _fcmdrun "%sysfunc(pathname(work))/batchrun&ext.";
        data _null_;
            set &dsin.;
            file _fcmdrun lrecl=32767;
            put cmd;
        run;
        filename _fcmdrun;
        filename _fcmdrun pipe %sysfunc(quote(&interpreter."%quote(%str(%sysfunc(pathname(work))/batchrun&ext.))" 2>&1));
        %if not %sysevalf(%superq(bom_opt)=,boolean) %then %do;
            option &bom_opt.;
        %end;
    %end;
    
    data &dsout.;
        infile _fcmdrun lrecl=max;
        input;
        %if &silent. ne Y or %upcase(&dsout.) eq _NULL_ %then %do;
            %if &silent. ne Y %then %do;
                %put %sysfunc(cats(NO,TICE:)) reading from command pipe:;
            %end;
            put _infile_;
        %end;
        %if %upcase(&dsout.) ne _NULL_ %then %do;
            length cmdlog $32767;
            cmdlog = _infile_;
        %end;
    run;

    filename _fcmdrun;
%mend batchrun;

data testcmd;
    length cmd $32767;
    cmd = "@echo off";
    output;
    cmd = "uptime";
    output;
    cmd = "netstat -a";
    output;
run;

%batchrun(
    dsin=testcmd
);
