# Tiny_Python_Interpreter
A simple python interpreter implemented by yacc and lex and it is capable of interpreting python-like languages simply.  

We leads the language of the translation the analysis the method to produce the language rule.

This project is mainly contributed by [Ke Rui](https://github.com/Berkesole) and [Jiawei Wang](https://github.com/JarvisUSTC)

![](https://github.com/Berkesole/Tiny_Python_Interpreter/blob/master/assets/example.png)

## Directory Structure
- `src` : All the important code of Python_Interpreter
	- `.y` : productions/rewriting mle and syntax-directed file
 	- `.l` : code of lexical analysis and identify specific text strings to generate TOKEN
 	- `.cpp` : functions implemented by c++
 	- `.h` : the head file
 	- `Makefile` : make all files
- `assets` : some pictures and others

## Running
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
/* Anyway, you can also use `make` to make all the files */
make
```
## Functions
- +,-,*,/,%
- list
- append(), len(), print(), exit(), join()
- UI
- slices/deep copy and shallow copy
