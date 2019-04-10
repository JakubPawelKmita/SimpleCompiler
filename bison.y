/*
 * Kod z gramatyką kompilatora do projektu z JFTT2018
 *
 * Autor: Jakub Kmita
*/

%{
#include "definitions.hpp"
#include "fun.hpp"
#include <fstream>
#include <regex>

extern FILE * yyin;
extern FILE * yyout;

std::string labelASM;

unsigned long long valIt=1; //marker iterujący po pamięci
std::map<std::string, unsigned long long> variables; //<nazwa zmiennej, miejsce w pamięci>
std::map<unsigned long long, bool> hValue; //<miejsce w pamięci, czy jest zainicjalizowana>
std::map<std::string, bool> isIterator; //czy zmienna jest iteratorem
std::map<std::string, bool> isArray; //czy zmienna jest tablicą
std::map<std::string, unsigned long long> arrayMinimum; //wartość minimalna tablicy

void decl(std::string str){
	variables[str]=valIt++;
}
void declTAB(std::string name, unsigned long long arr_beg, unsigned long long arr_end){
	variables[name]=valIt++;
	arrayMinimum[name]=arr_beg;
	unsigned long long s = arr_end-arr_beg;
	valIt+=s;
	isArray[name]=true;
}
bool isDeclared(std::string str){
    if(variables[str]==0){
        return false;
    } else {
        return true;
    }
}

bool hasValue(std::string str){
	return hValue[variables[str]];
}
void initial(std::string str){
	hValue[variables[str]]=true;
}

std::string myLOAD(std::string value, char rejestr){
	std::stringstream ss, out;
	unsigned long long num;
	std::string x, y;
	switch(countLines(value)){
		case 0: //zmienna
			out<<create_constantASM(variables[value],'A');
			out<<"LOAD "<< rejestr<<std::endl;
			return out.str();
		break;
		case 1: //x(y)
			ss<<value;
			ss>>x;
			ss>>y;
			out<<create_constantASM(variables[y], 'A');
			out<<"LOAD "<< rejestr<<std::endl;
			out<<create_constantASM(arrayMinimum[x], 'A');
			out<<"SUB "<<rejestr<<" A"<<std::endl;
			out<<create_constantASM(variables[x], 'A');
			out<<"ADD "<< 'A'<<" "<<rejestr<<std::endl;
			out<<"LOAD "<< rejestr<<std::endl;
			return out.str();
		break;
		case 2: //x(liczba)
			ss<<value;
			ss>>x;
			ss>>num;
			num=variables[x]+num-arrayMinimum[x];
			out<<create_constantASM(num, 'A');
			out<<"LOAD "<< rejestr<<std::endl;
			return out.str();
		break;
		case 3: //liczba
			ss<<value;
			ss>>num;
			return create_constantASM(num, rejestr);
		break;
		default:
		return value;
		break;
	} 
}

std::string iteratorSTORE(std::string value, char rejestr){
	std::stringstream out;
	out<<create_constantASM(variables[value],'A');
	out<<"STORE "<< rejestr<<std::endl;
	return out.str();
}

std::string mySTORE(std::string value, char rejestr, char pomoc){
	std::stringstream ss, out;
	unsigned long long num;
	std::string x, y;
	switch(countLines(value)){
		case 0: //zmienna lub iterator
			if(isIterator[value]){ //sprawdza czy nie uzywamy iteratora w ASSIGN lub READ
				std::cerr<<"ERROR at line "<<yylineno<<"\n";
				std::cerr<<"violation of the iterator named "<<value<<"\n";
				exit(1);
			}
			initial(value);
			out<<create_constantASM(variables[value],'A');
			out<<"STORE "<< rejestr<<std::endl;
			return out.str();
		break;
		case 1: //x(y)
			ss<<value;
			ss>>x;
			ss>>y;
			initial(x); //inicjalizacja tablicy nastepuje w momencie zainicjalizowania jakiejkolwiek zmiennej z tej tablicy
			out<<create_constantASM(variables[y], 'A');
			out<<"LOAD "<< pomoc<<std::endl;
			out<<create_constantASM(arrayMinimum[x], 'A');
			out<<"SUB "<<pomoc<<'A'<<std::endl;
			out<<create_constantASM(variables[x], 'A');
			out<<"ADD "<< 'A'<<" "<<pomoc<<std::endl;
			out<<"STORE "<< rejestr<<std::endl;
			return out.str();
		break;
		case 2: //x(liczba)
			ss<<value;
			ss>>x;
			ss>>num;
			initial(x); //inicjalizacja tablicy
			num=variables[x]+num-arrayMinimum[x];
			out<<create_constantASM(num, 'A');
			out<<"STORE "<< rejestr<<std::endl;
			return out.str();
		break;
		default:
			return value;
		break;
	}
}

%}

