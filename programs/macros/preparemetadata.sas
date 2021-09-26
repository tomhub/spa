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
    Prepares metadata from define.xml into normalized structure to be used for
    forming datasets and variables
### Requirements:
    requires SAS option: validvarname=any
md*
*******************************************************************************/
%macro prepareMetadata(
    libin=      /*Input library with define.xml elements as datasets, will be WORK if missing*/
    ,libout=    /*Metadata output library, will be WORK if missing*/
    ,prefix=_def_    /*Prefix for define.xml datatsets in &LIBIN.*/
    ,silent=Y
    ,outprefix=m_   /*Output dataset prefix*/
    ,force_update=N /*If datasets are prepared, do not re-create them*/
);
    %if %sysevalf(%superq(libin)=,boolean) %then %let libin = WORK;
    %if %sysevalf(%superq(libout)=,boolean) %then %let libout = WORK;
    
    %local indsmodt datasetsmodt;
    %let datasetsmodt=;
    %let indsmodt=;
    %local rc dsid;

    %if %sysfunc(exist(&libin..&prefix.datasets)) and %sysfunc(exist(&libout..&outprefix.datasets)) %then %do;
        %let dsid = %sysfunc(open(&libin..&prefix.datasets));
        %let indsmodt = %sysfunc(attrn(&dsid., MODTE));
        %let rc = %sysfunc(close(&dsid.));

        %let dsid = %sysfunc(open(&libout..&outprefix.datasets));
        %let datasetsmodt = %sysfunc(attrn(&dsid., MODTE));
        %let rc = %sysfunc(close(&dsid.));
    %end;

    %if &force_update. eq Y or &indsmodt. gt &datasetsmodt. or &datasetsmodt. eq %str( ) %then %do;
        %* list of datasets *;
        proc sort data=&libin..&prefix.datasets out=&libout..&outprefix.datasets;
            by order;
        run;

        proc datasets nolist library=%sysfunc(compress(&libout., %str( .)));
            modify &outprefix.datasets;
                index create name;
                index create sasdatasetname;
            run;
        quit;
    %end;

    %local dsitemsmodt itemdefsmodt variablesmodt;
    
    %if %sysfunc(exist(&libout..&outprefix.variables))
        and %sysfunc(exist(&libin..&prefix.dsitems))
        and %sysfunc(exist(&libin..&prefix.itemdefs))
    %then %do;
        %let dsid = %sysfunc(open(&libin..&prefix.dsitems));
        %let dsitemsmodt = %sysfunc(attrn(&dsid., MODTE));
        %let rc = %sysfunc(close(&dsid.));

        %let dsid = %sysfunc(open(&libin..&prefix.itemdefs));
        %let itemdefsmodt = %sysfunc(attrn(&dsid., MODTE));
        %let rc = %sysfunc(close(&dsid.));

        %let dsid = %sysfunc(open(&libout..&outprefix.variables));
        %let variablesmodt = %sysfunc(attrn(&dsid., MODTE));
        %let rc = %sysfunc(close(&dsid.));
    %end;
 
    %if &force_update. eq Y
        or &variablesmodt. eq %str( )
        or &variablesmodt. lt &dsitemsmodt.
        or &variablesmodt. lt &datasetsmodt.
        or &variablesmodt. lt &itemdefsmodt.
    %then %do;
        %* dataset items=variables. Some variables are VLM, so VLM will need to be loaded also ;
        data &libout..&outprefix.variables;
            set &libin..&prefix.dsitems;
            if _N_ eq 1 then do;
                if 0 then set &libout..&outprefix.datasets(keep=order name dslabelen rename=(order=dsorder name=dsname));
                declare hash hdatasets(dataset:"&libout..&outprefix.datasets(rename=(order=dsorder name=dsname))");
                hdatasets.defineKey('OID');
                hdatasets.defineData('DSORDER', 'DSNAME', 'DSLABELEN');
                hdatasets.defineDone();
                
                if 0 then set &libin..&prefix.itemdefs(keep=oid name datatype length significantDigits SASFieldName 'def:displayFormat'n ItemDescriptionEN CodeListOID ValueListOID Origin OriginDescriptionEN rename=(oid=itemoid name=varname));
                declare hash hitems(dataset:"&libin..&prefix.itemdefs(rename=(oid=itemoid name=varname))");
                hitems.defineKey('ITEMOID');
                hitems.defineData('VARNAME', 'DATATYPE', 'LENGTH', 'SIGNIFICANTDIGITS', 'SASFIELDNAME', 'DEF:DISPLAYFORMAT', 'ITEMDESCRIPTIONEN', 'CODELISTOID', 'VALUELISTOID', 'ORIGIN', 'ORIGINDESCRIPTIONEN');
                hitems.defineDone();
            end;
            
            drop _rc;
            _rc = hdatasets.find();
            if _rc ne 0 then do;
                put 'WA' "RNING: OID not found in &libout..&outprefix.datasets:" oid=;
                call missing(dsorder, dsname, dslabelen);
            end;
            
            _rc = hitems.find();
            if _rc ne 0 then do;
                put 'WA' "RNING: ITEMOID not found in &libin..&prefix.itemdefs: " itemoid=;
                call missing(varname, datatype, length, significantdigits, sasfieldname, 'def:displayformat'n, itemdescriptionen, codelistoid, valuelistoid, origin, origindescriptionen);
            end;
        run;

        proc datasets nolist library=%sysfunc(compress(&libout., %str( .)));
            modify &outprefix.variables;
                index create varname;
                index create itemoid;
                index create sasfieldname;
                index create dsnamevarname=(dsname varname);
                index create dsnamefieldname=(dsname sasfieldname);
                index create dsfivar=(dsname sasfieldname varname);
            run;
        quit;
    %end;

%mend prepareMetadata;
/*
%prepareMetadata(
    libin=work
    ,libout=work
    ,prefix=ad_
    ,outprefix=ma_
);
*/

