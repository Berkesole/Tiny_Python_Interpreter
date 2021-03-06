#include "minipy.h"


extern symbol_item* symbol_table;

void yyerror(char const* s)
{
    cout << s; //<< endl ; 
}

void printAssignExpr(stype* show)
{
    switch (show->type) {
    case Int:
        cout << show->iValue; //<< endl;
        break;
    case Double:
        cout << show->dValue;
        if (fabs(show->dValue - int(show->dValue)) < Epsilon)
            cout << ".0";
        break;
    case MyList:
        printList(show->new_List,show->new_List);
        break;
    case String:
        printf("\'%s\'", show->string_literal);
        break;
    case Identify:
        {
            int IsDefined = 0;
            for (symbol_item* temp = symbol_table; temp; temp = temp->next_element) {
                if (!strcmp(temp->cID, show->cID)) {
                    printAssignExpr(temp->stype_items);
                    IsDefined = 1;
                    break;
                }
            }
            if(IsDefined == 0) {
                yyerror("Not defined");
            }
            break;
        }
    case List_element:
    {
        stype* temp = (stype*)malloc(sizeof(stype));
        temp->type = show->new_List->type;
        switch(show->new_List->type)
        {
            case Int:
                temp->iValue = show->new_List->integer;
                break;
            case Double:
                temp->dValue = show->new_List->float_number;
                break;
            case String:
                temp->string_literal = show->new_List->string_literal;
                break;
            case MyList:
                temp->new_List = show->new_List->new_List;
                break;
            default:;
        }
        printAssignExpr(temp);
        break;
    }
    case Error:
        break;
    default:;
    }
}

void printList(cList* new_List,cList* head)
{
    cout << '[' ;
    for (cList* temp = new_List; temp; (temp = temp->next_element) ? printf(", ") : 0 ) {
        switch (temp->type) {
        case Int:
            cout << temp->integer;
            break;
        case Double: 
            cout << temp->float_number;
            if (fabs(temp->float_number - (int)(temp->float_number)) < Epsilon)
                cout << ".0";
            break;
        case String:
            printf("\'%s\'", temp->string_literal);
            break;
        case MyList:
            if(temp->new_List == head)
                cout << "[...]";
            else
                printList(temp->new_List,temp->new_List);
            break;
        default:
            ;
        }
    }
    cout << ']' ;
}

symbol_item* Search_Symbol(char * cID)
{
    for (symbol_item* tmp = symbol_table; tmp; tmp = tmp->next_element) {
        if (!strcmp(cID, tmp->cID)) {
            return tmp;
        }
    }
    return NULL;
}

int stype_Add(stype* lval, stype* rval, stype* result)
{
    TYPE ltype = lval->type;
    TYPE rtype = rval->type;
    if ((ltype == Int || ltype == Double)
    &&  (rtype == Int || rtype == Double)) {
        if (ltype == Int && rtype == Int) {
            result->type = Int;
            result->iValue = lval->iValue + rval->iValue;
        } else {
            result->type = Double;
            result->dValue = 0.0;
            if (ltype == Int) {
                result->dValue = (double)lval->iValue;
            } else {
                result->dValue = lval->dValue;
            }
            if (rtype == Int) {
                result->dValue += (double)rval->iValue;
            } else {
                result->dValue += rval->dValue;
            }
        }
    } else if ( ltype == String
             && rtype == String) {
        result->type = String;
        result->string_literal = (char *)safe_malloc(sizeof(
                strlen(lval->string_literal) + strlen(rval->string_literal)
            ));
        strcpy(result->string_literal, lval->string_literal);
        strcat(result->string_literal, rval->string_literal);
    }
    else if(ltype == MyList && rtype == MyList)
    {
        cList* lcopy = (cList*)safe_malloc(sizeof(cList));
        result->type = MyList;
        copy_cList(lval->new_List,lcopy);
        cList* rcopy = (cList*)safe_malloc(sizeof(cList));
        copy_cList(rval->new_List,rcopy);
        cList* temp = lcopy;
        if(temp == NULL)
        {
            result->new_List = rcopy;
            return 1;
        }
        if(rcopy == NULL)
        {
            result->new_List = lcopy;
            return 1;
        }
        while(temp->next_element)
            temp = temp->next_element;
        temp->next_element = rcopy;
        result->new_List = lcopy;
    }
    else {
        return 0;
    }
    return 1;
}

