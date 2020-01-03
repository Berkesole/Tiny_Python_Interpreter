%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <math.h>
    #include <ctype.h>
    #include <iostream>
    #include <map>
    #include <string>
    #include <assert.h>

    #include "minipy.h"

    #include "lex.yy.c"
    using namespace std;

    symbol_item* symbol_table;
    int isAssign;
%}

%union{
    stype*  val;            //指针
    cList*  list;
    int     iValue;
    double  dValue;
    char    str;            //字符，匹配'\n'
    char*   cID;            //标识符
    char*   string_literal; //字符串

};

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
%type <list>    arglist
%type <val>     slice_op
%type <val>     sub_expr
%%

Start   : prompt Lines
        ;

Lines   : Lines stat '\n' prompt
        | Lines '\n' prompt
        |
        | error '\n'    {
                            yyerrok;
                        }
        ;

prompt  :   {
                cout << "miniPy> " ;
            }
        ;

stat    : assignExpr    {
                            if (isAssign) {
                                printAssignExpr($1);
                                cout<<endl;
                            }
                        }
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

number  : INT   {   //stype
                    stype* temp = (stype*)safe_malloc(sizeof(stype));
                    temp->type = Int;
                    temp->iValue = $1;
                    $$ = temp;//指针
                }
        | REAL  {
                    stype* temp = (stype*)safe_malloc(sizeof(stype));
                    temp->type = Double;
                    temp->dValue = $1;
                    $$ = temp;
                    // $$.type = Double; $$.dValue = $1;
                }
        ;

factor  : '+' factor    {
                            $$ = $2;
                        }
        | '-' factor    {
                            $$ = (stype*)safe_malloc(sizeof(stype));
                            $$->type = $2->type;
                            switch ($$->type) {
                                case Int:
                                    $$->iValue = -1*$2->iValue;
                                    break;
                                case Double:
                                    $$->dValue = -1*$2->dValue;
                                    break;
                                default:
                                    ;
                                }
                            free($2);
                        }

        | atom_expr {
                        if($1->type == List_element)
                        {
                            //cList* temp_List = analysis_ListElement($1);
                            cList* temp_List = $1->new_List;
                            if(temp_List==NULL)
                                goto endFactor;
                            $$ = (stype*)safe_malloc(sizeof(stype));
                            $$->type = temp_List->type;
                            switch(temp_List->type)
                            {
                                case Int: $$->iValue = temp_List->integer;break;
                                case Double: $$->dValue = temp_List->float_number;break;
                                case String: 
                                    $$->string_literal = (char*)safe_malloc(sizeof(temp_List->string_literal));
                                    strncpy($$->string_literal, temp_List->string_literal, strlen(temp_List->string_literal));
                                    break;
                                case MyList: $$->new_List = temp_List->new_List;break;
                                default:;
                            }
                            free($1);
                        }
                        else
                        {
                            $$ = $1;
                        }
                        endFactor:
                        ;
                    }
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
                                //$$.type = String;
                                //cout<<"atom"<<endl;
                                //$$.string_literal = $1;
                                //cout<<$$.string_literal<<endl;
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
                $$ = $2;
            }
            ;

sub_expr    :  /*  empty production */
            {
                $$ = NULL;
            }
            | add_expr
            {
                $$ = $1;
            }
            ;              

