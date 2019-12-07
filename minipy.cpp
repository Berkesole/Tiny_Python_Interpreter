#include "minipy.h"


extern symbol_item* symbol_table;

void yyerror(char const* s)
{
    cout << "error:" ;
    cout << s << endl ; 
}

void printAssignExpr(stype* show)
{
    switch (show->type) {
    case Int:
        cout << show->iValue << endl;
        break;
    case Double:
        cout << show->dValue;
        if (fabs(show->dValue - int(show->dValue)) < Epsilon)
            cout << ".0" << endl;
        cout << endl;
        break;
    case MyList:
        printList(show->new_List);
        cout << endl;
        break;
    case String:
        printf("\"%s\"\n", show->string_literal);
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
        }
    }
}

void printList(cList* new_List)
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
            cout << temp->string_literal;
            break;
        case MyList:
            printList(temp->new_List);
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
    } else {
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
    } else {
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
    *dst = *src;
}

void copy_cList(cList* src, cList* dst)
{
    *dst = *src;
    if (dst->type == MyList) {
        dst->new_List = (cList*)safe_malloc(sizeof(cList));
        copy_cList(src->new_List, dst->new_List);  
    }
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

//void free_symbol_item(symbol_item* target)
//{
//    free(target->cID);
//    free_stype(target->stype_items);
//    free(target);
//}

cList* analysis_ListElement(stype* src)
{
                            symbol_item* itemtemp = Search_Symbol(src->sListElement.cID);
                            if(itemtemp==NULL)
                            {
                                yyerror("Not defined!");
                                return NULL;
                            }
                            if(Is_Silce == 0)
                            {                               
                                stype* temp = itemtemp->stype_items;
                                if(temp->type!=MyList)
                                {
                                    yyerror("this object is not subscriptable");
                                    return NULL;
                                }
                                cList* temp_List = (cList*)safe_malloc(sizeof(cList));
                                cList* temp_List2 = temp_List;
                                temp_List->type = MyList;
                                temp_List->new_List = temp->new_List;
                                for (int i = 0; i < src->sListElement.place.size(); ++i)
                                {
                                    if(temp_List->type!=MyList)
                                    {
                                        yyerror("this object is not subscriptable");
                                        free(temp_List2);
                                        return NULL;
                                    }
                                    temp_List = temp_List->new_List;
                                    for (int j = 0; j < src->sListElement.place[i]; ++j)
                                    {
                                        temp_List = temp_List->next_element;
                                    }
                                }
                                free(temp_List2);
                                return temp_List;
                            }
                            else 
                            {
                                stype* temp = itemtemp->slice_TEMP;
                                
                            }                               
}