int stype_Minus(stype* lval, stype* rval, stype* result)
{
    TYPE ltype = lval->type;
    TYPE rtype = rval->type;
    if ((ltype == Int || ltype == Double)
    &&  (rtype == Int || rtype == Double)) {
        if (ltype == Int && rtype == Int) {
            result->type = Int;
            result->iValue = lval->iValue - rval->iValue;
        } else {
            result->type = Double;
            result->dValue = 0.0;
            if (ltype == Int) {
                result->dValue = (double)lval->iValue;
            } else {
                result->dValue = lval->dValue;
            }
            if (rtype == Int) {
                result->dValue -= (double)rval->iValue;
            } else {
                result->dValue -= rval->dValue;
            }
        }
    } else {
        return 0;
    }
    return 1;
}

int stype_Mul(stype* lval, stype* rval, stype* result)
{
    TYPE ltype = lval->type;
    TYPE rtype = rval->type;
    if ((ltype == Int || ltype == Double)
    &&  (rtype == Int || rtype == Double)) {
        if (ltype == Int && rtype == Int) {
            result->type = Int;
            result->iValue = lval->iValue * rval->iValue;
        } else {
            result->type = Double;
            result->dValue = 0.0;
            if (ltype == Int) {
                result->dValue = (double)lval->iValue;
            } else {
                result->dValue = lval->dValue;
            }
            if (rtype == Int) {
                result->dValue *= (double)rval->iValue;
            } else {
                result->dValue *= rval->dValue;
            }
        }
    } 
    else if(ltype == MyList && rtype == Int||(ltype == Int && rtype == MyList))
    {
        if(ltype == MyList)
        {
            result->type = MyList;
            cList* lcopy = (cList*)safe_malloc(sizeof(cList));
            copy_cList(lval->new_List,lcopy);
            int num = rval->iValue;
            if(num<=0)
            {
                result->new_List = NULL;
                return 1;
            }
            result->new_List = lcopy;
            num--;
            cList* temp = result->new_List;
            if(temp == NULL)
            {
                result->new_List = NULL;
                return 1;
            }
            while(num--)
            {
                cList* temp2 = (cList*)safe_malloc(sizeof(cList));
                copy_cList(lval->new_List,temp2);
                temp = result->new_List;
                while(temp->next_element)
                    temp = temp->next_element;
                temp->next_element = temp2;
            }
        }
        else if(rtype == MyList)
        {
            result->type = MyList;
            cList* rcopy = (cList*)safe_malloc(sizeof(cList));
            copy_cList(rval->new_List,rcopy);
            int num = lval->iValue;
            if(num<=0)
            {
                result->new_List = NULL;
                return 1;
            }
            result->new_List = rcopy;
            num--;
            cList* temp = result->new_List;
            if(temp == NULL)
            {
                result->new_List = NULL;
                return 1;
            }
            while(num--)
            {
                cList* temp2 = (cList*)safe_malloc(sizeof(cList));
                copy_cList(rval->new_List,temp2);
                temp = result->new_List;
                while(temp->next_element)
                    temp = temp->next_element;
                temp->next_element = temp2;
            }
        }
    }
    else {
        return 0;
    }
    return 1;
}

int stype_Div(stype* lval, stype* rval, stype* result)
{
    TYPE ltype = lval->type;
    TYPE rtype = rval->type;
    if ((ltype == Int || ltype == Double)
    &&  (rtype == Int || rtype == Double)) {
        result->type = Double;
        result->dValue = 0.0;
        if (ltype == Int) {
            result->dValue = (double)lval->iValue;
        } else {
            result->dValue = lval->dValue;
        }
        if (rtype == Int) {
            if (rval->iValue == 0) {
                return -1;
            }
            result->dValue /= (double)rval->iValue;
        } else {
            if (fabs(rval->dValue) < Epsilon) {
                return -1;
            }
            result->dValue /= rval->dValue;
        }
    } else {
        return 0;
    }
    return 1;
}

