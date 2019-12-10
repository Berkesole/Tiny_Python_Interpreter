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
    // case Splite:
    //     {
    //         cList* head = (cList*)safe_malloc(sizeof(cList));
    //         cList* tail = head;
    //         cList* temp = show->new_List;
    //         while(temp!=NULL)
    //         {
    //             cList* c = (cList*)safe_malloc(sizeof(cList));
    //             c->type = temp->new_List->type;
    //             switch (c->type) {
    //                 case Int:
    //                     c->integer = temp->new_List->integer;
    //                     break;
    //                 case Double: 
    //                     c->float_number = temp->new_List->float_number;
    //                     break;
    //                 case String:
    //                     c->string_literal = temp->new_List->string_literal;
    //                     break;
    //                 case MyList:
    //                     c->new_List = temp->new_List->new_List;
    //                     break;
    //                 default:
    //                     ;
    //                 }
    //             temp = temp->next_element;
    //             tail->next_element = c;
    //             tail = c;
    //         }
    //         tail->next_element = NULL;
    //         printList(head->next_element);
    //         tail = head->next_element;
    //         while(tail)
    //         {
    //             free(head);
    //             head = tail;
    //             tail = head->next_element;
    //         }
    //         free(head);
    //     }
    case Error:
        break;
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

