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

