# Tiny_Python_Interpreter
a simple python interpreter implemented by yacc and lex

![](https://github.com/Berkesole/Tiny_Python_Interpreter/blob/master/assets/example.png)
### Running
Make sure you get all the requestments, if not, do below 
```bash
sudo apt-get install flex bison
```
Clone the repository from the github page
```bash
git clone git@github.com:Berkesole/Tiny_Python_Interpreter.git
```
You have two ways to make all the file  
```bash
lex minipy-lab.l
yacc --defines=minipy-lab.tab.h minipy-lab.y
```
Then you should make the `.cpp` file, and maybe you should ignore some Warning Messages   
```bash
c++ -g -o analysis y.tab.c minipy.cpp
```
Anyway, you can also use `make` to make all the files 
```bash
make
```
### functions
- +,-,*,/,%
- list
- append(), len(), print(), exit(), join()
