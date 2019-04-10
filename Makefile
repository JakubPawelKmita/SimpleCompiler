CFLAGS 	 += -O3
CXXFLAGS += -std=c++0x

CC        = gcc $(CFLAGS)
CXX       = g++ $(CFLAGS) $(CXXFLAGS)

LDFLAGS  +=

all: compiler
	$(CXX) -o kompilator fun.o lexer.o grammar.o

bison:
	bison -o grammar.cpp -d bison.y	
flex:
	flex -o lexer.cpp flex.l

compiler: flex bison
	$(CXX) -c lexer.cpp -o lexer.o
	$(CXX) -c grammar.cpp -o grammar.o
	$(CXX) -c fun.cpp -o fun.o
