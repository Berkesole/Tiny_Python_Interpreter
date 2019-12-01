#define Epsilon 1e-6
#include <iostream>
#include <math.h>
#include <stdlib.h>
#include <stdio.h>
#include <vector>
#include <string.h>
using namespace std;

typedef enum TYPE {
    Int,
    Double,
    Identify,
    String,
    MyList,
    List_element,
    Splite
}TYPE;

typedef struct ListElement
{
    char* cID;//所在的列表名称
    vector<int> place;//元素位置 insert(place.begin(),int)
}ListElement;