atom_expr   : atom  {
                        $$ = $1;                
                    }
            
            | atom_expr  '[' sub_expr  ':' sub_expr  slice_op ']'
            {
                $$ = (stype*)safe_malloc(sizeof(stype));
                $$->type = MyList;
                // $$->sListElement.cID = $1->sListElement.cID;
                //$$->head_stype = $1;
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
                    //$1->new_List = __item->new_List;

                    if(($3 != NULL && $3->type != Int) || ($5 != NULL && $5->type != Int) || ($6 != NULL && $6->type != Int))
                    {
                        yyerror("TypeError: slices indices must be integers, not float");
                        goto endListElement1;
                    }

                    if($6 == NULL) 
                    {
                    	$6 = (stype*)safe_malloc(sizeof(stype));
                    	$6->type = Int;
                    	$6->iValue = 1;
                    }
                    if($3 == NULL)
                    {
                    	$3 = (stype*)safe_malloc(sizeof(stype));
                    	$3->type = Int;
                    	$3->iValue = 0;
                    }                    	
                    if($5 == NULL) 
                    {
                    	$5 = (stype*)safe_malloc(sizeof(stype));
                    	$5->type = Int;
						$5->iValue = SizeCaculation(__item->new_List);
					}

                    vector<int> element_index = MySplite($3->iValue, $5->iValue ,$6->iValue,SizeCaculation(__item->new_List));

                    int step = $6->iValue;
                    cList *temp = __item->new_List;
                    cList *temp1 = __item->new_List;
                    cList *temp2 = __item->new_List;
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
                        	temp = __item->new_List;
                            for (int j = 0; j < element_index[i]; j++)
                            {
                                temp = temp->next_element;
                            }
                            temp1 = Copy_Slice(temp);
                            if (flag == 1)
                            {
	                            temp2->next_element = temp1;
	                            temp2 = temp2->next_element;
                            }
                            else 
                            {
                                temp2 = temp1;
                            	temp3 = temp2;                                
                                flag = 1;
                            }                                                                            
                        }
                    }
                    if(element_index.size() != 0) $$->new_List = temp3;
                    else $$->new_List = NULL;
                    if (step == 1) $$->head_stype = $1;
                    $$->slice_index.assign(element_index.begin(),element_index.end());
                    if($3->iValue == $5->iValue) 
                    	{
                    		$$->slice_index.push_back($3->iValue);
                			$$->slice_index.push_back(0);
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
                        yyerror("TypeError: This object is not subscriptable");
                        goto endListElement1;
                    }
                    if($6 == NULL) 
                    {
                    	$6 = (stype*)safe_malloc(sizeof(stype));
                    	$6->type = Int;
                    	$6->iValue = 1;
                    }
                    if($3 == NULL)
                    {
                    	$3 = (stype*)safe_malloc(sizeof(stype));
                    	$3->type = Int;
                    	$3->iValue = 0;
                    }                    	
                    if($5 == NULL) 
                    {
                    	$5 = (stype*)safe_malloc(sizeof(stype));
                    	$5->type = Int;
						$5->iValue = SizeCaculation($1->new_List->new_List->new_List);
					}                    
                    vector<int> element_index = MySplite($3->iValue, $5->iValue ,$6->iValue,SizeCaculation($1->new_List->new_List->new_List));

                    int step = $6->iValue;
                    cList *temp = $1->new_List->new_List;
                    cList *temp1 = $1->new_List->new_List;
                    cList *temp2 = $1->new_List->new_List;
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
                        	temp = $1->new_List->new_List;
                            for (int j = 0; j < element_index[i]; j++)
                            {
                                temp = temp->next_element;
                            }
                            temp1 = Copy_Slice(temp);
                            if (flag == 1)
                            {
	                            temp2->next_element = temp1;
	                            temp2 = temp2->next_element;
                            }
                            else 
                            {
                                temp2 = temp1;
                                temp3 = temp2;
                                flag = 1;
                            }                                                                            
                        }
                    }

                    if(element_index.size() != 0) $$->new_List = temp3;
                    else $$->new_List = NULL;
                    if (step == 1) 
                    {
                		$$->head_stype = $1;
                		$$->head_stype->new_List = $$->head_stype->new_List->new_List;
                    }
                    $$->slice_index.assign(element_index.begin(),element_index.end());                  
                    if($3->iValue == $5->iValue) 
                    	{
                    		$$->slice_index.push_back($3->iValue);
                			$$->slice_index.push_back(0);
                		}
                }
                else if($1->type == MyList)
                {    
                    if(($3 != NULL && $3->type != Int) || ($5 != NULL && $5->type != Int) || ($6 != NULL && $6->type != Int))
                    {
                        yyerror("TypeError: slices indices must be integers, not float");
                        goto endListElement1;
                    }                    

                    if($6 == NULL) 
                    {
                    	$6 = (stype*)safe_malloc(sizeof(stype));
                    	$6->type = Int;
                    	$6->iValue = 1;
                    }
                    if($3 == NULL)
                    {
                    	$3 = (stype*)safe_malloc(sizeof(stype));
                    	$3->type = Int;
                    	$3->iValue = 0;
                    }                    	
                    if($5 == NULL) 
                    {
                    	$5 = (stype*)safe_malloc(sizeof(stype));
                    	$5->type = Int;
						$5->iValue = SizeCaculation($1->new_List);
					}
                    vector<int> element_index = MySplite($3->iValue, $5->iValue ,$6->iValue ,SizeCaculation($1->new_List));

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
                        	temp = $1->new_List;
                            for (int j = 0; j < element_index[i]; j++)
                            {
                                temp = temp->next_element;
                            }
                            temp1 = Copy_Slice(temp);
                            if (flag == 1)
                            {
	                            temp2->next_element = temp1;
	                            temp2 = temp2->next_element;
                            }
                            else 
                            {
                                temp2 = temp1;
                                temp3 = temp2;
                                flag = 1;
                            }                                                                            
                        }
                    }
                   
                    if(element_index.size() != 0) $$->new_List = temp3;
                    else $$->new_List = NULL;                    
                    if(step == 1) $$->head_stype = $1;
                    $$->slice_index.assign(element_index.begin(),element_index.end());
                    if($3->iValue == $5->iValue) 
                    	{
                    		$$->slice_index.push_back($3->iValue);
                			$$->slice_index.push_back(0);
                		}
                }               
                endListElement1:
                    //free($1);
                    //stype* temp = $$;
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
                    if($1->new_List->type != MyList)//&& $1->new_List->type != String)
                    {
                        yyerror("TypeError: this object is not subscriptable");
                        goto endListElement;
                    }
                    cList* temp3 = $1->new_List->new_List;
                    int num = Mylen($1->new_List);
                    if($3->iValue<0)
                        $3->iValue = $3->iValue+num;
                    for (int i = 0; i < $3->iValue; ++i)
                    {
                        temp3 = temp3->next_element;
                        if(temp3 == NULL)
                        {
                            yyerror("IndexError: list index out of range");
                            $$->type = Error;
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
                    cList* temp4 = (cList*)safe_malloc(sizeof(cList));
                    temp4->new_List = temp3;
                    temp4->type = MyList;
                    int num = Mylen(temp4);
                    if($3->iValue<0)
                        $3->iValue = $3->iValue+num;
                    for (int i = 0; i < $3->iValue; ++i)
                    {
                        temp3 = temp3->next_element;
                        if(temp3 == NULL)
                        {
                            yyerror("IndexError: list index out of range");
                            $$->type = Error;
                            goto endListElement;
                        }
                    }
                    $$->new_List = temp3; //指针指向取出来的值
                }
                else if($1->type == MyList)
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
                    $$->new_List = temp3;
                }
                endListElement:
                    //free($1);
                    free($3);
            }
            | atom_expr  '.' ID
            {
                $$ = $1;
                // if($1->type==Identify)
                // {
                //     //$$->type = Function;
                //     $$->function_name = $3->string_literal;
                // }
                $$->function_name = $3;
            }
            | atom_expr  '(' arglist opt_comma ')'
            {
                const char* s1 = "append";
                const char* s2 = "print";
                const char* s3 = "len";
                const char* s4 = "list";
                const char* s5 = "range";
                const char* s6 = "join";
                if($1->function_name!=NULL)
                {
                    if(!strcmp($1->function_name,s1))
                    {
                        $$ = MyAppend($1,$3);
                    }
                    else if(!strcmp($1->function_name,s6))
                    {
                        $$ = Myjoin($1,$3);
                    }
                    else{
                        yyerror("AttributeError: this object has not this attribute");
                    }
                }
                else
                {
                    if(!strcmp($1->cID,s2))
                    {
                        MyPrint($3);
                        $$ = (stype*)safe_malloc(sizeof(stype));
                        $$->type = None;
                        stype* temp = $$;
                    }
                    else if(!strcmp($1->cID,s3))
                    {
                        int len = Mylen($3);
                        if($3->next_element!= NULL)
                        {
                            yyerror("TypeError: len() takes exactly one argument");
                            return -1;
                        }
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
                    else if(!strcmp($1->cID,s5))
                    {
                        cList* head = (cList*)safe_malloc(sizeof(cList));
                        head->next_element = NULL;
                        head->new_List = $3;
                        //cList* temp_List = $3;
                        head->type = MyList;
                        int len = Mylen(head);
                        $$ = (stype*)safe_malloc(sizeof(stype));
                        if(len == -1)
                        {
                            $$->type = Error;
                            goto endFunction;
                        }
                        vector<int> element_index;
                        switch(len)
                        {
                            case 1:
                            {
                                if($3->type!=Int)
                                {
                                    yyerror("TypeError: range() integer start argument expected");
                                    $$->type = Error;
                                    goto endFunction;
                                }
                                element_index = range(0,$3->integer,1);
                                //temp = CreateList(0,$3->integer);
                                break;
                            }
                            case 2:
                            {
                                if($3->type!=Int||$3->next_element->type!=Int)
                                {
                                    yyerror("TypeError: range() integer all arguments expected");
                                    $$->type = Error;
                                    goto endFunction;
                                }
                                element_index = range($3->integer,$3->next_element->integer,1);
                                break;
                            }
                            case 3:
                            {
                                if($3->type!=Int||$3->next_element->type!=Int||$3->next_element->next_element->type!=Int)
                                {
                                    yyerror("TypeError: range() integer all arguments expected");
                                    $$->type = Error;
                                    goto endFunction;
                                }
                                element_index = range($3->integer,$3->next_element->integer,$3->next_element->next_element->integer);
                                break;
                            }
                        }
                        len = element_index.size();
                
                        cList* tail = head;
                        for(int i = 0;i<len;i++)
                        {
                            cList* c = (cList*)safe_malloc(sizeof(cList));
                            c->type = Int;
                            c->integer = element_index[i];
                            tail->next_element = c;
                            tail = c;
                        }
                        tail->next_element = NULL;
                        $$->new_List = head->next_element;
                        $$->type = MyList;
                        free(head);
                    }
                    else if(!strcmp($1->cID,s4))
                    {
                        $$ = (stype*)safe_malloc(sizeof(stype));
                        $$->type = MyList;
                        $$->new_List = list($3);
                        stype* temp = $$;
                        if($$->new_List==NULL)
                        {
                            $$->type = Error;
                        }
                    }
                    else
                    {
                        yyerror("the function does not exist");
                        $$->type = Error;
                    }
                }
            endFunction:
                ;
                //free($1);
                //free_cList($3);
            }
            | atom_expr  '('  ')'
            {
                const char* s5 = "quit";
                if(!strcmp($1->cID,s5))
                    return 0;
            }
            ;

arglist : add_expr
        {
            $$ = Stype2Clist($1);
            $$->reverse = $1;
        }   
        | arglist ',' add_expr 
        {
            $1->next_element = Stype2Clist($3);
            $1->next_element->reverse = $3;
            $$ = $1;
        }
        ;      

List    : '[' ']'   {
                        $$ = NULL;
                    }
        | '[' List_items opt_comma ']'  {
                                            $$ = $2;
                                        } 
        ;

opt_comma   :   {
                    $$ = ' ';
                }
                /*  empty production */
            | ','   {
                        $$ = ',';
                    }
            ;

List_items  : add_expr  {
                            //cout<<"List_items"<<endl;
                            $$ = (cList*)safe_malloc(sizeof(cList)*1);
                            $$->type = $1->type;
                            switch($1->type) {
                            case Int:
                                $$->integer = $1->iValue;
                                break;
                            case Double:
                                $$->float_number = $1->dValue;
                                break;
                            case String:
                                /*cout<<$1->string_literal<<endl;*/
                                $$->string_literal = $1->string_literal;
                                /*cout<<$$->string_literal<<endl;*/
                                break;
                            case MyList:
                                $$->new_List = $1->new_List;
                                break;
                            default:
                                ;
                            }
                            $$->next_element = NULL;
                            free($1);
                        }
      		| List_items ',' add_expr 
      		;

add_expr : add_expr '+' mul_expr{
                                    $$ = (stype*)safe_malloc(sizeof(stype));
                                    stype* lvalue;
                                    stype* rvalue;
                                    if ($1->type == Identify) {
                                        symbol_item* tmp = Search_Symbol($1->cID);
                                        if (!tmp) {
                                            yyerror("Not defined!");
                                            $$->type = Error;
                                            goto endAdd;
                                        } else {
                                            lvalue = tmp->stype_items;
                                        }
                                    } else {
                                        lvalue = $1;
                                    }
                                    if ($3->type == Identify) {
                                        symbol_item* tmp = Search_Symbol($3->cID);
                                        if (!tmp) {
                                            yyerror("Not defined!");
                                            $$->type = Error;
                                            goto endAdd;
                                        } else {
                                            rvalue = tmp->stype_items;
                                        }
                                    } else {
                                        rvalue = $3;
                                    }
                                    if (!stype_Add(lvalue, rvalue, $$)) {
                                        yyerror("Unsupported operation for types");
                                        $$->type = Error;
                                    }
                                endAdd:
                                    free($1);
                                    free($3);								
								}
            | add_expr '-' mul_expr {
                                        $$ = (stype*)safe_malloc(sizeof(stype));
                                        stype* lvalue;
                                        stype* rvalue;
                                        if ($1->type == Identify) {
                                            symbol_item* tmp = Search_Symbol($1->cID);
                                            if (!tmp) {
                                                yyerror("Not defined!");
                                                $$->type = Error;
                                                goto endMinus;
                                            } else {
                                                lvalue = tmp->stype_items;
                                            }
                                        } else {
                                            lvalue = $1;
                                        }
                                        if ($3->type == Identify) {
                                            symbol_item* tmp = Search_Symbol($3->cID);
                                            if (!tmp) {
                                                yyerror("Not defined!");
                                                $$->type = Error;
                                                goto endMinus;
                                            } else {
                                                rvalue = tmp->stype_items;
                                            }
                                        } else {
                                            rvalue = $3;
                                        }
                                        if (!stype_Minus(lvalue, rvalue, $$)) {
                                            yyerror("Unsupported operation for types");
                                            $$->type = Error;
                                        }
                                    endMinus:
                                        free($1);
                                        free($3);
                                    }
	      	|  mul_expr {
	      					$$ = $1;
	      				}
        ;

mul_expr    : mul_expr '*' factor   {
                                        $$ = (stype*)safe_malloc(sizeof(stype));
                                        stype* lvalue;
                                        stype* rvalue;
                                        if ($1->type == Identify) {
                                            symbol_item* tmp = Search_Symbol($1->cID);
                                            if (!tmp) {
                                                yyerror("Not defined!");
                                                $$->type = Error;
                                                goto endMul;
                                            } else {
                                                lvalue = tmp->stype_items;
                                            }
                                        } else {
                                            lvalue = $1;
                                        }
                                        if ($3->type == Identify) {
                                            symbol_item* tmp = Search_Symbol($3->cID);
                                            if (!tmp) {
                                                yyerror("Not defined!");
                                                $$->type = Error;
                                                goto endMul;
                                            } else {
                                                rvalue = tmp->stype_items;
                                            }
                                        } else {
                                            rvalue = $3;
                                        }
                                        if (!stype_Mul(lvalue, rvalue, $$)) {
                                            yyerror("Unsupported operation for types");
                                            $$->type = Error;
                                        }
                                    endMul:
                                        free($1);
                                        free($3);
                                    }
            |  mul_expr '/' factor  {
                                        $$ = (stype*)safe_malloc(sizeof(stype));
                                        stype* lvalue;
                                        stype* rvalue;
                                        if ($1->type == Identify) {
                                            symbol_item* tmp = Search_Symbol($1->cID);
                                            if (!tmp) {
                                                yyerror("Not defined!");
                                                $$->type = Error;
                                                goto endDiv;
                                            } else {
                                                lvalue = tmp->stype_items;
                                            }
                                        } else {
                                            lvalue = $1;
                                        }
                                        if ($3->type == Identify) {
                                            symbol_item* tmp = Search_Symbol($3->cID);
                                            if (!tmp) {
                                                yyerror("Not defined!");
                                                $$->type = Error;
                                                goto endDiv;
                                            } else {
                                                rvalue = tmp->stype_items;
                                            }
                                        } else {
                                            rvalue = $3;
                                        }
                                        switch (stype_Div(lvalue, rvalue, $$)) {
                                        case 0:
                                            yyerror("Unsupported operation for types");
                                            $$->type = Error;
                                            break;
                                        case -1:
                                            yyerror("Division by zero");
                                            $$->type = Error;
                                            break;
                                        default:
                                        case 1:
                                            break;
                                        }
                                    endDiv:
                                        free($1);
                                        free($3);
                                    }
            | mul_expr '%' factor   {
                                        $$ = (stype*)safe_malloc(sizeof(stype));
                                        stype* lvalue;
                                        stype* rvalue;
                                        if ($1->type == Identify) {
                                            symbol_item* tmp = Search_Symbol($1->cID);
                                            if (!tmp) {
                                                yyerror("Not defined!");
                                                $$->type = Error;
                                                goto endMod;
                                            } else {
                                                lvalue = tmp->stype_items;
                                            }
                                        } else {
                                            lvalue = $1;
                                        }
                                        if ($3->type == Identify) {
                                            symbol_item* tmp = Search_Symbol($3->cID);
                                            if (!tmp) {
                                                yyerror("Not defined!");
                                                $$->type = Error;
                                                goto endMod;
                                            } else {
                                                rvalue = tmp->stype_items;
                                            }
                                        } else {
                                            rvalue = $3;
                                        }
                                        switch (stype_Mod(lvalue, rvalue, $$)) {
                                        case 0:
                                            yyerror("Unsupported operation for types");
                                            $$->type = Error;
                                            break;
                                        case -1:
                                            yyerror("Division by zero");
                                            $$->type = Error;
                                            break;
                                        default:
                                        case 1:
                                            break;
                                        }
                                    endMod:
                                        free($1);
                                        free($3);
                                    }
            | factor    {
                            $$ = $1;
                        }
            ;

%%


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
