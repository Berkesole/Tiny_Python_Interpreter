%{
    #include <stdlib.h>
    #include <stdio.h>
    #include "minipy-lab.tab.h"
%}

letter  [a-zA-Z]
digit   [0-9]
number  {digit}+
id      ({letter}|"_")({letter}|{digit}|"_")*
real    {number}"."{number}?|{number}?"."{number}

%%

[ \t]+              { /*do nothing , just skip */ }

{number}            { 
                        yylval.iValue = strtol(yytext, NULL, 10);
                        return INT;
                    }

{real}              {
                        yylval.dValue = strtod(yytext, NULL);
                        return REAL;
                    }

{id}                {
                        char* temp = (char*)malloc(yyleng * sizeof(char));
                        if (temp == NULL) {
                            printf("Memory not enough!\n");
                            exit(1);
                        }
                        strncpy(temp, yytext, yyleng);
                        yylval.cID = temp;
                        return ID;
                    }

\"(\\.|[^"\\])*\"   {
                        char* temp = (char*)malloc(yyleng * sizeof(char));
                        /* 不要把引号复制进来 */
                        strncpy(temp, yytext + 1, yyleng - 2);
                        yylval.string_literal = temp;
                        return(STRING_LITERAL);
                    }

.|\n                {
                        return yylval.str = yytext[0];
                    }

%%