int stype_Mod(stype* lval, stype* rval, stype* result)
{
    TYPE ltype = lval->type;
    TYPE rtype = rval->type;
    if ((ltype == Int || ltype == Double)
    &&  (rtype == Int || rtype == Double)) {
        if (ltype == Int && rtype == Int) {
            result->type = Int;
            if (rval->iValue == 0) {
                return -1;
            }
            result->iValue = lval->iValue % rval->iValue;
            if ((lval->iValue > 0 && rval->iValue < 0) ||
                (lval->iValue < 0 && rval->iValue > 0)) {
                if (result->iValue != 0) {
                    result->iValue += rval->iValue;
                }
            }
        } else {
            result->type = Double;
            result->dValue = 0.0;
            double ldvalue = lval->type == Int ? (double)lval->iValue : lval->dValue;
            double rdvalue = rval->type == Int ? (double)rval->iValue : rval->dValue;
            if (fabs(rdvalue) < Epsilon) {
                return -1;
            }
            result->dValue = ldvalue - (int)(ldvalue / rdvalue) * rdvalue;
            if ((ldvalue > 0 && rdvalue < 0) ||
                (ldvalue < 0 && rdvalue > 0)) {
                if (fabs(result->dValue) >= Epsilon) {
                    result->dValue += rval->dValue;
                }
            }
        }
    } else {
        return 0;
    }
    return 1;
}

void* safe_malloc(int size)
{
    void* result = malloc(size);
    if (!result) {
        printf("Memory not enough!\n");
        exit(1);
    }
    return result;
}

void copy_stype(stype* src, stype* dst)
{
    if(src->type == List_element)
    {
        cList* temp = src->new_List;
        switch(temp->type)
        {
            case Int:
            {
                dst->type = Int;
                dst->iValue = temp->integer;
                break;
            }
            case Double:
            {
                dst->type = Double;
                dst->dValue = temp->float_number;
                break;
            }
            case MyList:
            {
                dst->type = MyList;
                dst->new_List = temp->new_List;
                break;
            }
            case String:
            {
                dst->type = String;
                dst->string_literal = (char*)safe_malloc(sizeof(temp->string_literal));
                strncpy(dst->string_literal, temp->string_literal, strlen(temp->string_literal));
                break;
            }
        }
    }
    // else if(src->type == Splite)
    // {
    //     dst->type = MyList;
    //     cList* head = (cList*)safe_malloc(sizeof(cList));
    //     cList* tail = head;
    //     cList* temp1 = src->new_List;
    //     while(temp1)
    //     {
    //         cList* temp = temp1->new_List;
    //         cList* c = (cList*)safe_malloc(sizeof(cList));
    //         switch(temp->type)
    //         {
    //             case Int:
    //             {
    //                 c->type = Int;
    //                 c->integer = temp->integer;
    //                 break;
    //             }
    //             case Double:
    //             {
    //                 c->type = Double;
    //                 c->float_number = temp->float_number;
    //                 break;
    //             }
    //             case MyList:
    //             {
    //                 c->type = MyList;
    //                 c->new_List = temp->new_List;
    //                 break;
    //             }
    //             case string_literal:
    //             {
    //                 c->type = String;
    //                 c->string_literal = (char*)safe_malloc(sizeof(temp->string_literal));
    //                 strncpy(c->string_literal, temp->string_literal, strlen(temp->string_literal));
    //                 break;
    //             }
    //         }
    //         temp1 = temp1->next_element;
    //         tail->next_element = c;
    //         tail = c;
    //     }
    //     tail->next_element = NULL;
    //     dst->new_List = head->next_element;
    //     free(head);
    // }
    else if(src->type == String)
    {
        dst->type = String;
        dst->string_literal = (char*)safe_malloc(sizeof(src->string_literal));
        strncpy(dst->string_literal, src->string_literal, strlen(src->string_literal));
    }
    else 
    {
        //*dst = *src;
        switch(src->type)
        {
            case Int:
            {
                dst->type = Int;
                dst->iValue = src->iValue;
                break;
            }
            case Double:
            {
                dst->type = Double;
                dst->dValue = src->dValue;
                break;
            }
            case MyList:
            {
                dst->type = MyList;
                dst->new_List = src->new_List;
                break;
            }
        }
    }
    // if (dst->type == MyList) {
    //     dst->new_List = (cList*)safe_malloc(sizeof(cList));
    //     copy_cList(src->new_List, dst->new_List);
    // }
}

