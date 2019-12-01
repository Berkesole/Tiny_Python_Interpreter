%{
#include <stdlib.h>
#include <stdio.h>

#include "y.tab.h"

extern int yylval;

/*  any C declaration  */
%}

letter    [a-zA-Z]

digit     [0-9]

number   {digit}+

id       {letter}({letter}|{digit})*

real     {number}'.'{number}?|{number}?'.'{number}

%%
[ \t]+      {/*do nothing , just skip */}
{number}    { 
              return INT;
            }
{real}      {
              return REAL;
            }
{id}        {
              return ID; 
            }
\"(\\.|[^\\"])*\"	{
             return(STRING_LITERAL); 
                  }
.|\n        { return yylval = yytext[0];}
%%
