#ifndef FUN_HPP
#define FUN_HPP
#include"definitions.hpp"
#include<algorithm>
#include<iostream>
#include<map>
#include<sstream>

std::string createID();
std::string create_constantASM(unsigned long long i, char X);
std::string addASM(char A, char B);
std::string subASM(char A, char B);
std::string divASM(char A, char B, char C, char D, char E);
std::string modASM(char A, char B, char C, char D, char E);
std::string mulASM(char A, char B, char C);
std::string equalASM(char A, char B, char C);
std::string nonequalASM(char A, char B, char C);
std::string moreASM(char A, char B);
std::string lessASM(char A, char B);
std::string moreequalASM(char A, char B);
std::string lessequalASM(char A, char B);
unsigned long long countLines(std::string str);
std::string arr(std::string s1, std::string s2);
std::string arrnum(std::string s1, std::string s2);
std::string num3(std::string s);
#endif