void copy_cList(cList* src, cList*& dst)
{
    if(src == NULL)
    {
        dst = NULL;
        return;
    }
    *dst = *src;
    if (dst->type == MyList) {
        dst->new_List = (cList*)safe_malloc(sizeof(cList));
        copy_cList(src->new_List, dst->new_List);  
    }
    else if(dst->type == String)
    {
        dst->string_literal = (char*)safe_malloc(sizeof(src->string_literal));
        strncpy(dst->string_literal, src->string_literal, strlen(src->string_literal));
    }
    dst->next_element = (cList*)safe_malloc(sizeof(cList));
    copy_cList(src->next_element,dst->next_element);
}

void free_stype(stype* target)
{
    if (target->type == MyList) {
        free_cList(target->new_List);
    }
    free(target);
}

void free_cList(cList* target)
{
    if (target->type == MyList) {
        free_cList(target->new_List);
    }
    if (target->next_element) {
        free_cList(target->next_element);
    }
    free(target);
}

void free_symbol_item(symbol_item* target)
{
    free(target->cID);
    free_stype(target->stype_items);
    free(target);
}

cList* Stype2Clist(stype* t)
{
    cList* list = (cList*)safe_malloc(sizeof(cList));
    list->next_element = NULL;
            list->type = t->type;
            switch(t->type)
            {
                case Int:
                    list->integer = t->iValue;
                    break;
                case Double:
                    list->float_number = t->dValue;
                    break;
                case String:
                    list->string_literal = t->string_literal;
                    break;
                case MyList:
                    list->new_List = t->new_List;
                    break;
                case List_element:
                {
                    list = t->new_List;
                    break;
                } 
                case Splite:
                {
                    list = t->new_List;
                    break;
                }
                case Identify:
                {
                    symbol_item* temp = Search_Symbol(t->cID);
                    if(temp == NULL)
                    {
                        yyerror("It is not defined");
                        return NULL;
                    }
                    stype* temp1 = temp->stype_items;
                    free(list);
                    list = Stype2Clist(temp1);
                    break;
                }
            }
    return list;
}

stype* MyAppend(stype* src,cList* arglist)
{
    //append只接收一个参数
    if(arglist->next_element!=NULL)
    {
        yyerror("TypeError: append() takes exactly one argument");
        src->type = Error;
        return src;
    }
    if(src->type == Identify)
    {
        symbol_item* item = Search_Symbol(src->cID);
        stype* t = item->stype_items;
        if(t->type != MyList)
        {
            yyerror("A non-list found!");
            src->type = Error;
            return src;
        }
        cList* temp = t->new_List;
        if(temp==NULL)
        {
            t->new_List = arglist;
            return src;
        }
        while(temp->next_element)
        {
            temp = temp->next_element;
        }
        temp->next_element = arglist;
        return src;
    }
    else if(src->type == List_element)
    {
        cList* temp = src->new_List;
        if(temp->type != MyList)
        {
            yyerror("A non-list found!");
            src->type = Error;
            return src;
        }
        temp = temp->new_List;
        if(temp==NULL)
        {
            src->new_List->new_List = arglist;
            return src;
        }
        while(temp->next_element)
        {
            temp = temp->next_element;
        }
        temp->next_element = arglist;
        return src;
    }
    else if(src->type == MyList)
    {
        cList* temp = src->new_List;
        if(temp==NULL)
        {
            src->new_List = arglist;
            return src;
        }
        while(temp->next_element)
        {
            temp = temp->next_element;
        }
        temp->next_element = arglist;
        return src;
    }
}

void MyPrint(cList* arglist)
{
    if(arglist->next_element==NULL)
    {
        printAssignExpr(arglist->reverse);
        return;
    }
    cout<<'(';
    while(arglist)
    {
        printAssignExpr(arglist->reverse);
        if(arglist->next_element !=NULL)
            cout<<',';
        arglist = arglist->next_element;
    }
    cout<<')';//<<endl;
    return;

}

int Mylen(cList* arglist)
{
    // if(arglist->type == List_element)
    // {
    //     arglist = arglist->new_List;
    // }
    if(arglist->type!=MyList)//&&arglist->type!=Splite)
    {
        yyerror("TypeError: this object has no len()");
        return -1;
    }
    cList* temp = arglist->new_List;
    int len = 0;
    while(temp)
    {
        len = len + 1;
        temp = temp->next_element;
    }
    return len;
}

int SizeCaculation(cList* temp)
{
    int size = 0;
    while(temp != NULL)
    {
        size++;
        temp = temp->next_element;
    }
    return size;
}

