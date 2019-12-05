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

Lines   : Lines stat '\n' prompt
        | Lines '\n' prompt
        |
        | error '\n'    {
                            yyerrok;
                        }
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

atom    : ID    {
                    stype* temp = (stype*)safe_malloc(sizeof(stype));
                    temp->type = Identify;
                    temp->cID = $1;
                    $$ = temp;
                }
        | STRING_LITERAL    {
                                stype* temp = (stype*)safe_malloc(sizeof(stype));
                                temp->type = String;
                                temp->string_literal = $1;
                                $$ = temp;
                            }
        | List  {
                    $$ = (stype*)safe_malloc(sizeof(stype));
                    $$->type = MyList;
                    $$->new_List = $1;
                }
        | number    {
                        $$ = $1;
                    }
        ;


slice_op    :  /*  empty production */
          {
            $$ = NULL;
          }
            | ':' add_expr 
            {
              $$ = $1;
            }
            ;

sub_expr:  /*  empty production */
        | add_expr
        ;        

atom_expr   : atom  {
                        $$ = $1;
                    }
            
            | atom_expr  '[' sub_expr  ':' sub_expr  slice_op ']'
            {
                $$ = (stype*)safe_malloc(sizeof(stype));
                $$->type = Splite;
                // $$->sListElement.cID = $1->sListElement.cID;

                if($1->type == Identify)
                {
                    symbol_item* item = Search_Symbol($1->cID);
                    if(!item)
                    {
                        yyerror("NameError: name is not defined");
                        goto endListElement1;
                    }
                    stype* __item = item->stype_items;

                    if(__item->type != MyList)
                    {
                        yyerror("TypeError: This object is not subscriptable");
                        $$ = $1;
                        $$->type = Error;
                        goto endListElement1;
                    }
                    $1->new_List = __item->new_List;

                    if(($3 != NULL && $3->type != Int) || ($5 != NULL && $5->type != Int) || ($6 != NULL && $6->type != Int))
                    {
                        yyerror("TypeError: slices indices must be integers, not float");
                        goto endListElement1;
                    }      

                    if($6->iValue == NULL) $6->iValue = 1;
                    if($3->iValue == NULL) $3->iValue = 0;
                    if($5->iValue == NULL) $3->iValue = Mylen($1->new_List) - 1;                    
                    vector<int> element_index = MySplite($3->iValue, $5->iValue ,$6->iValue,Mylen($1->new_List));

                    if(step == 0) 
                    {
                        yyerror("ValueError: slice step cannot be zero");
                        goto endListElement1;
                    }
                    else
                    {
                        
                    }

                }
                else if($1->type == List_element)
                {

                    if(($3 != NULL && $3->type != Int) || ($5 != NULL && $5->type != Int) || ($6 != NULL && $6->type != Int))
                    {
                        yyerror("TypeError: slices indices must be integers, not float");
                        goto endListElement1;
                    }
                    if($1->new_List->type != MyList)
                    {   
                        yyerror("TypeError: This object is not subscriptable"):
                        goto endListElement1;
                    }
                    if($6->iValue == NULL) $6->iValue = 1;
                    if($3->iValue == NULL) $3->iValue = 0;
                    if($5->iValue == NULL) $3->iValue = Mylen($1->new_List) - 1;                    
                    vector<int> element_index = MySplite($3->iValue, $5->iValue ,$6->iValue,Mylen($1->new_List));




                }
                else if($1->type == Splite)
                {    
                    if(($3 != NULL && $3->type != Int) || ($5 != NULL && $5->type != Int) || ($6 != NULL && $6->type != Int))
                    {
                        yyerror("TypeError: slices indices must be integers, not float");
                        goto endListElement1;
                    }                    

                    if($6->iValue == NULL) $6->iValue = 1;
                    if($3->iValue == NULL) $3->iValue = 0;
                    if($5->iValue == NULL) $3->iValue = Mylen($1->new_List) - 1;
                    vector<int> element_index = MySplite($3->iValue, $5->iValue ,step ,Mylen($1->new_List));

                    int step = $6->iValue;
                    cList *temp = $1->new_List;
                    cList *temp1 = $1->new_List;
                    cList *temp2 = $1->new_List;
                    cList *temp3 = temp2;
                    if(step == 0) 
                    {
                        yyerror("ValueError: slice step cannot be zero");
                        goto endListElement1;
                    }
                    else
                    {
                        int flag = 0;// a trick
                        for (int i = 0; i < element_index.size(); i++)
                        {   
                            for (int j = 0; j < element_index[i]; i++)
                            {
                                temp = temp->next_element;
                            }
                            temp1 = Copy_Slice(temp);
                            if (flag == 1) 
                                temp2->next_element = temp1;
                            else 
                            {
                                temp2 = temp1;
                                flag = 1;
                            }
                            temp2 = temp2->next_element;                                                                            
                        }
                    }
                }
                // if(1)
                // {
                //     cList* temp = $1->new_List;
                //     cList* temp_start = $1->new_List;    //起始的逻辑位置     
                //     cList* temp_end = $1->new_List;      //终止的逻辑位置       
                //     int step = 0;                        //步长         
                    // int __size__ = 0;
                    // __size__ = SizeCaculation($1->new_List); //统计list大小，用于计算负参数表达的逻辑位置
                //     // if ($3 == NULL) $3->iValue = 0;
                //     // if ($5 == NULL) $5->iValue = __size__ - 1;
                    
                //     if($6 != NULL)                       //步长初始化
                //         step = $6->iValue;
                //     else step = 1;
                //     /*负方向参数转化为正方向相对位置*/                            
                //     int __Start_index =$3->iValue + __size__;
                //     int __End_index = $5->iValue + __size__;                

                //     if($3->iValue >= 0)
                //     {
                //             for(int i = 0; i < $3->iValue; i++)
                //         {
                //             temp_start = temp->next_element;
                //             if(temp_start == NULL)
                //             {
                //                 temp_start = temp;// 最后一个结点
                //                 break;
                //             }
                //             temp = temp->next_element;
                //         }
                //     }
                //     else
                //     {
                //         for(int i = 0; i < __Start_index; i++)
                //         {
                //             temp_start = temp->next_element;
                //             if(temp_start == NULL)
                //             {
                //                 temp_start = temp;
                //                 break;
                //             }
                //             temp = temp->next_element;
                //         }
                //     }
                //     temp = $1->new_List; //重新初始化
                //     if($5->iValue >= 0)
                //     {
                //         for(int i = 0; i < $5->iValue; i++)
                //         {
                //             temp_end = temp->next_element;
                //             if(temp_end == NULL)
                //             {
                //                 temp_end = temp;
                //                 break;
                //             }
                //             temp = temp->next_element;
                //         }                       
                //     }
                //     else
                //     {
                //         for(int i = 0; i < __End_index; i++)
                //         {
                //             temp_end = temp->next_element;
                //             if(temp_end == NULL)
                //             {
                //                 temp_end = temp;
                //                 break;
                //             }
                //             temp = temp->next_element;                      
                //         }
                //     }
                //     // cout << "__Start_index = " << __Start_index << endl;
                //     // cout << "__End_index = " << __End_index << endl;
                //     // cout << temp_start->integer << endl;
                //     // cout << temp_end->integer << endl;    
                //     /***************************展开/****************************/


                //      // cList* temp3 = (cList*)safe_malloc(sizeof(cList));
                //      // temp3 = Silce_Open(temp_start,temp_end);

                //     cList* temp3 = (cList*)safe_malloc(sizeof(cList));
                //     cList* temp2 = temp_start;
                //     temp3->new_List = temp_start;
                //     cList* temp4 = temp3;
                //     int step_overflow_ = 0;
                //     if ($3->iValue < 0) step_overflow_ = __Start_index;
                //     else step_overflow_ = $3->iValue;
                //     for(int i = 0; i < step; i++)
                //     {                    
                //         temp2 = temp2->next_element;
                //         step_overflow_ = step_overflow_ + 1;
                //     }                    
                //     if (step == 0)
                //     {
                //         yyerror("ValueError: slice step cannot be zero");
                //         goto endListElement1;
                //     }
                //     /*************************正方向切片*********************************/
                //     else if(step > 0)
                //     {
                //         // cout << "S_O_ = " << step_overflow_ << endl;
                //         if(temp_start == temp_end) temp3->new_List = NULL;
                //         else                            
                //         {
                //             int flag = 0;
                //             if($5->iValue < 0) flag = __End_index;
                //             else flag = $5->iValue;
                //             while(temp2 != temp_end && temp2 != NULL && step_overflow_ < flag)
                //             {                                                            
                //                 cList* NEWLIST = (cList*)safe_malloc(sizeof(cList));
                //                 NEWLIST->new_List = temp2;
                //                 temp4->next_element = NEWLIST;
                //                 temp4 = temp4->next_element;
                //                 for(int i = 0; i < step; i++)
                //                 {                    
                //                     temp2 = temp2->next_element;
                //                     step_overflow_ = step_overflow_ + 1;
                //                 }                                                                
                //             }
                //         }
                //         if(temp2 == NULL && temp_end->next_element != NULL)
                //         {
                //             temp3->new_List = NULL;
                //         }
                //     }
                //     /*************************负方向切片,第三次重构*********************************/
                //     else 
                //     {
                //         /*链表的逆序*/
                //         cList* pre_point = NULL;//下层指针移动控制
                //         cList* next_point = $1->new_List; //指针指向原list的位置
                //         while(next_point != NULL)
                //         {
                //             cList * temp_reverse = (cList*)safe_malloc(sizeof(cList));
                //             temp_reverse = next_point;                          
                //             temp_reverse->next_element = pre_point;
                //             pre_point = temp_reverse;
                //             next_point = next_point->next_element;
                //             temp3 = temp_reverse; // 逆序的链表
                //         }

                //         /************************逆序展开************************/
                //         // cList* exchange = NULL;
                //         // exchange = temp_start;
                //         // temp_start = temp_end;
                //         // temp_end = exchange; //                   
                //         if(temp_start == temp_end) temp3->new_List = NULL;
                //         else                            
                //         {
                //             int flag = 0;
                //             if($5->iValue < 0) flag = __End_index;
                //             else flag = $5->iValue;
                //             while(temp2 != temp_end && temp2 != NULL && step_overflow_ < flag)
                //             {                                                            
                //                 cList* NEWLIST = (cList*)safe_malloc(sizeof(cList));
                //                 NEWLIST->new_List = temp2;
                //                 temp4->next_element = NEWLIST;
                //                 temp4 = temp4->next_element; 
                //                 for(int i = 0; i < step; i++)
                //                 {                    
                //                     temp2 = temp2->next_element;
                //                     step_overflow_ = step_overflow_ + 1;
                //                 }                                                               
                //             }
                //         }
                //         if(temp2 == NULL && temp_end->next_element != NULL)
                //         {
                //             temp3->new_List = NULL;
                //         }                                                               
                //     } 

                //     while (temp3 != NULL)
                //     {
                //         cout << temp3->new_List->integer << endl;
                //         temp3 = temp3->next_element;
                //     }
                //     $$->new_List = temp3;

                // }                                 
                endListElement1:
                    //free($1);
                    free($3);
                    free($5);
                    free($6);
            }
            | atom_expr  '[' add_expr ']'
            {
                $$ = (stype*)safe_malloc(sizeof(stype));
                $$->type = List_element;
                stype* temp = $$;
                if($1->type == List_element)
                {
                    //$$->sListElement.cID = $1->sListElement.cID;
                    if($3->type != Int)
                    {
                        yyerror("TypeError: list indices must be integers or slices, not float");
                        goto endListElement;
                    }
                    // $$->sListElement.place.insert($$->sListElement.place.begin(),$1->sListElement.place.begin(), $1->sListElement.place.end());
                    // $$->sListElement.place.push_back($3->iValue);

                    if($1->new_List->type!=MyList)
                    {
                        yyerror("TypeError: this object is not subscriptable");
                        goto endListElement;
                    }
                    cList* temp3 = $1->new_List->new_List;
                    for (int i = 0; i < $3->iValue; ++i)
                    {
                        temp3 = temp3->next_element;
                        if(temp3 == NULL)
                        {
                            yyerror("IndexError: list index out of range");
                            goto endListElement;
                        }
                    }
                    $$->new_List = temp3; //指针指向取出来的值
                }
                else if($1->type == Identify)
                {
                    //$$->sListElement.cID = $1->cID;
                    if($3->type != Int)
                    {
                        yyerror("TypeError: list indices must be integers or slices, not float");
                        goto endListElement;
                    }
                    // $$->sListElement.place.clear();
                    // $$->sListElement.place.push_back($3->iValue);

                    symbol_item* item = Search_Symbol($1->cID);
                    if(!item)
                    {
                        yyerror("NameError: name is not defined");
                        goto endListElement;
                    }
                    stype* temp2 = item->stype_items;
                    if(temp2->type != MyList)
                    {
                        yyerror("TypeError: this object is not subscriptable");
                        $$ = $1;
                        $$->type = Error;
                        goto endListElement;
                    }
                    cList* temp3 = temp2->new_List;
                    for (int i = 0; i < $3->iValue; ++i)
                    {
                        temp3 = temp3->next_element;
                        if(temp3 == NULL)
                        {
                            yyerror("IndexError: list index out of range");
                            goto endListElement;
                        }
                    }
                    $$->new_List = temp3; //指针指向取出来的值
                }
                else if($1->type == Splite)
                {   //双层链表结构
                    if($3->type != Int)
                    {
                        yyerror("TypeError: list indices must be integers or slices, not float");
                        goto endListElement;
                    }
                    cList* temp3 = $1->new_List;
                    for (int i = 0; i < $3->iValue; ++i)
                    {
                        temp3 = temp3->next_element;
                        if(temp3 == NULL)
                        {
                            yyerror("IndexError: list index out of range");
                            $$ = $1;
                            $$->type = Error;
                            goto endListElement;
                        }
                    }
                    $$->new_List = temp3->new_List;
                }
                endListElement:
                    //free($1);
                    free($3);
            }
            | atom_expr  '.' ID
            {
                $$ = $1;
                $$->function_name = $3;
            }
            | atom_expr  '(' arglist opt_comma ')'
            {
                const char* s1 = "append";
                const char* s2 = "print";
                const char* s3 = "len";
                const char* s4 = "list";
                if($1->function_name!=NULL)
                {
                    if(!strcmp($1->function_name,s1))
                    {
                        $$ = MyAppend($1,$3);
                    }
                }
                else
                {
                    if(!strcmp($1->cID,s2))
                    {
                        MyPrint($3);
                        $$ = $1;
                        $$->type = Error;
                    }
                    else if(!strcmp($1->cID,s3))
                    {
                        int len = Mylen($3);
                        if(len == -1)
                        {
                            $$ = $1;
                            $$->type = Error;
                        }
                        else
                        {
                            $$ = (stype*)safe_malloc(sizeof(stype));
                            $$->type = Int;
                            $$->iValue = len;
                        }
                        
                    }
                }
                
            }
            | atom_expr  '('  ')'
            {
                const char* s5 = "quit";
                if(!strcmp($1->cID,s5))
                    return 0;
            }
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
{ 
  return 1; 
}        		    

int main()
{
    symbol_table = (symbol_item*)safe_malloc(sizeof(symbol_item));
    char head[200] = "head";
    symbol_table->cID = head;
    symbol_table->next_element = NULL;
    return yyparse();
}
