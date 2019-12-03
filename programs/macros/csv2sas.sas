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
Macro to read CSV and import all data as character
md*
*******************************************************************************/
%macro csv2sas(
    dsout=  /*output dataset name, required*/
    ,filein=    /*input filename, required*/
    ,datarow=   /*which row to use to read in data*/
    ,varrow=    /*variable name row*/
    ,varlabelrow=   /*row with variable labels*/
    ,filenameoptions=   /*filename options to use, ex. encoding=utf8*/
);
    %if %sysevalf(%superq(dsout)=,boolean) %then %do;
        %put %sysfunc(cats(ER,ROR:)) DSOUT is required parameter.;
        %return;
    %end;
    
    %if %sysevalf(%superq(filein)=,boolean) %then %do;
        %put %sysfunc(cats(ER,ROR:)) FILEIN is required parameter.;
        %return;
    %end;
    
    %if %sysevalf(%superq(varrow)=,boolean) %then %let varrow = 0;
    %if %sysevalf(%superq(varlabelrow)=,boolean) %then %let varlabelrow = 0;
    %if %sysevalf(%superq(datarow)=,boolean) %then %let datarow = 1;

    filename _fcsvsas "&filein." &filenameoptions.;
    %* get columns, variables, and lables if any;
    proc import file=_fcsvsas out=_csv2sas01 dbms=csv replace;
        datarow=1;
        getnames=NO;
    run;

    %* get variable names: if not in csv, then use the ones from proc import,
    otherwise, use CSV data: repeat names will be suffixed with proc import
    varames, ex. 'z_var2'
   ;
    data _csv2sas02;
        dsid = open('_csv2sas01');
        nvars = attrn(dsid, 'NVARS');
        length oname varname varlabel $32767;
        do i = 1 to nvars;
            oname = varname(dsid, i);
            
            %if &varrow. > 0 %then %do;
                rc = fetchobs(dsid, &varrow.);
                if vartype(dsid, i) eq 'C' then do;
                    varname = ktrim(kleft(getvarc(dsid, i)));
                end;
                else do;
                    varname = oname;
                end;
                if missing(varname) then varname = oname;
            %end;
            %else %do;
                varname = oname;
            %end;
            
            %if &varlabelrow. > 0 %then %do;
                rc = fetchobs(dsid, &varlabelrow.);
                if vartype(dsid, i) eq 'C' then do;
                    varlabel = ktrim(kleft(getvarc(dsid, i)));
                end;
                else do;
                    call missing(varlabel);
                end;
            %end;
            %else %do;
                call missing(varlabel);
            %end;
            if length(varname) > 32 then do;
                put 'NO' 'TICE: CSV variable name length too long, truncated: ' varname=;
                varname = substr(varname, 1, 32);
                put varname=;
            end;
            if length(varlabel) > 256 then do;
                put 'NO' 'TICE: CSV variable label length too long, truncated: ' varlabel=;
                varlabel = substr(varlabel, 1, 256);
                put varlabel=;
            end;
            output;
        end;
    run;
    
    %local repeat;
    %let repeat = 1;
    %do %while(&repeat. eq 1);
        proc sql noprint;
            create table _csv2sas03 as
                select *
                    ,count(*) as n
                from _csv2sas02
                group by varname
                order by i
           ;
       quit;
   
       %let repeat = 0;
       data _csv2sas04;
           set _csv2sas03;
           if n > 1 then do;
               varname = cats(varname, '_', oname);
               if length(varname) > 32 then do;
                   put 'NO' 'TICE: too long variable name chaneged to: ' varname= oname=;
                   varname = oname;
               end;
               call symputx('repeat', '1');
           end;
           drop n;
       run;
   
       %if &repeat. eq 1 %then %do;
           proc datasets nolist;
               delete _csv2sas02;
               run;
               change _csv2sas04=_csv2sas02;
               run;
            quit;
       %end;
    %end;
    
    %local attrib input;
    data _null_;
        set _csv2sas04 end=eof;
        length attrib input $32767;
        retain attrib input;
        input = catx(' ', input, quote(ktrim(kleft(varname)))||'n $');
        attrib = catx(' ', attrib
            , 'attrib '||quote(ktrim(kleft(varname)))||'n length=$32767'
            ,ifc(not missing(varlabel), 'label='||quote(ktrim(kleft(varlabel))), trimn(' '))
            ,';'
        );
        
        if eof then do;
            call symputx('input', input);
            call symputx('attrib', attrib);
        end;
    run;
    
    data &dsout.;
        &attrib.
        infile _fcsvsas firstobs=&datarow.  missover dsd dlm=',';
        input &input.;
    run;
    filename _fcsvsas;
    
    %* compress char vars;
    %compressds(dsin=&dsout.);
    
%mend csv2sas;
/** Example call:
%csv2sas(
    dsout= test
    ,filein=&g_path_root./data/misc/_wip_test.csv
    ,datarow=2
    ,varrow=1
    ,varlabelrow=2
    ,filenameoptions=
);
*/