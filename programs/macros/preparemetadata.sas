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
    Prepares metadata from define.xml into normalized structure to be used for
    forming datasets and variables
md*
*******************************************************************************/
%macro prepareMetadata(
    libin=      /*Input library with define.xml elements as datasets, will be WORK if missing*/
    ,libout=    /*Metadata output library, will be WORK if missing*/
    ,prefix=_def_    /*Prefix for define.xml datatsets in &LIBIN.*/
    ,silent=Y
    ,outprefix=m_   /*Output dataset prefix*/
);
    %if %sysevalf(%superq(libin)=,boolean) %then %let libin = WORK;
    %if %sysevalf(%superq(libout)=,boolean) %then %let libout = WORK;
    
    %* list of datasets *;
    proc sort data=&libin..&prefix.datasets out=&libout..&outprefix.datasets;
        by order;
    run;
    
    %* dataset items=variables. Some variables are VLM, so VLM will need to be loaded also ;
    data &libout..&outprefix.variables;
        set &libin..&prefix.dsitems;
        if _N_ eq 1 then do;
            if 0 then set &libout..&outprefix.datasets(keep=order name dslabelen rename=(order=dsorder name=dsname));
            declare hash hdatasets(dataset:"&libout..&outprefix.datasets(rename=(order=dsorder name=dsname))");
            hdatasets.defineKey('OID');
            hdatasets.defineData('DSORDER', 'DSNAME', 'DSLABELEN');
            hdatasets.defineDone();
            
            if 0 then set &libin..&prefix.itemdefs(keep=oid name datatype length significantDigits SASFieldName def_displayFormat ItemDescriptionEN CodeListOID ValueListOID Origin OriginDescriptionEN rename=(oid=itemoid name=varname));
            declare hash hitems(dataset:"&libin..&prefix.itemdefs(rename=(oid=itemoid name=varname))");
            hitems.defineKey('ITEMOID');
            hitems.defineData('VARNAME', 'DATATYPE', 'LENGTH', 'SIGNIFICANTDIGITS', 'SASFIELDNAME', 'DEF_DISPLAYFORMAT', 'ITEMDESCRIPTIONEN', 'CODELISTOID', 'VALUELISTOID', 'ORIGIN', 'ORIGINDESCRIPTIONEN');
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
            call missing(varname, datatype, length, significantdigits, sasfieldname, def_displayformat, itemdescriptionen, codelistoid, valuelistoid, origin, origindescriptionen);
        end;
    run;

%mend prepareMetadata;
/*
%prepareMetadata(
    libin=work
    ,libout=work
    ,prefix=ad_
    ,outprefix=ma_
);
*/
