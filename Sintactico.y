%{
	#include <stdio.h>
	#include <stdlib.h>
	#include <conio.h>
	#include <string.h>
	#include "y.tab.h"

	#include "tabla_simbolos.h"
	#include "tercetos.h"

	#define MAX_ANIDAMIENTOS 10
	#define VALOR_NULO -1

	#define MAX_ANIDAMIENTOS 10

	/* Funciones necesarias */
	int yyerror(char* mensaje);
	int yyerror();
	int yylex();

	void chequearTipoDato(int tipo);
	void resetTipoDato();

	int saltarFalse(int comp);
	int saltarTrue(int comp);
	void apilar_IEP();
	void desapilar_IEP();
	void apilar_IAEA();
	void desapilar_IAEA();
	void ponerSaltosThen();
	void ponerSaltosElse();
	void ponerSaltoEndif();
	void ponerSaltoEndwhile();

	int yystopparser=0;
	FILE  *yyin;

	/* Cosas de tabla de simbolos */
	simbolo tabla_simbolo[TAMANIO_TABLA];
	int fin_tabla = -1; /* Apunta al ultimo registro en la tabla de simbolos. Incrementarlo para guardar el siguiente. */

	/* Cosas para la declaracion de variables y la tabla de simbolos */
	int varADeclarar1 = 0;
	int cantVarsADeclarar = 0;
	int tipoDatoADeclarar;

	/* Cosas para las asignaciones */
	char idAsignar[TAM_NOMBRE];
	/* Cosas para comparadores booleanos */
	int comp_bool_actual;
	/* Cosas para control de tipo de datos en expresiones aritméticas */
	int tipoDatoActual = sinTipo;
	/* Cosas para average */
	int cant;

	/* Cosas para tercetos */
	terceto lista_terceto[MAX_TERCETOS];
	int ultimo_terceto = -1; /* Apunta al ultimo terceto escrito. Incrementarlo para guardar el siguiente. */

	/* Pila de cosas para tercetos */
	typedef struct{
		int ind_sent; //Apilamos la sentencia actual
		int ind_bloque; //Apilamos el bloque actual
		int ind_branch_pendiente;
		int ind_branch_pendiente2;
		int ind_jmp;
		int ind_if;
		int ind_endif;
		int ind_else;
		int ind_then;
		int falseIzq; //Si se pasa por false el bool izquierdo
		int falseDer; //Si se pasa por false el bool derecho
		int verdadero; //Si hay un OR, el lado izq
		int always; //Para los else, y los endwhile
	} info_elemento_pila;

	/* Pila de cosas para AVG */
	typedef struct{
		int ind_rterm;
		int ind_term;
		int ind_pre;
		int ind_factor;
		int ind_avg;
	} info_anidamiento_exp_aritmeticas;

	int falseIzq=VALOR_NULO;
	int falseDer=VALOR_NULO;
	int verdadero=VALOR_NULO;
	int always=VALOR_NULO;
	info_elemento_pila pila_bloques[MAX_ANIDAMIENTOS];
	int ult_pos_pila_bloques=VALOR_NULO;
	info_anidamiento_exp_aritmeticas pila_exp[MAX_ANIDAMIENTOS];
	int ult_pos_pila_exp=VALOR_NULO;

	int pila_ind_xplogic[MAX_ANIDAMIENTOS];
	int ultimo_pila_ind_xplogic=-1;
	int ind_branch_pendiente;
	int ind_branch_pendiente2;
	int ind_if;
	int ind_endif;
	int ind_else;
	int ind_then;
	int ind_jmp;

	int ind_program;
	int ind_sdec;
	int ind_bdec;
	int ind_dec;
	int ind_tdato;
	int ind_list_id;
	int ind_bloque;
	int ind_sent;
	int ind_bif;
	int ind_bwhile;
	int ind_btrue;
	int ind_asig;
	int ind_xp;
	int ind_xpcad;
	int ind_expr; //Expresion aritmetica
	int ind_rterm;
	int ind_term;
	int ind_pre;
	int ind_factor;
	int ind_xplogic;
	int ind_tlogic;
	int ind_tlogic_izq;
	int ind_expr_izq;
	int ind_compbool;
	int ind_avg;
	int ind_inlist;
	int ind_lec; //Lista expresion coma
	int ind_lepc; //Lista expresion punto y coma
	int ind_lectura;
	int ind_escritura;
%}

