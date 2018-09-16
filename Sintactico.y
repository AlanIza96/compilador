%{
	#include <stdio.h>
	#include <stdlib.h>
	#include <conio.h>
	#include "y.tab.h"

	int yyerror();

	int yystopparser=0;
	FILE  *yyin;
%}

%token START
%token END

%token DECVAR ENDDEC
%token INT FLOAT STRING

%token WHILE ENDWHILE
%token IF THEN ELSE ENDIF

%token AND OR NOT

%token ASIG
%token MAS MENOS
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

%token ID
%token CTE_FLOAT CTE_INT CTE_STRING

%%

programa: START seccion_declaracion bloque END {printf("\nCOMPILACION EXITOSA");};

seccion_declaracion: DECVAR bloque_dec ENDDEC {printf("\nRegla 1");};

bloque_dec: bloque_dec declaracion{printf("\nRegla 2");};

bloque_dec: declaracion{printf("\nRegla 3");};

declaracion: t_dato lista_id PUNTO_COMA{printf("\nRegla 4");};

t_dato: FLOAT{printf("\nRegla 5");} | INT{printf("\nRegla 6");} | STRING{printf("\nRegla 7");};

lista_id: lista_id COMA ID{printf("\nRegla 8");};

lista_id: ID{printf("\nRegla 9");};

bloque: bloque sentencia{printf("\nRegla 10");};

bloque: sentencia{printf("\nRegla 11");};

sentencia: asignacion{printf("\nRegla 12");}; /* | bloque_if | bloque_while | lectura | escritura | expresion_aritmetica PUNTO_COMA; */ /* puede no haber sentencias? lo mismo para if y while, la expresion_aritmetica est� porque si */

asignacion: ID ASIG expresion PUNTO_COMA{printf("\nRegla 13");}; /* terminar de desarrollar, puede ser una exp aritmetica, o una cadena, as� que es una expresion */

expresion: expresion_cadena{printf("\nRegla 14");} | expresion_aritmetica{printf("\nRegla 15");};

expresion_cadena: CTE_STRING{printf("\nRegla 16");};

expresion_aritmetica: expresion_aritmetica MAS termino {printf("\nRegla 17");}| expresion_aritmetica MENOS termino {printf("\nRegla 18");}| termino{printf("\nRegla 19");};

termino: termino POR factor {printf("\nRegla 20");}| termino DIVIDIDO factor {printf("\nRegla 21");}| factor{printf("\nRegla 22");};

factor: PA expresion_aritmetica PC{printf("\nRegla 23");}; /* puedo multiplicar por una string? ya no xD */

factor: ID{printf("\nRegla 24");};

factor: CTE_FLOAT{printf("\nRegla 25");} | CTE_INT{printf("\nRegla 26");}; /* de aca para atras esta mas o menos listo */

/* prueba 1: descomentar lo de abajo para que sea le�do ------------------------------------------------------------------------------------------------------------------------------------------------------------------- */

/* bloque_if: IF expresion_booleana THEN bloque ENDIF; /* /* terminar de desarrollar */

/* bloque_if: IF expresion_booleana THEN bloque ELSE bloque ENDIF; /* /* terminar de desarrollar */

/* bloque_while: WHILE expresion_booleana bloque ENDWHILE; */


/* bloque:
	toquen | bloque toquen;

toquen:
 DECVAR      {printf("DECVAR ");}
 |ENDDEC     {printf("ENDDEC ");}
 |INT        {printf("INT ");}
 |FLOAT      {printf("FLOAT ");}
 |STRING     {printf("STRING ");}
 |WHILE      {printf("WHILE ");}
 |ENDWHILE   {printf("ENDWHILE ");}
 |IF         {printf("IF ");}
 |THEN       {printf("THEN ");}
 |ELSE       {printf("ELSE ");}
 |ENDIF      {printf("ENDIF ");}
 |ASIG       {printf("ASIG ");}
 |MAS        {printf("MAS ");}
 |MENOS      {printf("MENOS ");}
 |POR        {printf("POR ");}
 |DIVIDIDO   {printf("DVD ");}
 |MENOR      {printf("MENOR ");}
 |MAYOR      {printf("MAYOR ");}
 |MENOR_IGUAL{printf("MENOR_IGUAL ");}
 |MAYOR_IGUAL{printf("MAYOR_IGUAL ");}
 |IGUAL      {printf("IGUAL ");}
 |DISTINTO   {printf("DISTINTO ");}
 |PA         {printf("PA ");}
 |PC         {printf("PC ");}
 |CA         {printf("CA ");}
 |CC         {printf("CC ");}
 |COMA       {printf("COMA ");}
 |PUNTO_COMA {printf("PUNTO_COMA ");}
 |READ       {printf("READ ");}
 |WRITE      {printf("WRITE ");}
 |AVG        {printf("AVG ");}
 |INLIST    {printf("INLIST ");}
|ID			{printf("ID ");}
|CTE_FLOAT	{printf("CTE_FLOAT ");}
|CTE_INT	{printf("CTE_INT ");}
|CTE_STRING	{printf("CTE_STRING ");}
|AND	{printf("AND ");}
|OR		{printf("OR ");}
|NOT	{printf("NOT ");};  */

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


int yyerror(void)
 {
	printf("Syntax Error\n");
	system ("Pause");
	exit (1);
 }
