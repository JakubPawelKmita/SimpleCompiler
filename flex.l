/*
 * Kod z analiza leksykalna kompilatora do projektu z JFTT2018
 *
 * Autor: Jakub Kmita
*/

%{
#include "definitions.hpp"
%}
%option yylineno
%%
\;				{ return SEMICOLON; }
:               { return COLON; 	}
:=              { return ASSIGN; 	}

=               { return EQUAL; 	}
!=              { return NONEQUAL; 	}
"<"             { return LESS; 		}
">"             { return MORE; 		}
"<="            { return LESSEQUAL; }
">="            { return MOREEQUAL; }

\+              { return PLUS; 		}
-               { return MINUS; 	}
\*              { return STAR; 		}
\/              { return SLASH; 	}
"%"             { return PERCENT; 	}
"("             { return L_BRACKET; }
")"             { return R_BRACKET; }

[A-Z]+	{
		std::string KW(yytext);
		     if(KW == "DECLARE")	return DECLARE;
		else if(KW == "IN")		return IN;
		else if(KW == "END")		return END;
		else if(KW == "IF")		return IF;
		else if(KW == "THEN")    	return THEN;
		else if(KW == "ELSE")  		return ELSE;
		else if(KW == "ENDIF")  	return ENDIF;
		else if(KW == "WHILE") 		return WHILE;
		else if(KW == "ENDWHILE") 	return ENDWHILE;
		else if(KW == "DO")    		return DO;
		else if(KW == "ENDDO") 		return ENDDO;
		else if(KW == "FOR") 		return FOR;//zliczać?
		else if(KW == "ENDFOR") 	return ENDFOR;
		else if(KW == "FROM") 		return FROM;
		else if(KW == "TO") 		return TO;
		else if(KW == "DOWNTO") 	return DOWNTO;
		else if(KW == "READ")  		return READ;
		else if(KW == "WRITE") 		return WRITE;
		else std::cout<<"ERROR, invalid KeyWord: "<<yytext<<std::endl;
	}

[[:digit:]]+    {yylval = std::string(yytext); return NUM; }
[_a-z]+         {yylval = std::string(yytext); return PIDENTIFIER; }

\r|\r\n|\n		{ /*ignore newlines*/ }
[[:space:]]|\t	{ /*ignore whitespaces*/ }
\[[^\[\]]*\]	{ /*ignore comments*/ }
.				{ std::cerr<<"ERROR at line "<<yylineno<<"\ninvalid character"<<std::endl; exit(1);}

%%

int yywrap(void) {
    return 1;
}
