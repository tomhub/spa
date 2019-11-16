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
Setup miscalenous stuff
md*
*******************************************************************************/

%macro setup_misc;
    %*md
    *Setup styles.spi001: Courier New, 8pt
    md*;
    proc template;
        define style styles.spi001/store=work.spi;
            parent = styles.minimal;
            class fonts/
                'TitleFont' = ("Courier New", 8pt)
                'TitleFont2'= ("Courier New", 8pt)
                'StrongFont' = ("Courier New", 8pt)
                'EmphasisFont'= ("Courier New", 8pt)
                'headingEmphasisFont' = ("Courier New", 8pt)
                'headingFont' = ("Courier New", 8pt)
                'docFont' = ("Courier New", 8pt)
                'footFont' = ("Courier New", 8pt)
                'FixedEmphasisFont' = ("Courier New", 8pt)
                'FixedStrongFont' = ("Courier New", 8pt)
                'FixedHeadingFont' = ("Courier New", 8pt)
                'BatchFixedFont' = ("Courier New", 8pt)
                'FixedFont' = ("Courier New", 8pt)
            ;
    
            class color_list/
                'link' = blue /*links*/
                'bgH' = white /*row and column header background*/
                'bgT' = white /*table background*/
                'bgD' = white /*data cell background*/
                'fg' = black /*text color*/
                'bg' = white /* page background color*/
            ;
    
            style Table from Output / 
                frame = hsides /* outside borders: void, box, above/below, vsides/hsides, lhs/rhs */
                rules = groups /* internal borders: none, all, cols, rows, groups */
                cellpadding = 1pt /* the space between table cell contents and the cell border */
                cellspacing = 0pt /* the space between table cells, allows background to show */
                borderwidth = 0.5pt /* the width of the borders and rules */
            ;

            style SystemFooter from SystemFooter/
                font = fonts("footFont")
            ;
    
            style Data from Data/
                background=color_list('bgD')
            ;
    
            style GraphFonts/
                'GraphDataFont' = ("Courier New", 8pt)
                'GraphUnicodeFont' = ("Courier New", 8pt)
                'GraphValueFont' = ("Courier New", 8pt)
                'GraphLabelFont' = ("Courier New", 8pt)
                'GraphFootnoteFont' = ("Courier New", 8pt)
                'GraphTitleFont' = ("Courier New", 8pt)
                'GraphTitle1Font' = ("Courier New", 8pt)
                'GraphAnnoFont' = ("Courier New", 8pt)
                'NodeDetailFont' = ("Courier New", 8pt)
                'NodeInputLabelFont' = ("Courier New", 8pt)
                'NodeLabelFont' = ("Courier New", 8pt)
                'NodeTitleFont' = ("Courier New", 8pt)
                'NodeLinkLabelFont' = ("Courier New", 8pt)
                'GraphLabel2Font' = ("Courier New", 8pt)
            ;
        end;
    run;
    
    ods path(prepend) work.spi;

    
    %exit:
%mend setup_misc;
/*%setup_misc;*/

