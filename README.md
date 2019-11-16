# spa
Statistical Programming Area for SAS Language

This is intended for individual projects.

## 


# Playground rules (which are nice to follow, but :
  * 4 spaces to indent, UTF-8 encoding (no tabs)
  * No code obscuring, hiding in the log.
  * No compiled macros without source code.
  * Macros updates/new features: backward compatible (if possible)
  * Macros to declare %local or %global macro variable scape, use named macro parameters instead of positional (unless it is necessary), 
  * Macros to not change options (unless, user expects macro to be changing options, i.e. data processing or reporting macros should not change mprint mlogic etc. options)
  * User defined log messages:
    * ERROR: (use put 'ER' 'ROR: ' or %put %sysfunc(cats(ER,ROR:)) for unexpected program path etc or detected issue)
    * WARNING: (use put 'WAR' 'NING: ' or %put %sysfunc(cats(WAR,NING:)) for correct program path, but most likely not expected, or deviated from expected
    * NOTICE: (use put 'NOT' 'ICE: ' or %put %sysfunc(cats(NOT,ICE:)) for debug or information
    * NOTE: only by SAS/WPS itself.

# TODO:
  * Read define.xml to get dataset/variable/codelist metadata ondemand
  * Shape dataset based on define.xml metadata (dataset label, variable name/label/order/type/display format etc.)
  * Prepare metadata for TLFs (titles/footnotes etc.) and datasets (dependencies?)
  * Prepare python script to output <filename>.md if it contains "*md ... md*;" comments.
  * Log parser..

# Disclaimer
Not affiliated with:
  * CDISC (www.cdisc.org)
  * SAS(R) (www.sas.com)
  * World Programming (www.worldprogramming.com)
