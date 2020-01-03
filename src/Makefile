analysis: y.tab.c lex.yy.c minipy.cpp
	c++ -g -o analysis y.tab.c minipy.cpp
y.tab.c: minipy-lab.y
	yacc --defines=minipy-lab.tab.h minipy-lab.y
lex.yy.c: minipy-lab.l
	lex minipy-lab.l
clean:
	rm analysis y.tab.c lex.yy.c minipy-lab.tab.h