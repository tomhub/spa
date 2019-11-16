options mautosource sasautos=("macros/" sasautos);
%setup;
title "%sysfunc(time(),e8601tm.)";

%* If this is WPS, then set prorgam name manually. *;
%let g_pgmname=Program2.sas;


libname sdxml xml "&g_path_root./data/sdtm/define.xml"
    access=readonly
    xmlmap="&g_path_root./data/misc/define.xmlv2.0.map.xml"
;
*proc datasets library=sdxml details;
run;

ods html style=default file="&g_path_tmp./test.html";
*proc print data=sdxml.datasets width=min label;
run;

proc print data=sdxml.ItemDefs width=min label;
run;
ods html close;

data a;
    set sdxml.CODELISTS;
run;




/**/