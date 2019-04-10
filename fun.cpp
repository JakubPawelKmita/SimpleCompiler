/*
 * Kod zawierający funkcje użyte przy programowaniu kompilatora do projektu z JFTT2018
 *
 * Autor: Jakub Kmita
*/

#include"fun.hpp"
#include<iostream>
#include<algorithm>
#include<iostream>
#include<map>
#include<sstream>
#include<string>
using namespace std;

unsigned long long i=0; //globalny iterator do tworzenia ID

string createID(){ //generowanie unikalnego ID
	++i;
	stringstream ss;
	ss<<"[ID:"<<i<<"]";
	string s = ss.str();
	return s;
}

unsigned long long countLines(string str){
    unsigned long long count = 0;
    unsigned long long iterator=0;
    unsigned long long letters = str.length();

    while(iterator<letters){
        if(str[iterator]=='\n'){
            ++count;
        }
        ++iterator;
    }

    return count;
}

//generowanie liczby w zadanym rejestrze
string create_constantASM(unsigned long long i, char X){
	stringstream ss;
	while(i!=0){
		if(i%2==0)
		ss<<0;
		else
		ss<<1;
		i=i/2;
	}
	string s = ss.str();
	reverse(s.begin(), s.end());

	stringstream _asm;
	_asm<<"SUB "<<X<<" "<<X<<std::endl;

    if(s[0]=='1'){
        _asm<<"INC "<<X<<std::endl;
    }
	
	for(int x=1;x<s.length();++x){
		if(s[x] == '0'){
			_asm<<"ADD "<<X<<" "<<X<<std::endl;
		} else{
			_asm<<"ADD "<<X<<" "<<X<<std::endl;
			_asm<<"INC "<<X<<std::endl;	
		}
	}
	return _asm.str();
}

/*
działanie arytmetyczne lub logiczne pobiera argumenty z pierwszych dwóch podanych rejestrów
pozostale ewentualne rejestry sa potrzebne do wykonywania dzialan
wynik pozostawia w pierwszym podanym rejestrze
*/