%define api.value.type {std::string}
%define parse.error verbose
%locations

%token SEMICOLON
%token COLON
%token ASSIGN

%token EQUAL
%token NONEQUAL
%token LESS
%token MORE
%token LESSEQUAL
%token MOREEQUAL

%token PLUS
%token MINUS
%token STAR
%token SLASH
%token PERCENT
%token L_BRACKET
%token R_BRACKET

// keywords:
%token DECLARE
%token IN
%token END
%token IF
%token THEN
%token ELSE
%token ENDIF
%token WHILE
%token ENDWHILE
%token DO
%token ENDDO
%token FOR
%token ENDFOR
%token FROM
%token TO
%token DOWNTO
%token READ
%token WRITE

%token NUM
%token PIDENTIFIER

%%

program:
	DECLARE declarations IN commands END
		{
			std::stringstream ss;
			ss<<$4<<"HALT\n";
			labelASM=ss.str();
		};

declarations:
	declarations pidentifier SEMICOLON
		{
			if(isDeclared($2)){
				std::cerr<<"ERROR at line "<<yylineno<<"\n";
				std::cerr<<"Second declaration of variable named "<<$2<<"\n";
				exit(1);
			}else{
				decl($2);
			}
		}|
	declarations pidentifier L_BRACKET num COLON num R_BRACKET SEMICOLON
		{
			unsigned long long arr_beg, arr_end;
			std::stringstream ss;
			ss<<$4<<std::endl;
			ss>>arr_beg;
			ss<<$6<<std::endl;
			ss>>arr_end;

			if(arr_beg>arr_end){
				std::cerr<<"ERROR at line "<<yylineno<<"\n";
				std::cerr<<"Wrong array declaration: "<<$2<<"("<<arr_beg<<" > "<<arr_end<<")\n";
				exit(1);
			}
			
			if(isDeclared($2)){
				std::cerr<<"ERROR at line "<<yylineno<<"\n";
				std::cerr<<"Second declaration of array named "<<$2<<"\n";
				exit(1);
			} else{
				declTAB($2, arr_beg, arr_end);
			}
		}|
	%empty {};

commands: 
	commands command
		{
			std::stringstream ss;
			ss<<$1<<$2;
			$$=ss.str();
		}|
	command
		{$$=$1;};