vector<int> range(int a,int b,int c)
{
    std::vector<int> element_index;
    if(c==0)
        return element_index;
    else if(c>0)
    {

        if(a>=b)
            return element_index;
        while(a<b)
        {
            element_index.push_back(a);
            a += c;
        }
        return element_index;
    }
    else
    {
        if(a<=b)
            return element_index;
        while(a>b)
        {
            element_index.push_back(a);
            a += c;
        }
        return element_index;
    }
}

vector<int> MySplite(int a,int b,int c,int len)
{
    if(a < -len) a = 0;
    else if (a > len - 1) a = len;
    if(b < -len) b = 0;
    else if (b > len - 1) b = len; 
    vector<int> element_index;
    if(a < 0)
    {
        a += len;
    }
    if(b < 0)
    {
        b += len;
    }
    if(c == 0)
    {
        return element_index;
    }
    else if(c > 0)
    {

        if(a >= b)
            return element_index;
        while(a < b)
        {
            element_index.push_back(a);
            a += c;
        }
        return element_index;
    }
    else
    {
        if(a <= b)
            return element_index;
        while(a > b)
        {
            element_index.push_back(a);
            a += c;
        }
        return element_index;
    }

}  

cList* list(cList* arglist)
{
    if(arglist->next_element!=NULL)
    {
        yyerror("TypeError: list() takes exactly one argument");
        return NULL;
    }
    if(arglist->type == String)
    {
        int len = strlen(arglist->string_literal);
        cList* head = (cList*)safe_malloc(sizeof(cList));
        cList* tail = head;
        for (int i = 0; i < len; ++i)
        {
            cList* temp = (cList*)safe_malloc(sizeof(cList));
            temp->type = String;
            temp->string_literal = (char*)safe_malloc(sizeof(char)*2);
            temp->string_literal[0] = arglist->string_literal[i];
            temp->string_literal[1] = '\0';
            tail->next_element = temp;
            tail = temp;
        }
        tail->next_element = NULL;
        tail = head->next_element;
        free(head);
        return tail;
    }
    else if(arglist->type == MyList)//||arglist->type == Splite)
    {
        cList* src = (cList*)safe_malloc(sizeof(cList));
        copy_cList(arglist->new_List,src);
        return src;//arglist->new_List;
    }
    else
    {
        yyerror("TypeError: this object is not iterable");
        return NULL;
    }
}

void assign_clist(cList *src, cList *&dst)
{
    switch(src->type)
    {
        case Int:
        {
            dst->type = Int;
            dst->integer = src->integer;
            break;
        }
        case Double:
        {
            dst->type = Double;
            dst->float_number = src->float_number;
            break;
        }
        case MyList:
        {
            dst->type = MyList;
            dst->new_List = src->new_List;
            break;
        }
        case String:
        {
            dst->type = String;
            dst->string_literal = (char*)safe_malloc(sizeof(src->string_literal));
            strncpy(dst->string_literal, src->string_literal, strlen(src->string_literal));
            break;
        }
    }
}

// void memmove_Slice(stype *src, stype *dst, int offset)
// {
//  cList *__shlstart = src->new_List;


//  if(offset < 0) //左移
//  {
//      offset = abs(offset);
//  }
//  else //右移
//  {

//  }
// }

// void shl_Slice(stype *src, stype *dst,int offset)
// {
//     offset = abs(offset);
//     cList *__shlstart = src->new_List;
//     int size = dst->slice_index.size();
//     for(int i = 0; i < dst->slice_index[0] - 1; i++)
//     {
//         __shlstart = __shlstart -> next_element;//记录切片的第一个结点
//     }
//     cList *temp_start = __shlstart;
//     cList *temp_end = __shlstart;
//     int flag = 0;
//     for (int i = 0; i < size - offset; i++)
//     {
//         if(flag == 0)
//         {
//             flag = 1;
//         }
//         else temp_start = temp_start->next_element; //记录左移后删除的list的第一个结点
//     }
//     for (int i = 0; i < size + 1 && temp_end != NULL; i++)
//     {
//         temp_end = temp_end->next_element;
//     }
//     if(temp_end != NULL) 
//     {
//         assign_clist(temp_end,temp_start->next_element);
//         temp_start->next_element->next_element = temp_end->next_element;
//     }
//     else 
//     {
//         if (dst->slice_index[0] == 0 && flag != 1) src->new_List = NULL;
//         else temp_start->next_element = NULL;
//     }
// }

