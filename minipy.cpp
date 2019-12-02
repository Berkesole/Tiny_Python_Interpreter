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
