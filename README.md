# spa
SAS Programming Area (for SAS Language)

This is intended for blank, single projects.

## Usage:
* Clone repository
* Update programs/macros/setup.sas (and other setup*.sas files as necessary for the project)
* data/misc/define20map.xml - an XML map to access define.xml v2.0 data through libname xml engine
 

# Playground rules (which are nice to follow, but..):
  * 4 spaces to indent, UTF-8 encoding (no tabs)
  * No code obscuring, hiding in the log.
  * No compiled macros without source code.
  * Macros updates/new features: backward compatible (if possible)
  * Macros to declare %local or %global macro variable scape, use named macro parameters instead of positional (unless it is necessary), 
  * Macros to not change options (unless, user expects macro to be changing options, i.e. data processing or reporting macros should not change mprint mlogic etc. options)
  * User defined log messages:
    * ERROR: (use put 'ER' 'ROR: ' or %put %sysfunc(cats(ER,ROR:)) for unexpected program path etc or detected issue)
    * WARNING: (use put 'WA' 'RNING: ' or %put %sysfunc(cats(WA,RNING:)) for correct program path, but most likely not expected, or deviated from expected
    * NOTICE: (use put 'NO' 'TICE: ' or %put %sysfunc(cats(NO,TICE:)) for debug or information
    * NOTE: only by SAS/WPS itself.
  * Nice to have:
    * When not running in batch, produce all outputs into "work", so that actual outputs aren't modified until the program is batch submitted and log files are saved

# TODO:
  * Prepare metadata for TLFs (titles/footnotes etc.) and datasets (dependencies?)
  * Prepare python script to output <filename>.md if it contains "*md ... md*;" comments.
  * Log parser..

# Disclaimer
Not affiliated with:
  * CDISC (www.cdisc.org)
  * SAS(R) (www.sas.com)
  * World Programming (www.worldprogramming.com)