%union {
	int int_val;
	float float_val;
	char *string_val;
}

%token START
%token END

%token DECVAR ENDDEC
%token INT FLOAT STRING

%token WHILE ENDWHILE
%token IF THEN ELSE ENDIF

%token AND OR NOT

%token ASIG
%left MAS MENOS
%token POR DIVIDIDO

%token MENOR  MAYOR MENOR_IGUAL MAYOR_IGUAL
%token IGUAL DISTINTO

%token PA PC
%token CA CC
%token COMA
%token PUNTO_COMA

%token READ
%token WRITE
%token AVG
%token INLIST

%token <string_val>ID
%token <float_val>CTE_FLOAT
%token <int_val>CTE_INT
%token <string_val>CTE_STRING

%%

programa:
	START seccion_declaracion bloque END 	            {
															printf("\nCOMPILACION EXITOSA\n");
															guardarTabla();

															ind_program = crear_terceto(START, ind_sdec, ind_bloque);
															guardarTercetos();
														};
/*
programa:
	START bloque END									{
															printf("\nCOMPILACION EXITOSA\n");
															guardarTabla();

															ind_program = crear_terceto(START, NOOP, ind_bloque);
														}
*/
/* Declaracion de variables */

seccion_declaracion:
	DECVAR bloque_dec ENDDEC 				            {
															printf("Regla 1: Seccion declaracion es DECVAR bloque_dec ENDEC\n\n");
														};

bloque_dec:
	bloque_dec declaracion					            {printf("Regla 2: bloque_dec es bloque_dec declaracion\n");}
	| declaracion							            {printf("Regla 3: bloque_dec es declaracion\n");};

declaracion:
	t_dato lista_id PUNTO_COMA				            {
															printf("Regla 4: declaracion es t_dato lista_id PUNTO_COMA\n");
															 agregarTiposDatosATabla();
														};

t_dato:
	FLOAT		                                        {
															printf("Regla 5: t_dato es FLOAT\n");
															tipoDatoADeclarar = Float;
														}
	| INT		                                        {
															printf("Regla 6: t_dato es INT\n");
															tipoDatoADeclarar = Int;
														}
	| STRING	                                        {
															printf("Regla 7: t_dato es STRING\n");
															tipoDatoADeclarar = String;
														};

lista_id:
	lista_id COMA ID	                                {
	                                                        printf("Regla 8: lista_id es lista_id COMA ID(%s)\n", $3);
	                                                        agregarVarATabla(yylval.string_val);
															cantVarsADeclarar++;
                                                        }
	| ID				                                {
	                                                        printf("Regla 9: lista_id es ID(%s)\n", $1);
	                                                        agregarVarATabla(yylval.string_val);
															varADeclarar1 = fin_tabla; /* Guardo posicion de primer variable de esta lista de declaracion. */
															cantVarsADeclarar = 1;
                                                        };

 /* Fin de Declaracion de variables */

 /* Seccion de codigo */

bloque:                                                 /* No existen bloques sin sentencias */
	bloque sentencia	                                {
															printf("Regla 10: bloque es bloque sentencia\n");
															ind_bloque = crear_terceto(BLOQ, ind_bloque, ind_sent);
														}
	| sentencia			                                {
															printf("Regla 11: bloque es sentencia\n");
															ind_bloque = ind_sent;
														};