command:
	identifier ASSIGN expression SEMICOLON
		{
			std::stringstream out;
			out<<$3<<mySTORE($1, 'B', 'C');
			$$=out.str();
		}|
	IF condition THEN commands ELSE commands ENDIF
		{
			std::string id = createID();
			std::stringstream ss;
			ss<<$2;
			ss<<"JZERO B "<<id<<"+[1]"<<std::endl;
			ss<<$4;
			ss<<"JUMP "<<id<<"+["<<countLines($6)+1<<"] #"<<id<<std::endl;
			ss<<$6;
			$$=ss.str();
		}|
	IF condition THEN commands ENDIF
		{
			std::string id = createID();
			std::stringstream ss;
			ss<<$2;
			ss<<"JZERO B "<<id<<"+["<<countLines($4)+1<<"] #"<<id<<std::endl;
			ss<<$4;
			$$=ss.str();
		}|
	WHILE condition DO commands ENDWHILE
		{
			int commandsCount = countLines($4);
			int conditionCount = countLines($2);
			std::string id = createID();
			std::stringstream out;
			out<<$2;
			out<<"JZERO B "<<id<<"+["<<commandsCount+2<<"] #"<<id<<std::endl;
			out<<$4;
			out<<"JUMP "<<id<<"-["<<conditionCount<<"]"<<std::endl;
			$$=out.str();
		}|
	DO commands WHILE condition ENDDO
		{
			int commandsCount = countLines($2);
			int conditionCount = countLines($4);
			std::string id = createID();
			std::stringstream out;
			out<<$2;
			out<<$4;
			out<<"JZERO B "<<id<<"+["<<commandsCount+2<<"] #"<<id<<std::endl;
			out<<$2;
			out<<"JUMP "<<id<<"-["<<conditionCount<<"]"<<std::endl;
			$$=out.str();
		}|
	FOR it FROM value TO value DO commands ENDFOR
		{//ok, it jest legalnym iteratorem na tym etapie, sprawdzam to gdy tylko znajdę it, niżej jako pidentyfikator
		 // teraz należy stworzyć kopie $4 i $6, bo ich zmiana w pętli ma nie wpływać na ilość przebiegów pętli

			std::string id = createID();
			std::string id2 = createID();
			std::stringstream out;
			
			out<<myLOAD($6, 'C');
			out<<myLOAD($4, 'B');
			out<<iteratorSTORE($2+"END", 'C');

			out<<"DEC A"<<" #"<<id2<<std::endl; //tu bedziemy skakac na poczatek petli
			out<<"STORE B\n";//ok, iterator i iteratorEND zaladowane, storujemy iterator

			out<<$8;

			out<<myLOAD($2, 'B');
			out<<"INC A\n"<<"LOAD C\n"; //out<<myLOAD($2+"END", 'C');
			out<<"SUB C B\n";
			out<<"JZERO C "<<id<<"+[3] #"<<id<<std::endl;//wyskocz z pętli
			out<<"INC B\n";
			out<<"JUMP "<<id2<<"\n";//kontynuuj pętle
			
			$$=out.str();

			/*zwalnianie iteratora, by mógł być użyty ponownie w innej, nie wewnętrznej pętli*/
			isIterator[$2]=false;
			hValue[variables[$2]]=false; hValue[variables[$2+"END"]]=false;
			variables[$2]=0; variables[$2+"END"]=0;
			valIt-=2; //cofam marker o dwa, iterator i iteratorEND
		}|
	FOR it FROM value DOWNTO value DO commands ENDFOR
		{
			std::string id = createID();
			std::string id2 = createID();
			std::stringstream out;
			
			out<<myLOAD($6, 'C');
			out<<myLOAD($4, 'B');
			out<<iteratorSTORE($2+"END", 'C');

			out<<"DEC A"<<" #"<<id2<<std::endl; //tu bedziemy skakac na poczatek petli
			out<<"STORE B\n";//ok, iterator i iteratorEND zaladowane, storujemy iterator

			out<<$8;

			out<<myLOAD($2, 'B');
			out<<"COPY D B\n";
			out<<"INC A\n"<<"LOAD C\n";
			out<<"SUB D C\n";
			out<<"JZERO D "<<id<<"+[3] #"<<id<<std::endl;//wyskocz z pętli
			out<<"DEC B\n";
			out<<"JUMP "<<id2<<"\n";//kontynuuj pętle
			
			$$=out.str();

			/*zwalnianie iteratora, by mógł być użyty ponownie w innej, nie wewnętrznej pętli*/
			isIterator[$2]=false;
			hValue[variables[$2]]=false; hValue[variables[$2+"END"]]=false;
			variables[$2]=0; variables[$2+"END"]=0;
			valIt-=2;
		}|
	READ identifier SEMICOLON
		{
			std::stringstream out;
			out<<"GET B"<<std::endl;
			out<<mySTORE($2, 'B', 'C');
			$$=out.str();
		}|
	WRITE value SEMICOLON
		{
			std::stringstream out;
			out<<myLOAD($2, 'B');
			out<<"PUT B"<<std::endl;
			$$=out.str();
		};

expression:
	value
		{
			$$=myLOAD($1, 'B');
		}|
	value PLUS value
		{
			std::stringstream out;
			if($1==$3){
				out<<myLOAD($1, 'B')<<addASM('B','B');
			} else {
				out<<myLOAD($1, 'B')<<myLOAD($3, 'C')<<addASM('B','C');
			}
			$$=out.str();
		}|
	value MINUS value
		{
			std::stringstream out;
			if($1==$3){
				out<<"SUB B B\n";
			} else {
				out<<myLOAD($1, 'B')<<myLOAD($3, 'C')<<subASM('B','C');
			}
			$$=out.str();
		}|
	value STAR value
		{
			std::stringstream out;
			if($1==$3){
				out<<myLOAD($1, 'B')<<"COPY C B\n"<<mulASM('B','C','D');
			} else {
				out<<myLOAD($1, 'B')<<myLOAD($3, 'C')<<mulASM('B','C','D');
			}
			$$=out.str();
		}|
	value SLASH value
		{
			std::stringstream out;
			if($1==$3){
				out<<myLOAD($1, 'B')<<"COPY C B\n"<<divASM('B','C','D','E','F');
			} else {
			out<<myLOAD($1, 'B')<<myLOAD($3, 'C')<<divASM('B','C','D','E','F');
			}
			$$=out.str();
		}|
	value PERCENT value
		{
			std::stringstream out;
			if($1==$3){
				out<<myLOAD($1, 'B')<<"COPY C B\n"<<modASM('B','C','D','E','F');
			} else {
			out<<myLOAD($1, 'B')<<myLOAD($3, 'C')<<modASM('B','C','D','E','F');
			}
			$$=out.str();
		};

