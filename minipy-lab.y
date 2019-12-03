%{
   /* definition */
   #include <stdio.h>
   #include <ctype.h>
   using namespace std;
   #include <iostream>
   #include <string>
   #include <map>
  
   #include "minipy.h"

   #include "lex.yy.c"
   using namespace std;

   symbol_item* symbol_table;
   int isAssign;
%}

%token <cID>            ID
%token <string_literal> STRING_LITERAL
%token <iValue>         INT
%token <dValue>         REAL

%type <val>     add_expr
%type <val>     assignExpr
%type <val>     factor
%type <val>     atom
%type <val>     atom_expr
%type <val>     mul_expr
%type <val>     number
%type <list>    List
%type <list>    List_items
%type <str>     opt_comma

%%
Start : prompt Lines
      ;

Lines : Lines  stat '\n' prompt
      | Lines  '\n' prompt
      | 
      | error '\n' {yyerrok;}
      ;

prompt : {cout << "miniPy> ";}
       ;

stat  : assignExpr
      ;

assignExpr:
        atom_expr '=' assignExpr
      | add_expr 
      ;

number : INT
       | REAL
       ;

factor : '+' factor
       | '-' factor
       | atom_expr
       ; 

atom  : ID
      | STRING_LITERAL 
      | List 
      | number 
      ;

slice_op :  /*  empty production */
        | ':' add_expr 
        ;

sub_expr:  /*  empty production */
        | add_expr
        ;        

atom_expr : atom 
        | atom_expr  '[' sub_expr  ':' sub_expr  slice_op ']'
        | atom_expr  '[' add_expr ']'
        | atom_expr  '.' ID
        | atom_expr  '(' arglist opt_comma ')'
        | atom_expr  '('  ')'
        ;

arglist : add_expr
        | arglist ',' add_expr 
        ;
        ;      

List  : '[' ']'
      | '[' List_items opt_comma ']' 
      ;

opt_comma : /*  empty production */
          | ','
          ;

List_items  
      : add_expr
      | List_items ',' add_expr 
      ;

add_expr : add_expr '+' mul_expr
	      |  add_expr '-' mul_expr
	      |  mul_expr 
        ;

mul_expr : mul_expr '*' factor
        |  mul_expr '/' factor
	      |  mul_expr '%' factor
        |  factor
        ;

%%

void yyerror(char *s)
{
   cout << s << endl<<"miniPy> "; 
}

int yywrap()
{ return 1; }        		    

int main()
{
    symbol_table = (symbol_item*)safe_malloc(sizeof(symbol_item));
    char head[200] = "head";
    symbol_table->cID = head;
    symbol_table->next_element = NULL;
    return yyparse();
}
