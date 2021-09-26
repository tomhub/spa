/*******************************************************************************
Copyright (c) 2019-2021 Tomas Demčenko

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
Opens define.xml and imports into datasets
md*
*******************************************************************************/
%macro readDefineXML(
    filename=       /*Full path and filename, quoted */
    ,libout=work    /*library to use as define output datasets*/
    ,forceUpdate=N  /*if N, the target datasets are only read if date/time of define.xml is after the dataset or dataset is missing*/
    ,xmlmap="%sysfunc(pathname(mi))\define20map.xml" /*Full path to define.xml map, also quoted*/
    ,silent=Y   /*if ne Y then more verbose log*/
    ,prefix=_def_   /*prefix to give to define.xml datasets*/
    ,compressds=Y   /*Y/N: compress datasets after importing (minimize char var lenghts)*/
);

    %put %sysfunc(cats(NO,TICE:)) &=xmlmap.;
    %local rc fid xmlcreatedt xmlmodifydt _fid_readDefineXML;
    %let rc = %sysfunc(filename(_fid_readDefineXML, %str(&filename.)));

    %if &rc. ne 0 %then %do;
        %put %sysfunc(cats(ER,ROR:)) could not reference: &=filename.;
        %if &silent. ne Y %then %do;
            %put %sysfunc(cats(ER,ROR:)) &=rc. &=sysfilrc.;
        %end;
        %return;
    %end;
    
    %if %sysevalf(%superq(libout)=,boolean) %then %do;
        %if &silent. ne Y %then %do;
            %put %sysfunc(cats(NO,TICE:)) setting LIBOUT=WORK.;
            %let libout=work.;
        %end;
    %end;
    %else %do;
        %let libout = &libout..;
    %end;

    %let fid = %sysfunc(fopen(&_fid_readDefineXML.,i));
    %if &fid. eq 0 %then %do;
        %put %sysfunc(cats(ER,ROR:)) could not open: &=filename.;
        %if &silent. ne Y %then %do;
            %put %sysfunc(cats(ER,ROR:)) &=fid. &=sysfilrc. &=_fid_readDefineXML.;
            %put %sysfunc(cats(ER,ROR:)) &=filename.;
        %end;
        %let rc = %sysfunc(filename(_fid_readDefineXML));
        %return;
    %end;
    
    %let xmlcreatedt = %sysfunc(finfo(&fid, Create Time));
    %let xmlmodifydt = %sysfunc(finfo(&fid, Last Modified));
    
    %if &silent. ne Y %then %do;
        %put %sysfunc(cats(NO,TICE:)) &=filename.;
        %put %sysfunc(cats(NO,TICE:)) &=xmlcreatedt. &=xmlmodifydt.;
    %end;
    
    %let rc = %sysfunc(fclose(&fid.));
    
    %* access to define.xml;
    libname _____def xmlv2
        &filename.
         access=readonly
         xmlmap=&xmlmap.
    ;
    
    %local listXMLDatasets;
    %let listXMLDatasets=datasets dsitems itemdefs codelists codelistsenum valuelistdef;
    %local i dsname dsmodifydt dsid;
    %let i = 1;
    %do %while(%scan(&listXMLDatasets., &i., %str( )) ne %str());
        %let dsname = %scan(&listXMLDatasets., &i., %str( ));
        %if %sysfunc(exist(&libout.&prefix.&dsname.)) %then %do;
            %let dsid = %sysfunc(open(&libout.&prefix.&dsname.));
            %let dsmodifydt = %sysfunc(attrn(&dsid., MODTE));
            %let rc = %sysfunc(close(&dsid.));
            
            %if &silent. ne Y %then %do;
                %put %sysfunc(cats(NO,TICE:)) &prefix.&dsname= last modified date: %sysfunc(putn(&dsmodifydt., e8601dt.));
            %end;
        %end;
        %else %do;
            %let dsmodifydt =;
        %end;
        
        %if %upcase(&forceUpdate.) eq Y or %sysevalf(%superq(dsmodifydt)=,boolean) or &dsmodifydt. lt %mdtc2dt(dtc=&xmlmodifydt.) %then %do;
            data &libout.&prefix.&dsname.;
                set _____def.&dsname.;
            run;

            %if &compressds. eq Y %then %do;
                %compressds(dsin=&libout.&prefix.&dsname.);
            %end;

            %if %upcase(&dsname.) eq CODELISTS or %upcase(&dsname.) eq CODELISTSENUM %then %do;
                proc datasets nolist library=%sysfunc(compress(&libout., %str( .)));
                    modify &prefix.&dsname.;
                        index create CodeListOID;
                        index create name;
                        index create CodeListName;
                    run;
                quit;
            %end;
        %end;
        %let i = %eval(&i. + 1);
    %end;
    
    %let rc = %sysfunc(filename(_fid_readDefineXML));
    
%mend readDefineXML;
/** example:
%readDefineXML(
    filename="%sysfunc(pathname(ad))/define.xml"
    ,libout=work
    ,forceUpdate=Y
    ,silent=N
);
*/
