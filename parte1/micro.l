%option noyywrap nounput noinput yylineno never-interactive

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "micro.tab.h"

extern int errores_lexicos;

#define YY_USER_ACTION yylloc.first_line = yylineno;

static char *copiar_lexema(void)
{
    char *copia = malloc((size_t)yyleng + 1);
    if (copia == NULL) {
        fprintf(stderr, "No hay memoria suficiente.\n");
        exit(2);
    }
    memcpy(copia, yytext, (size_t)yyleng + 1);
    return copia;
}
%}



LETRA       [a-zA-Z]
DIGITO      [0-9]
IDENT       {LETRA}({LETRA}|{DIGITO})*

%%
"inicio"    { return INICIO; }
"fin"       { return FIN; }
"leer"      { return LEER; }
"escribir"  { return ESCRIBIR; }
":="        { return ASIGNACION; }
{IDENT}     { yylval.texto = copiar_lexema(); return ID; }
{DIGITO}+   { return CONSTANTE; }
[()+,;-]    { return yytext[0]; }
[ \t\r\n]+  { /* Separadores entre tokens. */ }
.           {
                fprintf(stderr, "Error lexico (linea %d): caracter no reconocido '%s'.\n",
                        yylineno, yytext);
                ++errores_lexicos;
                return YYerror;
            }
<<EOF>>     { yylloc.first_line = yylineno; return 0; }
%%