//dodawanie na 2 rejestrach
string addASM(char A, char B){//A:=A+B
    stringstream _asm;
	_asm<<"ADD "<<A<<" "<<B<<endl;
	return _asm.str();
}
//odejmowanie na 2 rejestrach
string subASM(char A, char B){//A:=A-B
    stringstream _asm;
	_asm<<"SUB "<<A<<" "<<B<<endl;
	return _asm.str();
}
//dzielenie na 5 rejestrach
string divASM(char A, char B, char C, char D, char E){//A:=A/B zlozonosc O(log(n))

    string j = createID();

    stringstream _asm;

    _asm<<"JZERO "<<B<<" "<<j<<"+[21]"<<" #"<<j<<endl; //jesli dzielnik=0 to hop na koniec
    _asm<<"COPY "<<C<<" "<< A<<endl;
    _asm<<"SUB "<<E<<" "<< E<<endl;
    _asm<<"INC "<<E<<endl;
    _asm<<"SUB "<<A<<" "<< B<<endl;
    _asm<<"JZERO "<<A<<" "<<j<<"+[10]"<<endl;
    _asm<<"COPY "<<A<<" "<< C<<endl;
    _asm<<"ADD "<<B<<" "<< B<<endl;
    _asm<<"ADD "<<E<<" "<< E<<endl;
    _asm<<"JUMP "<<j<<"+[4]"<<endl;
    _asm<<"COPY "<<D<<" "<< B<<endl;
    _asm<<"SUB "<<B<<" "<< C<<endl;
    _asm<<"JZERO "<<B<<" "<<j<<"+[14]"<<endl;
    _asm<<"JUMP "<<j<<"+[16]"<<endl;
    _asm<<"SUB "<<C<<" "<< D<<endl;
    _asm<<"ADD "<<A<<" "<< E<<endl;
    _asm<<"COPY "<<B<<" "<< D<<endl;
    _asm<<"HALF "<<B<<endl;
    _asm<<"HALF "<<E<<endl;
    _asm<<"JZERO "<<E<<" "<<j<<"+[22]"<<endl;
    _asm<<"JUMP "<<j<<"+[10]"<<endl;
    _asm<<"SUB "<<A<<" "<< A<<endl;

	return _asm.str();
}
string modASM(char A, char B, char C, char D, char E){//A:=A%B zlozonosc O(log(n))
    
    string j = createID();

    stringstream _asm;
    
    _asm<<"JZERO "<<B<<" "<<j<<"+[21]"<<" #"<<j<<endl; //jesli dzielnik=0 to hop na koniec
    _asm<<"COPY "<<C<<" "<< A<<endl;
    _asm<<"SUB "<<E<<" "<< E<<endl;
    _asm<<"INC "<<E<<endl;
    _asm<<"SUB "<<A<<" "<< B<<endl;
    _asm<<"JZERO "<<A<<" "<<j<<"+[10]"<<endl;
    _asm<<"COPY "<<A<<" "<< C<<endl;
    _asm<<"ADD "<<B<<" "<< B<<endl;
    _asm<<"ADD "<<E<<" "<< E<<endl;
    _asm<<"JUMP "<<j<<"+[4]"<<endl;
    _asm<<"COPY "<<D<<" "<< B<<endl;
    _asm<<"SUB "<<B<<" "<< C<<endl;
    _asm<<"JZERO "<<B<<" "<<j<<"+[14]"<<endl;
    _asm<<"JUMP "<<j<<"+[16]"<<endl;
    _asm<<"SUB "<<C<<" "<< D<<endl;
    _asm<<"ADD "<<A<<" "<< E<<endl;
    _asm<<"COPY "<<B<<" "<< D<<endl;
    _asm<<"HALF "<<B<<endl;
    _asm<<"HALF "<<E<<endl;
    _asm<<"JZERO "<<E<<" "<<j<<"+[23]"<<endl;
    _asm<<"JUMP "<<j<<"+[10]"<<endl;
    _asm<<"SUB "<<A<<" "<<A<<endl;
    _asm<<"JUMP "<<j<<"+[24]"<<endl;
    _asm<<"COPY "<<A<<" "<<C<<endl;

    return _asm.str();
}

string mulASM(char A, char B, char C){//A:=A*B zlozonosc O(log(n))
    string j = createID();

    stringstream _asm;

    _asm<<"COPY "<<C<<" "<<A<<" #"<<j<<endl;
    _asm<<"SUB "<<A<<" "<< B<<endl;
    _asm<<"JZERO "<<A<<" "<<j<<"+[6]"<<endl;
    _asm<<"COPY "<<A<<" "<< B<<endl;
    _asm<<"COPY "<<B<<" "<< C<<endl;
    _asm<<"JUMP "<<j<<"+[7]"<<endl;
    _asm<<"COPY "<<A<<" "<< C<<endl;
    _asm<<"SUB "<<C<<" "<< C<<endl;
    _asm<<"JZERO "<<A<<" "<<j<<"+[17]"<<endl;
    _asm<<"JODD "<<A<<" "<<j<<"+[13]"<<endl;
    _asm<<"HALF "<<A<<endl;
    _asm<<"ADD "<<B<<" "<< B<<endl;
    _asm<<"JUMP "<<j<<"+[8]"<<endl;
    _asm<<"ADD "<<C<<" "<< B<<endl;
    _asm<<"HALF "<<A<<endl;
    _asm<<"ADD "<<B<<" "<< B<<endl;
    _asm<<"JUMP "<<j<<"+[8]"<<endl;
    _asm<<"COPY "<<A<<" "<< C<<endl;
    
    return _asm.str();
}

//Ponizsze działania logiczne zwracaja wynik 1 dla prawdy i 0 dla falszu

