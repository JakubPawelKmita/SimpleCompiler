#ifndef DEFINITIONS_HPP
#define DEFINITIONS_HPP

#include<iostream>
#include<algorithm>
#include<iostream>
#include<map>
#include<sstream>

int yylex();
int yyparse();
extern FILE* yyin;

extern int yylineno;

extern "C" int yywrap();
void yyerror(const char *s);

void error(std::string msg, bool fatal);
void warning(std::string msg);

// Tokens
#include "grammar.hpp"

#endif
