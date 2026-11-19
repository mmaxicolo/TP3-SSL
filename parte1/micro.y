%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct simbolo {
    char *nombre;
    struct simbolo *siguiente;
} Simbolo;

int yylex(void);
int yylex_destroy(void);
void yyerror(const char *mensaje);
extern FILE *yyin;
extern char *yytext;

int errores_lexicos;
static int errores_sintacticos;
static int errores_semanticos;
static Simbolo *tabla;

static Simbolo *agregar(Simbolo *lista, char *nombre);
static void liberar(Simbolo *lista);
static Simbolo *buscar(const char *nombre);
static void inicializar(char *nombre);
static int verificar_uso(const char *nombre, int linea);
%}

%locations
%union {
    char *texto;
    int valido;
    struct simbolo *lista;
}

%token INICIO FIN LEER ESCRIBIR ASIGNACION CONSTANTE
%token <texto> ID
%type <valido> expresion primaria
%type <lista> lista_identificadores
%destructor { free($$); } <texto>
%destructor { liberar($$); } <lista>

%%
programa:
    INICIO lista_sentencias FIN
;

lista_sentencias:
    sentencia
  | lista_sentencias sentencia
;

sentencia:
    ID ASIGNACION expresion ';'
    {
        if ($3)
            inicializar($1);
        else
            free($1);
    }
  | LEER '(' lista_identificadores ')' ';'
    {
        while ($3 != NULL) {
            Simbolo *actual = $3;
            $3 = actual->siguiente;
            inicializar(actual->nombre);
            free(actual);
        }
    }
  | ESCRIBIR '(' lista_expresiones ')' ';'
  | error ';' { yyerrok; }
;

lista_identificadores:
    ID                            { $$ = agregar(NULL, $1); }
  | lista_identificadores ',' ID  { $$ = agregar($1, $3); }
;

lista_expresiones:
    expresion
  | lista_expresiones ',' expresion
;

expresion:
    primaria                       { $$ = $1; }
  | expresion operador primaria   { $$ = $1 && $3; }
;

operador:
    '+'
  | '-'
;

primaria:
    ID                { $$ = verificar_uso($1, @1.first_line); free($1); }
  | CONSTANTE         { $$ = 1; }
  | '(' expresion ')' { $$ = $2; }
;
%%

static Simbolo *agregar(Simbolo *lista, char *nombre)
{
    Simbolo *nuevo = malloc(sizeof *nuevo);
    if (nuevo == NULL) {
        fprintf(stderr, "No hay memoria suficiente.\n");
        exit(2);
    }
    nuevo->nombre = nombre;
    nuevo->siguiente = lista;
    return nuevo;
}

static void liberar(Simbolo *lista)
{
    while (lista != NULL) {
        Simbolo *actual = lista;
        lista = actual->siguiente;
        free(actual->nombre);
        free(actual);
    }
}

static Simbolo *buscar(const char *nombre)
{
    for (Simbolo *actual = tabla; actual != NULL; actual = actual->siguiente) {
        if (strcmp(actual->nombre, nombre) == 0)
            return actual;
    }
    return NULL;
}

/* Rutina semantica 1: registra un identificador inicializado en la Tabla de Simbolos */
static void inicializar(char *nombre)
{
    if (buscar(nombre) == NULL)
        tabla = agregar(tabla, nombre);
    else
        free(nombre);
}

/* Rutina semantica 2: verifica que un identificador usado en una expresion exista en la Tabla de Simbolos */
static int verificar_uso(const char *nombre, int linea)
{
    if (buscar(nombre) != NULL)
        return 1;
    fprintf(stderr, "Error semantico (linea %d): '%s' se usa antes de inicializarse.\n",
            linea, nombre);
    ++errores_semanticos;
    return 0;
}

void yyerror(const char *mensaje)
{
    if (strcmp(mensaje, "memory exhausted") == 0) {
        fprintf(stderr, "No hay memoria suficiente.\n");
        return;
    }

    const char *encontrado = yychar == YYEOF ? "fin de archivo" : yytext;
    fprintf(stderr, "Error sintactico (linea %d): token inesperado '%s'.\n",
            yylloc.first_line, encontrado);
    ++errores_sintacticos;
}

int main(int argc, char **argv)
{
    if (argc != 2) {
        fprintf(stderr, "Uso: %s archivo.micro\n", argv[0]);
        return 2;
    }

    yyin = fopen(argv[1], "r");
    if (yyin == NULL) {
        perror(argv[1]);
        return 2;
    }

    int resultado = yyparse();
    fclose(yyin);
    yylex_destroy();
    liberar(tabla);

    if (resultado == 2)
        return 2;
    if (resultado == 0 && errores_lexicos + errores_sintacticos + errores_semanticos == 0) {
        puts("Programa Micro correcto.");
        return 0;
    }

    printf("Programa rechazado. Lexicos: %d | Sintacticos: %d | Semanticos: %d\n",
           errores_lexicos, errores_sintacticos, errores_semanticos);
    return 1;
}
