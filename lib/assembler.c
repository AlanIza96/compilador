#include <stdio.h>
#include <stdlib.h>
#include "assembler.h"
#include "../y.tab.h"
#include "tercetos.h"

void generarAssembler(){
  FILE* arch = fopen("final.asm", "w");
  if(!arch){
		printf("No pude crear el archivo final.txt\n");
		return;
	}

  escribirInicio(arch);
  generarTabla(arch);

  fprintf(arch, ".CODE\n");

  for(int i=0; i <= ultimo_terceto; i++){
    switch(lista_terceto[i].operador){
      case ASIG:
	  	asignacion(arch, i);
        break;
      case CMP:
		comparacion(arch, i);
        break;

      case BGT:
        escribirSalto(arch, "JG", lista_terceto[i].op2);
        break;
      case BGE:
        escribirSalto(arch, "JGE", lista_terceto[i].op2);
        break;
      case BLT:
        escribirSalto(arch, "JL", lista_terceto[i].op2);
        break;
      case BLE:
        escribirSalto(arch, "JLE", lista_terceto[i].op2);
        break;
      case BNE:
        escribirSalto(arch, "JNE", lista_terceto[i].op2);
        break;
      case BEQ:
        escribirSalto(arch, "JE", lista_terceto[i].op2);
        break;
      case JMP:
        escribirSalto(arch, "JMP", lista_terceto[i].op1);
        break;

      case THEN:
        escribirEtiqueta(arch, "then", i);
        break;
      case ELSE:
        escribirEtiqueta(arch, "else", i);
        break;
      case ENDIF:
        escribirEtiqueta(arch, "endif", i);
        break;

      case WHILE:
        escribirEtiqueta(arch, "while", i);
        break;
      case ENDWHILE:
        escribirEtiqueta(arch, "endwhile", i);
        break;

	case INLIST_TRUE:
		escribirEtiqueta(arch, "inlistTrue", i);
		break;
	case INLIST_CMP:
		escribirEtiqueta(arch, "inlistCMP", i);
		break;

      case MAS:
        break;
      case MENOS:
        break;
      case POR:
        break;
      case DIVIDIDO:
        break;

      case READ:
        break;
      case WRITE:
        break;
    }
  }

  escribirFinal(arch);
  fclose(arch);

}

void escribirInicio(FILE *arch){
  fprintf(arch, "include macros2.asm\ninclude number.asm\n\n.MODEL SMALL\n.386\n.STACK 200h\n\n");
}

void escribirFinal(FILE *arch){
    fprintf(arch, "\nend\n");
}

void generarTabla(FILE *arch){
    fprintf(arch, ".DATA\n");

    for(int i=0; i<=fin_tabla; i++){
        fprintf(arch, "%s ", tabla_simbolo[i].nombre);
        switch(tabla_simbolo[i].tipo_dato){
        case CteInt:
            fprintf(arch, "dd %d\n", tabla_simbolo[i].valor_i);
            break;
        case CteFloat:
            fprintf(arch, "dd %f\n", tabla_simbolo[i].valor_f);
            break;
        case CteString:
            fprintf(arch, "db \"%s\", 0\n", tabla_simbolo[i].valor_s);
            break;
        default: //Es una variable
            fprintf(arch, "dd ?\n");
        }
    }

    fprintf(arch, "\n");
}

void escribirEtiqueta(FILE* arch, char* etiqueta, int n){
    fprintf(arch, "%s%d: ", etiqueta, n+OFFSET);
}

void escribirSalto(FILE* arch, char* salto, int tercetoDestino){
    fprintf(arch, "%s ", salto);

    //Por si nos olvidamos de rellenar un salto
    if(tercetoDestino == NOOP){
        printf("Ups. Parece que me olvide de rellenar un salto en los tercetos y ahora no se como seguir.\n");
        system("Pause");
        exit(10);
    }

    switch( lista_terceto[tercetoDestino - OFFSET].operador ){
    case THEN:
        fprintf(arch, "then");
        break;
    case ELSE:
        fprintf(arch, "else");
        break;
    case ENDIF:
        fprintf(arch, "endif");
        break;
    case WHILE:
        fprintf(arch, "while");
        break;
    case ENDWHILE:
        fprintf(arch, "endwhile");
		break;
	case INLIST_TRUE:
        fprintf(arch, "inlistTrue");
		break;
	case INLIST_CMP:
        fprintf(arch, "inlistCMP");
    }

    fprintf(arch, "%d\n", tercetoDestino);
}

void asignacion(FILE* arch, int ind){
	int destino = lista_terceto[ind].op1;
	int origen = lista_terceto[ind].op2;

	//Ver tipo de dato
	switch(tabla_simbolo[destino].tipo_dato){
	case Int:
		break;
	case Float:
		break;
	case String:
		//mov [destino] origen
		//destino y origen son entradas a tabla de simbolos
		fprintf(arch, "LEA EAX, %s\nMOV %s, EAX", tabla_simbolo[origen].nombre, tabla_simbolo[destino].nombre);
	}

	fprintf(arch, "\n");
}

void comparacion(FILE* arch, int ind){
	int elemIzq = lista_terceto[ind].op1;
	int elemDer = lista_terceto[ind].op2;
	switch(tabla_simbolo[elemIzq].tipo_dato){
	case Int:
		break;
	case Float:
		break;
	case String:
		break;
	}
}