sentencia:
	asignacion PUNTO_COMA			                    {
															printf("Regla 12: sentencia es asignacion PUNTO_COMA\n");
															ind_sent = ind_asig;
														}
	| bloque_if                                         {
															printf("Regla 13: sentencia es bloque_if\n");
															ind_sent = ind_bif;
														}
	| bloque_while                                      {
															printf("Regla 14: sentencia es bloque_while\n");
															ind_sent = ind_bwhile;
														}
	| lectura PUNTO_COMA                                {
															printf("Regla 15: sentencia es lectura PUNTO_COMA\n");
															ind_sent = ind_lectura;
														}
	| escritura PUNTO_COMA                              {
															printf("Regla 16: sentencia es escritura PUNTO_COMA\n");
															ind_sent = ind_escritura;
														}
	| expresion_aritmetica PUNTO_COMA                   {
															printf("Regla 17: sentencia es expresion_aritmetica PUNTO_COMA\n");
															resetTipoDato();
															ind_sent = ind_expr;
														};

rutina_if:
														{
															ind_if=crear_terceto(IF, NOOP, NOOP);
															apilar_IEP();
														};
rutina_then:
														{
															ind_then=crear_terceto(THEN,NOOP,NOOP);
															ponerSaltosThen();
														};
rutina_else:
														{
															ind_jmp = crear_terceto(JMP, NOOP, NOOP);
															always=ind_jmp;
															ind_else = crear_terceto(ELSE,NOOP,NOOP);
															ponerSaltosElse();
														};

bloque_if:
    IF rutina_if expresion_logica THEN rutina_then bloque ENDIF
														{
															printf("Regla 18: bloque_if es IF expresion_logica THEN bloque ENDIF\n\n");
															ind_endif=crear_terceto(ENDIF,NOOP,NOOP);
															ind_else=ind_endif;
															ponerSaltosElse();
															desapilar_IEP();
															ind_bif=ind_if;
															/*ind_xplogic = desapilar_xplogic();
															ind_bif = crear_terceto(IF, ind_xplogic, ind_bloque);*/
														};

bloque_if:
    IF rutina_if expresion_logica THEN rutina_then bloque_true ELSE rutina_else bloque ENDIF
														{
															printf("Regla 19.1: bloque_if es IF expresion_logica THEN bloque ELSE bloque ENDIF\n\n");
															ind_endif=crear_terceto(ENDIF,NOOP,NOOP);
															ponerSaltoEndif();
															desapilar_IEP();
															ind_bif=ind_if;
															//int ind = crear_terceto(THEN, ind_btrue, ind_bloque);
															/*ind_xplogic = desapilar_xplogic();
															ind_bif = crear_terceto(IF, ind_xplogic, ind);*/
														}
	| IF rutina_if expresion_logica THEN rutina_then ENDIF
														{
															printf("Regla 19.2: bloque_if es IF expresion_logica THEN ENDIF\n\n");
															ind_endif=crear_terceto(ENDIF,NOOP,NOOP);
															ind_else=ind_endif;
															ponerSaltosElse();
															desapilar_IEP();
															ind_bif=ind_if;
														/*	ind_xplogic = desapilar_xplogic();
															ind_bif = crear_terceto(IF, ind_xplogic, NOOP);*/
														};

rutina_while:
														{
															ind_bwhile = crear_terceto(WHILE, NOOP, NOOP);
															apilar_IEP();
														};

bloque_while:
    WHILE rutina_while expresion_logica THEN rutina_then bloque ENDWHILE
														{
															printf("Regla 20.1: bloque_while es WHILE expresion_logica THEN bloque ENDWHILE\n\n");
															ind_jmp = crear_terceto(JMP,ind_bwhile,NOOP);
															always = crear_terceto(ENDWHILE, NOOP, NOOP);
															ponerSaltoEndwhile();
															desapilar_IEP();
															/*ind_xplogic = desapilar_xplogic();
															ind_bwhile = crear_terceto(WHILE, ind_xplogic, ind_bloque);*/
														}
	| WHILE rutina_while expresion_logica THEN rutina_then ENDWHILE
														{
															printf("Regla 20.2: bloque_while es WHILE expresion_logica ENDWHILE\n\n");
															ind_jmp = crear_terceto(JMP,ind_bwhile,NOOP);
															always = crear_terceto(ENDWHILE, NOOP, NOOP);
															ponerSaltoEndwhile();
															desapilar_IEP();
															/*ind_xplogic = desapilar_xplogic();
															ind_bwhile = crear_terceto(WHILE, ind_xplogic, NOOP);*/
														};

