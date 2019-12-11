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

assignExpr  : atom_expr '=' assignExpr {
                                            if ($1->type == Identify) {
                                                if ($3->type != Identify) {
                                                    symbol_item* item = (symbol_item*)safe_malloc(sizeof(symbol_item));
                                                    item->cID = $1->cID;
                                                    item->stype_items = (stype*)safe_malloc(sizeof(stype));
                                                    copy_stype($3, item->stype_items);
                                                    item->next_element = NULL;
                                                    symbol_item* temp = symbol_table;
                                                    int flag = 0;
                                                    //标识是否$1标识符已经在符号表中
                                                    if(!temp) {
                                                        temp = item;
                                                    } else {
                                                        while(temp->next_element) {
                                                            temp = temp->next_element;
                                                            if(!strcmp(temp->cID,$1->cID)) {
                                                                //已经存在
                                                                flag = 1;
                                                                break;
                                                            }
                                                        }
                                                        if(!flag) {
                                                            temp->next_element = item;
                                                        } else {
                                                            free(temp->stype_items);
                                                            temp->stype_items = item->stype_items;
                                                        }  
                                                    }
                                                } else {
                                                    symbol_item* temp = symbol_table;
                                                    stype* temp2;
                                                    int flag = 0;
                                                    while(temp) {
                                                        if(!strcmp(temp->cID, $3->cID)) {
                                                            //同一个标识符
                                                            temp2 = temp->stype_items;
                                                            flag = 1;
                                                            break;
                                                        }
                                                        temp = temp->next_element;                                            
                                                    }
                                                    if(flag == 0) {
                                                        //cout<<$3->cID<<"is";
                                                        yyerror("Not defined");
                                                    }
                                                    symbol_item* item = (symbol_item*)safe_malloc(sizeof(symbol_item));
                                                    item->cID = $1->cID;
                                                    item->stype_items = new stype();
                                                    item->stype_items->type = temp2->type;
                                                    switch(temp2->type) {
                                                        case Int:
                                                            item->stype_items->iValue = temp2->iValue;
                                                            break;
                                                        case Double:
                                                            item->stype_items->dValue = temp2->dValue;
                                                            break;
                                                        case String:
                                                            item->stype_items->string_literal = (char*)safe_malloc(sizeof(temp2->string_literal));
                                                            strncpy(item->stype_items->string_literal, temp2->string_literal, strlen(temp2->string_literal));
                                                            break;
                                                        case MyList:
                                                            item->stype_items->new_List = temp2->new_List;
                                                            break;
                                                        default:
                                                            ;
                                                    }
                                                    //item->stype_items = &(temp2); //悬空引用了，需要大改成stype*
                                                    item->next_element = NULL;
                                                    temp = symbol_table;
                                                    flag = 0;//重置
                                                    if(!temp) {
                                                        temp = item;
                                                    } else {
                                                        while(temp->next_element) {
                                                            temp = temp->next_element;
                                                            if(!strcmp(temp->cID,$1->cID))
                                                                {
                                                                //已经存在
                                                                flag = 1;
                                                                break;
                                                            }
                                                        }
                                                        if(!flag) {
                                                            temp->next_element = item;
                                                        } else {
                                                            free(temp->stype_items);
                                                            temp->stype_items = item->stype_items;
                                                        }
                                                    }

                                                }
                                                $$ = $3;
                                                isAssign = 0;
                                            } 
                                            else if($1->type == List_element)
                                            {
                                                stype* t = $1;
                                                cList* temp_List = $1->new_List;
                                                //cList* temp_List = analysis_ListElement($1);
                                                if(temp_List != NULL)
                                                {
                                                    if($3->type == Identify)
                                                    {
                                                        symbol_item* temp_sys = Search_Symbol($3->cID);
                                                        if(temp_sys == NULL)
                                                        {
                                                            yyerror("Not defined");
                                                        } 
                                                        else
                                                        {
                                                            if(temp_List->type == String)
                                                            {
                                                                free(temp_List->string_literal);
                                                            }
                                                            else if(temp_List->type == MyList)
                                                            {
                                                                //free_cList(temp_List->new_List);
                                                            }
                                                            stype* temp_stype = temp_sys->stype_items;
                                                            temp_List->type = temp_stype->type;
                                                            switch(temp_stype->type)
                                                            {
                                                                case Int: temp_List->integer = temp_stype->iValue;break;
                                                                case Double: temp_List->float_number = temp_stype->dValue;break;
                                                                case String: 
                                                                    temp_List->string_literal = (char*)safe_malloc(sizeof(temp_stype->string_literal));
                                                                    strncpy(temp_List->string_literal, temp_stype->string_literal, strlen(temp_stype->string_literal));
                                                                    break;
                                                                case MyList: temp_List->new_List = temp_stype->new_List;break;
                                                                default:;
                                                            }
                                                        }
                                                    }
                                                    else
                                                    {
                                                        if(temp_List->type == String)
                                                        {
                                                            free(temp_List->string_literal);
                                                        }
                                                        else if(temp_List->type == MyList)
                                                        {
                                                            //free_cList(temp_List->new_List);
                                                        }
                                                        temp_List->type = $3->type;
                                                        switch($3->type)
                                                        {
                                                            case Int: temp_List->integer = $3->iValue;break;
                                                            case Double: temp_List->float_number = $3->dValue;break;
                                                            case String: 
                                                                temp_List->string_literal = (char*)safe_malloc(sizeof($3->string_literal));
                                                                strncpy(temp_List->string_literal, $3->string_literal, strlen($3->string_literal));
                                                                break;
                                                            case MyList: temp_List->new_List = $3->new_List;break;
                                                            default:;
                                                        }
                                                    }
                                                }
                                                isAssign = 0;
                                            }
                                            else if($1->type == MyList)
                                            {
                                                //slice
                                                stype *_stype = $1;
                                                stype *preslice = $1->head_stype;
                                                if(preslice->type == Identify)
                                                {        
                                                    symbol_item* item = Search_Symbol(preslice->cID);
                                                    preslice = item->stype_items;
                                                }
                                                if ($1->head_stype == NULL) //step == 0
                                                {
                                                    yyerror("ValueError: attempt to assign sequence size is not match extended silce size");
                                                }
                                                if($3->type == Identify)
                                                {
                                                    symbol_item *temp_sys = Search_Symbol($3->cID);
                                                    if(temp_sys == NULL)
                                                    {
                                                        yyerror("Not defined");
                                                    }
                                                    else 
                                                    {
                                                        stype *temp_stype = temp_sys->stype_items;

                                                        if(temp_stype->type == Int || temp_stype->type == Double)
                                                        {
                                                            yyerror("TypeError: can only assign an iterable");                                                          
                                                        }                                             
                                                        else if(temp_stype->type == String)
                                                        {
                                                            cList *str_clist = list(Stype2Clist($3));
                                                            int n = SizeCaculation(str_clist);//赋值list的大小
                                                            int norig = _stype->slice_index.size();      //被赋值list的大小   
                                                            
                                                            int d = n - norig; // offset
                                                            if(d < 0)
                                                            {
                                                                shl_Slice(preslice,_stype,d);
                                                                cList *start_cList = preslice->new_List;                                                                
                                                                cList *__point = str_clist;   //指向右值
                                                                for(int i = 0; i < _stype->slice_index[0]; i++) 
                                                                    start_cList = start_cList->next_element;//找到切片赋值的起始位置
                                                                for(int i = 0; i < n; i++)
                                                                {
                                                                    assign_clist(__point,start_cList);
                                                                    start_cList = start_cList->next_element;
                                                                    __point = __point->next_element; 
                                                                }                                                               
                                                            }
                                                            else if(d >= 0)
                                                            {
                                                                shr_Slice(preslice,_stype,d);

                                                                cList *start_cList = preslice->new_List;
                                                                cList *__point = str_clist;   //指向右值
                                                                for(int i = 0; i < _stype->slice_index[0]; i++) 
                                                                    start_cList = start_cList->next_element;//找到切片赋值的起始位置
                                                                for(int i = 0; i < n; i++)
                                                                {
                                                                    assign_clist(__point,start_cList);
                                                                    start_cList = start_cList->next_element;
                                                                    __point = __point->next_element;
                                                                }
                                                            }
                                                        }                                                                                                                                                                                                            
                                                        else if(temp_stype->type == MyList)
                                                        {
                                                            int n = SizeCaculation(temp_stype->new_List);//赋值list的大小
                                                            int norig = _stype->slice_index.size();      //被赋值list的大小

                                                            int d = n - norig; // offset
                                                            if(d < 0)
                                                            {
                                                                shl_Slice(preslice,_stype,d);
                                                                cList *start_cList = preslice->new_List;                                                                
                                                                cList *__point = temp_stype->new_List;   //指向右值
                                                                for(int i = 0; i < _stype->slice_index[0]; i++) 
                                                                    start_cList = start_cList->next_element;//找到切片赋值的起始位置
                                                                if(start_cList == NULL)
                                                                {
                                                                    preslice->new_List = __point;
                                                                }
                                                                else
                                                                {
                                                                    for(int i = 0; i < n; i++)
                                                                    {
                                                                        assign_clist(__point,start_cList);
                                                                        start_cList = start_cList->next_element;
                                                                        __point = __point->next_element; 
                                                                    } 
                                                                }
                                                                                                                    
                                                            }
                                                            else if(d >= 0)
                                                            {
                                                                shr_Slice(preslice,_stype,d);
                                                                cList *start_cList = preslice->new_List;
                                                                cList *__point = temp_stype->new_List;   //指向右值
                                                                for(int i = 0; i < _stype->slice_index[0]; i++) 
                                                                    start_cList = start_cList->next_element;//找到切片赋值的起始位置
                                                                for(int i = 0; i < n; i++)
                                                                {
                                                                    assign_clist(__point,start_cList);
                                                                    start_cList = start_cList->next_element;
                                                                    __point = __point->next_element; 
                                                                }
                                                            }
                                                        }                                                       
                                                    }
                                                }
                                                else 
                                                {
                                                    stype *temp_stype = $3;
                                                    if(temp_stype->type == Int || temp_stype->type == Double)
                                                    {
                                                        yyerror("TypeError: can only assign an iterable");                                                          
                                                    }
                                                    else if(temp_stype->type == String)
                                                    {                                                       
                                                        cList *str_clist = list(Stype2Clist($3));
                                                        int n = SizeCaculation(str_clist);           //赋值list的大小
                                                        int norig = _stype->slice_index.size();      //被赋值list的大小

                                                        int d = n - norig; // offset
                                                        if(d < 0)
                                                        {
                                                            shl_Slice(preslice,_stype,d);
                                                            cList *start_cList = preslice->new_List;                                                                
                                                            cList *__point = str_clist;   //指向右值
                                                            for(int i = 0; i < _stype->slice_index[0]; i++) 
                                                                start_cList = start_cList->next_element;//找到切片赋值的起始位置
                                                            for(int i = 0; i < n; i++)
                                                            {
                                                                assign_clist(__point,start_cList);
                                                                start_cList = start_cList->next_element;
                                                                __point = __point->next_element; 
                                                            }                                                               
                                                        }
                                                        else if(d >= 0)
                                                        {
                                                            shr_Slice(preslice,_stype,d);
                                                            cList *start_cList = preslice->new_List;
                                                            cList *__point = str_clist;   //指向右值
                                                            for(int i = 0; i < _stype->slice_index[0]; i++) 
                                                                start_cList = start_cList->next_element;//找到切片赋值的起始位置
                                                            for(int i = 0; i < n; i++)
                                                            {
                                                                assign_clist(__point,start_cList);
                                                                start_cList = start_cList->next_element;
                                                                __point = __point->next_element; 
                                                            }
                                                        }
                                                    }
                                                    else if(temp_stype->type == MyList)
                                                    {
                                                        int n = SizeCaculation(temp_stype->new_List);//赋值list的大小
                                                        int norig = _stype->slice_index.size();      //被赋值list的大小

                                                        int d = n - norig; // offset
                                                        if(d < 0)
                                                        {
                                                            shl_Slice(preslice,_stype,d);
                                                            cList *start_cList = preslice->new_List;
                                                            cList *__point = temp_stype->new_List;   //指向右值
                                                            for(int i = 0; i < _stype->slice_index[0]; i++) 
                                                                start_cList = start_cList->next_element;//找到切片赋值的起始位置
                                                            for(int i = 0; i < n; i++)
                                                            {
                                                                assign_clist(__point,start_cList);
                                                                start_cList = start_cList->next_element;
                                                                __point = __point->next_element; 
                                                            }                                                               
                                                        }
                                                        else if(d >= 0)
                                                        {
                                                            shr_Slice(preslice,_stype,d);
                                                            cList *start_cList = preslice->new_List;
                                                            cList *__point = temp_stype->new_List;   //指向右值
                                                            for(int i = 0; i < _stype->slice_index[0]; i++) 
                                                                start_cList = start_cList->next_element;//找到切片赋值的起始位置
                                                            for(int i = 0; i < n; i++)
                                                            {
                                                                assign_clist(__point,start_cList);
                                                                start_cList = start_cList->next_element;
                                                                __point = __point->next_element; 
                                                            }
                                                        }
                                                    } 
                                                }
                                                isAssign = 0;
                                            }
                                            else 
                                            {
                                                yyerror("can't assign to this type");
                                            }
                                        }
            | add_expr  {
                            //printAssignExpr($1);
                            $$ = $1;
                            stype* temp = $1;
                            isAssign = 1;
                        }
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