condition:
	value EQUAL value
		{
			std::stringstream out;
			if($1==$3){
				out<<"INC B\n";
			} else {
				out<<myLOAD($1, 'B')<<myLOAD($3, 'C')<<equalASM('B','C','D');
			}
			$$=out.str();
		}|
	value NONEQUAL value
		{
			std::stringstream out;
			if($1==$3){
				out<<"SUB B B\n";
			} else {
				out<<myLOAD($1, 'B')<<myLOAD($3, 'C')<<nonequalASM('B','C','D');
			}
			$$=out.str();
		}|
	value LESS value
		{
			std::stringstream out;
			if($1==$3){
				out<<"SUB B B\n";
			} else {
				out<<myLOAD($1, 'B')<<myLOAD($3, 'C')<<lessASM('B','C');
			}
			$$=out.str();
		}|
	value MORE value
		{
			std::stringstream out;
			if($1==$3){
				out<<"SUB B B\n";
			} else {
				out<<myLOAD($1, 'B')<<myLOAD($3, 'C')<<moreASM('B','C');
			}
			$$=out.str();
		}|
	value LESSEQUAL value
		{
			std::stringstream out;
			if($1==$3){
				out<<"INC B\n";
			} else {
				out<<myLOAD($1, 'B')<<myLOAD($3, 'C')<<lessequalASM('B','C');
			}
			$$=out.str();
		}|
	value MOREEQUAL value
		{
			std::stringstream out;
			if($1==$3){
				out<<"INC B\n";
			} else {
				out<<myLOAD($1, 'B')<<myLOAD($3, 'C')<<moreequalASM('B','C');
			}
			$$=out.str();
		};

value:
	num
		{$$=num3($1);}|
	identifier
		{//sprawdzanie czy zmienna jest zainicjalizowana
			std::stringstream x;
			std::string a, b;
			switch(countLines($1)){
				case 0:
					if(!hasValue($1)){
						std::cerr<<"WARNING at line "<<yylineno<<"\n";
						std::cerr<<"variable named "<<$1<<" may not be initialized\n";
					}
				break;
				case 1: //tab(var)
					x<<$1;
					x>>a;
					x>>b;
					if(!hasValue(b)){
						std::cerr<<"WARNING at line "<<yylineno<<"\n";
						std::cerr<<"variable named "<<b<<" may not be initialized\n";
					}
				break;
				case 2: //tab(num) - tu warto by sprawdzac, czy num nie wychodzi poza zakres tablicy
					
				break;
			}
			$$=$1;
		};

identifier:
	pidentifier
		{	
			if(isDeclared($1)){
				if(isArray[$1]){
					std::cerr<<"ERROR at line "<<yylineno<<"\n";
					std::cerr<<"using array named "<<$1<<" as variable\n";
					exit(1);
				} else {
					$$=$1;
					} 
			} else {
				std::cerr<<"ERROR at line "<<yylineno<<"\n";
				std::cerr<<"variable named "<<$1<<" was not declared in DECLARE section\n";
				exit(1);
			}
		}|
	pidentifier L_BRACKET pidentifier R_BRACKET //jest na fb
		{
			if(isDeclared($1)){
				if(isDeclared($3))
					if(hasValue($3))
						if(isArray[$1]){
							$$=arr($1, $3);
						} else {
							std::cerr<<"ERROR at line "<<yylineno<<"\n";
							std::cerr<<"using variable named "<<$1<<" as an array\n";
							exit(1);
						}
					else{
						std::cerr<<"WARNING at line "<<yylineno<<"\n";
						std::cerr<<"variable named "<<$3<<" may not be initialized\n";
					}
				else{
					std::cerr<<"ERROR at line "<<yylineno<<"\n";
					std::cerr<<"variable named "<<$3<<" was not declared in DECLARE section\n";
					exit(1);
				}
			}else{
				std::cerr<<"ERROR at line "<<yylineno<<"\n";
				std::cerr<<"array named "<<$1<<" was not declared in DECLARE section\n";
				exit(1);
			}
		}|
	pidentifier L_BRACKET num R_BRACKET 
		{	
			if(isDeclared($1)){
				if(isArray[$1]){
					$$=arrnum($1, $3);
				} else {
					std::cerr<<"ERROR at line "<<yylineno<<"\n";
					std::cerr<<"using variable named "<<$1<<" as an array\n";
					exit(1);
				}
			}else{
				std::cerr<<"ERROR at line "<<yylineno<<"\n";
				std::cerr<<"array named "<<$1<<" was not declared in DECLARE section\n";
				exit(1);
			}
		};