asignacion:
	ID ASIG {strcpy(idAsignar, $1);} expresion	        {
															printf("Regla 21: asignacion es ID(%s) ASIG expresion\n\n", idAsignar);
															int tipo = chequearVarEnTabla(idAsignar);
															chequearTipoDato(tipo);
															resetTipoDato();
															int pos=buscarEnTabla(idAsignar);
															ind_asig = crear_terceto(ASIG, pos, ind_xp);
														};

bloque_true:
	bloque												{
															printf("Regla 21.1: bloque_true es bloque\n");
															ind_btrue = ind_bloque;
														};

/* Expresiones aritmeticas y otras */

expresion:
	expresion_cadena				                    {
															printf("Regla 22: expresion es expresion_cadena\n");
															ind_xp = ind_xpcad;
														}
	| expresion_aritmetica			                    {
															printf("Regla 23: expresion es expresion_aritmetica\n");
															ind_xp = ind_expr;
														};

expresion_cadena:
	CTE_STRING						                    {
															printf("Regla 24: expresion_cadena es CTE_STRING(%s)\n", $1);
															int pos=agregarCteStringATabla(yylval.string_val);
															ind_xpcad = crear_terceto(NOOP,pos,NOOP);
														};

expresion_aritmetica:
	expresion_aritmetica MAS termino_r 		            {
															printf("Regla 25: expresion_aritmetica es expresion_aritmetica MAS termino_r\n");
															ind_expr = crear_terceto(MAS, ind_expr, ind_rterm);
														}
	| expresion_aritmetica MENOS termino_r 	            {
															printf("Regla 26: expresion_aritmetica es expresion_aritmetica MENOS termino_r\n");
															ind_expr = crear_terceto(MENOS, ind_expr, ind_rterm);
														}
	| termino								            {
															printf("Regla 27: expresion_aritmetica es termino\n");
															ind_expr = ind_term;
														};

termino_r:
	termino POR factor 			                        {
															printf("Regla 28: termino_r es termino POR factor\n");
															ind_rterm = crear_terceto(POR, ind_term, ind_factor);
														}
	| termino DIVIDIDO factor 	                        {
															printf("Regla 29: termino_r es termino DIVIDIDO factor\n");
															ind_rterm = crear_terceto(DIVIDIDO, ind_term, ind_factor);
														}
	| factor					                        {
															printf("Regla 30: termino_r es factor\n");
															ind_rterm = ind_factor;
														};

termino:
	termino_r											{
															printf("Regla 30.1: termino es temrino_r\n");
															ind_term = ind_rterm;
														}
	| pre												{
															printf("Regla 30.2: termino es pre\n");
															ind_term = ind_pre;
														};

pre:
	MAS factor											{
															printf("Regla 30.2: pre es MAS factor\n");
															ind_pre = ind_factor;
														}
	| MENOS factor										{
															printf("Regla 30.3: pre es MENOS factor\n");

															ind_pre = crear_terceto(MENOS, ind_factor, NOOP);
														};

factor:
	PA expresion_aritmetica PC	                        {
															printf("Regla 31: factor es PA expresion_aritmetica PC\n");
															ind_factor = ind_expr;
														}
    | average                                           {
															printf("Regla 32: factor es average\n");
															ind_factor = ind_avg;
														}
	| ID			                                    {
															printf("Regla 33: factor es ID(%s)\n", $1);
															int tipo = chequearVarEnTabla(yylval.string_val);
															chequearTipoDato(tipo);

															int pos = buscarEnTabla($1);
															ind_factor = crear_terceto(NOOP, pos, NOOP);
														}
	| CTE_FLOAT	                                        {
															printf("Regla 34: factor es CTE_FLOAT(%f)\n", $1);
															chequearTipoDato(Float);
															int pos = agregarCteFloatATabla(yylval.float_val);
															ind_factor = crear_terceto(NOOP, pos, NOOP);
														}
	| CTE_INT	                                        {
															printf("Regla 35: factor es CTE_INT(%d)\n", $1);
															chequearTipoDato(Int);
															int pos = agregarCteIntATabla(yylval.int_val);
															ind_factor = crear_terceto(NOOP, pos, NOOP);
														};