void shl_Slice(stype *src, stype *dst,int offset)
{
    offset = abs(offset);
    cList *__shlstart = src->new_List;
    int size = dst->slice_index.size();
    for(int i = 0; i < dst->slice_index[0]; i++)
    {
        __shlstart = __shlstart -> next_element;//记录切片的第一个结点
    }
    cList *temp_start = __shlstart;
    cList *temp_end = __shlstart;

    for (int i = 0; i < size - offset; i++)
    {
        temp_start = temp_start->next_element; //记录左移后删除的最后一个结点
    }
    for (int i = 0; i < size; i++)
    {
        temp_end = temp_end->next_element;
    }
    
    if(temp_end != NULL) 
    {
        assign_clist(temp_end,temp_start);
        temp_start->next_element = temp_end->next_element;        
    }
    else
    {
        if(temp_start == __shlstart)
        {
            if(__shlstart == src->new_List)
                src->new_List = NULL;
            else
            {
                __shlstart = src->new_List;
                for(int i = 0; i < dst->slice_index[0]-1; i++)
                {
                    __shlstart = __shlstart -> next_element;//记录切片的第一个结点
                }
                __shlstart->next_element = NULL;
            }
        }
        else   
        {
            temp_start = __shlstart;
            for (int i = 0; i < size - offset-1; i++)
            {
                temp_start = temp_start->next_element; //记录左移后删除的最后一个结点
            }
            temp_start->next_element = NULL;
        }
    }
}

void shr_Slice(stype *src, stype *dst,int offset)
{
    cList *__shrstart = src->new_List;
    int size = dst->slice_index.size();
    for(int i = 0; i < dst->slice_index[size]; i++)
    {
        __shrstart = __shrstart -> next_element;//记录切片的最后一个结点，开始右移的前一个位置
    }
    cList *temp = __shrstart->next_element; 
    for(int i = 0; i < offset; i++)
    {
        cList *NEWCLIST = (cList*)safe_malloc(sizeof(cList));
        temp = __shrstart->next_element;
        __shrstart->next_element = NEWCLIST;
        NEWCLIST->next_element = temp;
    }
}

cList* Copy_Slice(cList *src)
{
    cList *dst = (cList*)safe_malloc(sizeof(cList));
    dst->next_element = NULL;
    dst->type = src->type;
    switch(src->type)
    {
        case Int:
        {
            dst->integer = src->integer;
            break;
        }
        case Double:
        {
            dst->float_number = src->float_number;
            break;
        }
        case MyList:
        {
            dst->new_List = src->new_List;
            break;
        }
        case String:
        {
            dst->string_literal = (char*)safe_malloc(sizeof(src->string_literal));
            strncpy(dst->string_literal, src->string_literal, strlen(src->string_literal));
            break;
        }
    }
    return dst; 
}

void MyQuit(symbol_item* symbol_table)
{
    //free 所有的符号
    symbol_item* temp = symbol_table;
    symbol_item* temp1 = temp->next_element;
    while(temp1)
    {
        free_symbol_item(temp);
        temp = temp1;
        temp1 = temp->next_element;
    }
    free_symbol_item(temp);
    return;
}

stype* Myjoin(stype* Delimiter,cList* src)
{
    if(src->type!=MyList)
    {
        yyerror("TypeError: can only join an iterable");
        return NULL;
    }
    stype* result = (stype*)safe_malloc(sizeof(stype));
    result->type = String;
    cList* string_list = src->new_List;
    if(string_list->type!=String)
    {
        yyerror("TypeError:expected str instance");
        return NULL;
    }
    char* result_string = (char*)safe_malloc(sizeof(string_list->string_literal));
    strncpy(result_string, string_list->string_literal, strlen(string_list->string_literal));
    char* s = Delimiter->string_literal;
    while(string_list->next_element)
    {
        string_list = string_list->next_element;
        if(string_list->type!=String)
        {
            yyerror("TypeError:expected str instance");
            return NULL;
        }
        result_string = join3(result_string,s);
        result_string = join3(result_string,string_list->string_literal);
    }
    result->string_literal = result_string;
    return result;
}

char* join3(char *s1, char *s2)
{
    char *result = (char*)malloc(strlen(s1)+strlen(s2)+1);//+1 for the zero-terminator
    //in real code you would check for errors in malloc here
    if (result == NULL) exit (1);
 
    strcpy(result, s1);
    strcat(result, s2);
 
    return result;
}