//equal - 3 rejestry
string equalASM(char A, char B, char C){//A:= A=B
    string j = createID();

    stringstream _asm;

    _asm<<"COPY "<<C<<" "<< A<<" #"<<j<<endl;
    _asm<<"SUB "<<A<<" "<< B<<endl;
    _asm<<"JZERO "<<A<<" "<< j<<"+[4]"<<endl;
    _asm<<"JUMP "<<j<<"+[6]"<<endl;
    _asm<<"SUB "<<B<<" "<< C<<endl;
    _asm<<"JZERO "<<B<<" "<<j<<"+[8]"<<endl;
    _asm<<"SUB "<<A<<" "<< A <<endl;
    _asm<<"JUMP "<<j<<"+[9]"<<endl;
    _asm<<"INC "<<A<<endl;

    return _asm.str();
}

string nonequalASM(char A, char B, char C){//A:= A!=B
    string j = createID();

    stringstream _asm;

    _asm<<"COPY "<<C<<" "<< A<<" #"<<j<<endl;
    _asm<<"SUB "<<A<<" "<< B<<endl;
    _asm<<"JZERO "<<A<<" "<< j<<"+[4]"<<endl;
    _asm<<"JUMP "<<j<<"+[6]"<<endl;
    _asm<<"SUB "<<B<<" "<< C<<endl;
    _asm<<"JZERO "<<B<<" "<<j<<"+[8]"<<endl;
    _asm<<"SUB "<<A<<" "<< A <<endl;
    _asm<<"INC "<<A<<endl;

    return _asm.str();
}

string moreASM(char A, char B){//A:= A>B
    string j = createID();

    stringstream _asm;

    _asm<<"SUB "<<A<<" "<< B<<" #"<< j<<endl;
    _asm<<"JZERO "<<A<<" "<<j<<"+[3]"<<endl;
    _asm<<"INC "<<A<<endl;
    
    return _asm.str();
}

string lessASM(char A, char B){//A:=A<B
    
    string j = createID();

    stringstream _asm;

    _asm<<"SUB "<<B<<" "<< A<<" #"<< j<<endl;
    _asm<<"SUB "<<A<<" "<< A<<endl;
    _asm<<"JZERO "<<B<<" "<<j<<"+[4]"<<endl;
    _asm<<"INC "<<A<<endl;
    
    return _asm.str();
}

string moreequalASM(char A, char B){//A:=A>=B
    
    string j = createID();

    stringstream _asm;

    _asm<<"SUB "<<B<<" "<< A<<" #"<< j<<endl;
    _asm<<"JZERO "<<B<<" "<<j<<"+[4]"<<endl;
    _asm<<"SUB "<<A<<" "<< A<<endl;
    _asm<<"JUMP "<<j<<"+[5]"<<endl;
    _asm<<"INC "<<A<<endl;
    
    return _asm.str();
}

string lessequalASM(char A, char B){//A:=A<=B
    string j = createID();

    stringstream _asm;

    _asm<<"SUB "<<A<<" "<< B<<" #"<< j<<endl;
    _asm<<"JZERO "<<A<<" "<<j<<"+[4]"<<endl;
    _asm<<"SUB "<<A<<" "<< A<<endl;
    _asm<<"JUMP "<<j<<"+[5]"<<endl;
    _asm<<"INC "<<A<<endl;
    
    return _asm.str();
}

//ponizsze funkcje umozliwiaja rozpoznanie rodzaju zmiennej podczas opercji assign i read

string arr(string s1, string s2){
    stringstream ss;
    ss<<s1<<endl<<s2;
    return ss.str();
}

string arrnum(string s1, string s2){
    stringstream ss;
    ss<<s1<<endl<<s2<<endl;
    return ss.str();
}

string num3(string s){
    stringstream ss;
    ss<<s<<endl<<endl<<endl;
    return ss.str();
}