/* Expresiones logicas */

expresion_logica:
    termino_logico_izq AND {ind_branch_pendiente = crear_terceto(saltarFalse(comp_bool_actual), ind_tlogic, NOOP); falseIzq=ind_branch_pendiente;}
							termino_logico              {
															printf("Regla 36: expresion_logica es termino_logico AND termino_logico\n");
															ind_branch_pendiente2 =  crear_terceto(saltarFalse(comp_bool_actual), ind_tlogic, NOOP);
															falseDer=ind_branch_pendiente2;
															ind_xplogic = crear_terceto(AND, ind_tlogic_izq, ind_tlogic);
														}
    | termino_logico_izq OR {ind_branch_pendiente = crear_terceto(saltarTrue(comp_bool_actual), ind_tlogic, NOOP); verdadero=ind_branch_pendiente;}
							termino_logico              {
															printf("Regla 37: expresion_logica es termino_logico OR termino_logico\n");
															ind_branch_pendiente2 =  crear_terceto(saltarFalse(comp_bool_actual), ind_tlogic, NOOP);
															falseDer=ind_branch_pendiente2;
															ind_xplogic = crear_terceto(OR, ind_tlogic_izq, ind_tlogic);
														}
    | termino_logico                                    {
															printf("Regla 38: expresion_logica es termino_logico\n");
															ind_xplogic = ind_tlogic;
															ind_branch_pendiente = crear_terceto(saltarFalse(comp_bool_actual), ind_tlogic, NOOP);
															falseIzq=ind_branch_pendiente;
														}
    | NOT termino_logico                                {
															printf("Regla 39: expresion_logica es NOT termino_logico\n");
															ind_xplogic = ind_tlogic;
															ind_branch_pendiente = crear_terceto(saltarTrue(comp_bool_actual), ind_tlogic, NOOP);
															falseIzq=ind_branch_pendiente;
														};

termino_logico_izq:
		termino_logico									{
															printf("Regla 39.1: termino_logico_izq es termino_logico\n");
															ind_tlogic_izq = ind_tlogic;
														};

termino_logico:
    expr_aritmetica_izquierda comp_bool expresion_aritmetica {
															printf("Regla 40: termino_logico es expr_aritmetica_izquierda comp_bool expresion_aritmetica\n");
															resetTipoDato();
															ind_tlogic = crear_terceto(CMP, ind_expr_izq, ind_expr);
														}
    | inlist                                            {
															printf("Regla 41: termino logico es inlist\n");
															ind_tlogic = ind_inlist;
														};

expr_aritmetica_izquierda:
	expresion_aritmetica								{
															printf("Regla 41.1: expr_aritmetica_izquierda es expresion_aritmetica\n");
															ind_expr_izq = ind_expr;
														}

comp_bool:
    MENOR                                               {
															printf("Regla 42: comp_bool es MENOR\n");
															comp_bool_actual = MENOR;
														}
    |MAYOR                                              {
															printf("Regla 43: comp_bool es MAYOR\n");
															comp_bool_actual = MAYOR;
														}
    |MENOR_IGUAL                                        {
															printf("Regla 44: comp_bool es MENOR_IGUAL\n");
															comp_bool_actual = MENOR_IGUAL;
														}
    |MAYOR_IGUAL                                        {
															printf("Regla 45: comp_bool es MAYOR_IGUAL\n");
															comp_bool_actual = MAYOR_IGUAL;
														}
    |IGUAL                                              {
															printf("Regla 46: comp_bool es IGUAL\n");
															comp_bool_actual = IGUAL;
														}
    |DISTINTO                                           {
															printf("Regla 47: comp_bool es DISTINTO\n");
															comp_bool_actual = DISTINTO;
														};

/* Funciones nativas */