it:
	pidentifier
		{
			if(isIterator[$1]){
				std::cerr<<"ERROR at line "<<yylineno<<"\n";
				std::cerr<<"re-use of the iterator: "<<$1<<" in the local inner loop\n";
				exit(1);
			} else if(isDeclared($1)){
				std::string typ;
				if(isArray[$1]) typ="array";
				else typ="variable";
				std::cerr<<"ERROR at line "<<yylineno<<"\n";
				std::cerr<<"ERROR: using the declared "<<typ<<" named "<<$1<<" as an iterator\n";
				exit(1);
			}
			
			$$=$1; 
			decl($1); decl($1+"END");
			initial($1); initial($1+"END");
			isIterator[$1]=true; //trzymam pidentifier jako iterator do momentu aż zostanie zwolniony w forze, żeby wewnętrzny for go nie mógł użyć
		};

num:
	NUM
		{$$=$1;};

pidentifier:
	PIDENTIFIER
		{$$=$1;};

%%
void yyerror(const char *syntaxErrorMessage)
{
	std::cerr<<"ERROR at line "<<yylineno<<"\n";
	std::cerr<<syntaxErrorMessage<<"\n";
    exit(1);
}
int main(int argc, char *argv[]) {
	if(argc<2){
		std::cerr<<"WRONG CALL\nmissing in & out file\nShould be: ./kompilator <in?> <out?>\n";
		return 0;
	}
	if(argc<3){
		std::cerr<<"WRONG CALL\nmissing out file\nShould be: ./kompilator "<<argv[1]<<" <out?>\n";
		return 0;
	}
	if(argc>3){
		std::cerr<<"WARNING\ntoo many arguments\nShould be: ./kompilator "<<argv[1]<<" "<<argv[2]<<"\n";
	}

	yyin = fopen(argv[1], "r");
    
	yyparse();

	//ponizej podmieniam etykiety na skoki w konkretne miejsca w kodzie
	std::map<std::string, unsigned long long> labelDecl;
	unsigned long long c = countLines(labelASM);
	std::string instructions[c];
	unsigned long long a = 0;
	
	for(unsigned long long i=0; i<labelASM.length(); ++i){
		if(labelASM[i]=='#'){
			int e=0;
			while(labelASM[i+e]!='\n'){
				e++;
			}
			labelDecl[labelASM.substr(i+1,e-1)]=a;
		}
		if(labelASM[i]=='\n'){
			a++;
		}
	}

	std::stringstream ss(labelASM);
	std::string to;
	unsigned long long i = 0;
	while(std::getline(ss,to,'\n')){
		instructions[i]=to;
		++i;
    }

	std::regex r_id("\\[ID:[0-9]*\\]");
	std::regex r_sign("[+-]");
	std::regex r_num("\\[[0-9]+\\]");
	for(unsigned long long i=0; i<c;++i){
		to=instructions[i];
		if(to[0]=='J'){
			std::smatch id;
			std::smatch num;
			std::smatch sign;
			unsigned long long k=0;

			std::regex_search(to, id, r_id);

			if(std::regex_search(to, sign, r_sign)){
				//podmiana ze znakiem
				std::regex_search(to, num, r_num);
				k=std::stoi( num.str().substr(1, num.str().length()-2));
				if( sign.str()=="+"){
					k+=labelDecl[id.str()];
				} else{
					k=labelDecl[id.str()]-k;
				}
			}else{
				//podmiana bez znaku
				k=labelDecl[id.str()];
			}

			std::stringstream ss;

			if(to[1]=='U'){
				//JUMP
				ss<<"JUMP "<<k;
			}else{
				//JODD i JZERO
				if(to[1]=='Z'){
					ss<<"JZERO "<<to[6]<<" "<<k;
				} else{
					ss<<"JODD "<<to[5]<<" "<<k;
				}
			}
			instructions[i] = ss.str();
		}
	}

	//Etykiety zostaly podmienione, program skompilowany wiec mozna drukowac
	std::ofstream myfile(argv[2]);
  	if (myfile.is_open()){
		for(unsigned long long i=0; i<c;++i){
			myfile << instructions[i]<<std::endl;
		}
		myfile.close();
	}
	else std::cerr << "Unable to open output file" << std::endl;
	return 0;
}