average:
    AVG PA CA lista_exp_coma CC PC                      {
															printf("Regla 48: average es AVG PA CA lista_exp_coma CC PC\n\n");
															int pos = agregarCteIntATabla(cant);
															ind_avg = crear_terceto(DIVIDIDO, ind_lec, pos);
														};

inlist:
	INLIST PA ID PUNTO_COMA CA lista_exp_pc CC PC   	{
															printf("Regla 49: inlist es INLIST PA ID(%s) PUNTO_COMA CA lista_exp_pc CC PC\n\n", $3);
															int tipo = chequearVarEnTabla($3);
															chequearTipoDato(tipo);
															resetTipoDato();
															int pos=chequearVarEnTabla($3);
															ind_inlist = crear_terceto(INLIST, pos, ind_lepc);
														};

lista_exp_coma:
    lista_exp_coma COMA expresion_aritmetica            {
															printf("Regla 50: lista_exp_coma es lista_exp_coma COMA expresion_aritmetica\n");
															ind_lec = crear_terceto(MAS, ind_lec, ind_expr);
															cant++;
														}
    | expresion_aritmetica                              {
															printf("Regla 51: lista_exp_coma es expresion_aritmetica\n");
															ind_lec = ind_expr;
															cant = 1;
														};

lista_exp_pc:
    lista_exp_pc PUNTO_COMA expresion_aritmetica        {
															printf("Regla 52: lista_exp_pc es lista_exp_pc PUNTO_COMA expresion_aritmetica\n");
															ind_lepc = crear_terceto(PUNTO_COMA, ind_lepc, ind_expr);
														}
    | expresion_aritmetica                              {
															printf("Regla 53: lista_exp_pc es expresion_aritmetica\n");
															ind_lepc = ind_expr;
														};

lectura:
    READ ID												{
															printf("Regla 54: lectura es READ ID(%s)\n", $2);
															chequearVarEnTabla($2);
															int pos = buscarEnTabla($2);
															ind_lectura = crear_terceto(READ, pos, NOOP);
														};

escritura:
    WRITE ID                                            {
															printf("Regla 55: escritura es WRITE ID(%s)\n", $2);
															chequearVarEnTabla($2);
															int pos = buscarEnTabla($2);
															ind_escritura = crear_terceto(WRITE, pos, NOOP);
														}
    | WRITE CTE_STRING                                  {
															printf("Regla 56: escritura es WRITE CTE_STRING(%s)\n\n", $2);
															int pos = agregarCteStringATabla(yylval.string_val);
															ind_escritura = crear_terceto(WRITE, pos, NOOP);
														};
%%

int main(int argc,char *argv[])
{
  if ((yyin = fopen(argv[1], "rt")) == NULL)
  {
	printf("\nNo se puede abrir el archivo: %s\n", argv[1]);
  }
  else
  {
	yyparse();
  	fclose(yyin);
  }
  return 0;
}

int yyerror(char* mensaje)
 {
	printf("Syntax Error: %s\n", mensaje);
	system ("Pause");
	exit (1);
 }

/** Compara el tipo de dato pasado por parámetro contra el que se está trabajando actualmente en tipoDatoActual.
Si es distinto, tira error. Si no hay tipo de dato actual, asigna el pasado por parámetro. */
void chequearTipoDato(int tipo){
	if(tipoDatoActual == sinTipo){
		tipoDatoActual = tipo;
		return;
	}
	if(tipoDatoActual != tipo)
		yyerror("me estas mezclando numeros enteros con reales. Por que me odias tanto?");
}

/** Vuelve tipoDatoActual a sinTipo */
void resetTipoDato(){
	tipoDatoActual = sinTipo;
}

void apilar_IEP(){
	ult_pos_pila_bloques++;
	if(ult_pos_pila_bloques>=MAX_ANIDAMIENTOS){
		yyerror("para un poco. Para que tantos anidamientos? Hasta 9 me banco.");
	}
	info_elemento_pila aux;
	aux.ind_sent=ind_sent;
	aux.ind_bloque=ind_bloque;
	aux.ind_branch_pendiente=ind_branch_pendiente;
	aux.ind_branch_pendiente2=ind_branch_pendiente2;
	aux.ind_if=ind_if;
	aux.ind_endif=ind_endif;
	aux.ind_else=ind_else;
	aux.ind_then=ind_then;
	aux.ind_jmp=ind_jmp;
	aux.falseIzq=falseIzq;
	aux.falseDer=falseDer;
	aux.verdadero=verdadero;
	aux.always=always;
	pila_bloques[ult_pos_pila_bloques] = aux;
	falseIzq=VALOR_NULO;
	falseDer=VALOR_NULO;
	verdadero=VALOR_NULO;
	always=VALOR_NULO;
}

void desapilar_IEP(){
	info_elemento_pila aux=pila_bloques[ult_pos_pila_bloques];
	ult_pos_pila_bloques--;
	ind_sent=aux.ind_sent;
	ind_bloque=aux.ind_sent;
	ind_branch_pendiente=aux.ind_branch_pendiente;
	ind_branch_pendiente2=aux.ind_branch_pendiente2;
	ind_if=aux.ind_if;
	ind_endif=aux.ind_endif;
	ind_then=aux.ind_then;
	ind_else=aux.ind_else;
	ind_jmp=aux.ind_jmp;
	falseIzq=aux.falseIzq;
	falseDer=aux.falseDer;
	verdadero=aux.verdadero;
	always=aux.always;
}

void apilar_IAEA(){
	ult_pos_pila_exp++;
	if(ult_pos_pila_exp>=MAX_ANIDAMIENTOS){
		yyerror("para un poco. Para que tantos anidamientos? Hasta 9 me banco.");
	}
	info_anidamiento_exp_aritmeticas aux;
	aux.ind_rterm=ind_rterm;
	aux.ind_term=ind_term;
	aux.ind_pre=ind_pre;
	aux.ind_factor=ind_factor;
	aux.ind_avg=ind_avg;
	pila_exp[ult_pos_pila_exp] = aux;
}

void desapilar_IAEA(){
	info_anidamiento_exp_aritmeticas aux=pila_exp[ult_pos_pila_exp];
	ult_pos_pila_exp--;
	ind_rterm=aux.ind_rterm;
	ind_term=aux.ind_term;
	ind_pre=aux.ind_pre;
	ind_factor=aux.ind_factor;
	ind_avg=aux.ind_avg;
}

int saltarFalse(int comp){
	switch(comp){
	case MAYOR:
		return BLE;
	case MAYOR_IGUAL:
		return BLT;
	case MENOR:
		return BGE;
	case MENOR_IGUAL:
		return BGT;
	case IGUAL:
		return BNE;
	case DISTINTO:
		return BEQ;
	}
	return NOOP;
}

int saltarTrue(int comp){
	switch(comp){
	case MAYOR:
		return BGT;
	case MAYOR_IGUAL:
		return BGE;
	case MENOR:
		return BLT;
	case MENOR_IGUAL:
		return BLE;
	case IGUAL:
		return BEQ;
	case DISTINTO:
		return BNE;
	}
	return NOOP;
}

//modificarTerceto(indice, posicion, valor);
void ponerSaltosThen(){
	if(verdadero!=VALOR_NULO){ //Me di cuenta tarde de que ind_branch_pendiente y compania no hacen falta, soy un boludo
		modificarTerceto(verdadero, OP2, ind_then);
	}
}
void ponerSaltosElse(){
	if(falseIzq!=VALOR_NULO){
		modificarTerceto(falseIzq, OP2, ind_else);
	}
	if(falseDer!=VALOR_NULO){
		modificarTerceto(falseDer, OP2, ind_else);
	}
}
void ponerSaltoEndif(){
	if(always!=VALOR_NULO){
		modificarTerceto(always, OP1, ind_endif);
	}
}
void ponerSaltoEndwhile(){
	if(falseIzq!=VALOR_NULO){
		modificarTerceto(falseIzq, OP2, always);
	}
	if(falseDer!=VALOR_NULO){
		modificarTerceto(falseDer, OP2, always);
	}
}
