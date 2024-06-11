;*******************************************************************
;* This stationery serves as the framework for a user application. *
;* For a more comprehensive program that demonstrates the more     *
;* advanced functionality of this processor, please see the        *
;* demonstration applications, located in the examples             *
;* subdirectory of the "Freescale CodeWarrior for HC08" program    *
;* directory.                                                      *
;*******************************************************************

; Include derivative-specific definitions
            INCLUDE 'derivative.inc'

; export symbols
            XDEF _Startup, main
            ; we export both '_Startup' and 'main' as symbols. Either can
            ; be referenced in the linker .prm file or from C/C++ later on

            XREF __SEG_END_SSTACK   ; symbol defined by the linker for the end of the stack


; variable/data section
MY_ZEROPAGE: SECTION  SHORT         ; Insert here your data definition

;Variables


;lo que se muestra en los 7 segmentos
numero1 ds 1;				Display Segundos
numero2 ds 1;
numero3 ds 1;				Display Minutos
numero4 ds 1;				

ciclo ds 1 ;				;Determina el delay del multiplexado
contadorencendido ds 1;		;Determina si el cronometro esta encendido o no.
puntito ds 1;				;Determina si habra un punto cada segundo
contadorloopmux ds 1;		;Determina el delay del reset	

; code section
MyCode:     SECTION
;constantes
;representaciones de los digitos 0-9	
digito0 dc %10111110	
digito1 dc %00000110	
digito2 dc %11011010
digito3 dc %11001110
digito4 dc %01100110
digito5 dc %11101100
digito6 dc %11111100
digito7 dc %10000110
digito8 dc %11111110
digito9 dc %11101110
main:
_Startup:
            LDHX   #__SEG_END_SSTACK ; initialize the stack pointer
            TXS
            CLI                     ; enable interrupts
            ; Insert your code here

			
			LDA #%11111111	;Se cargan todos 1 en el registro A para habilitar configuraciones.
			
			;Se habilitan los puertos A y B como salidas al tener un "1"
			;En el puerto A se ecuentran los Decodificadores y en el B el display
			STA PTADD				;*** PTADD - Port A Data Direction Register; 0x00000001 ***
			STA PTBDD				;*** PTBDD - Port B Data Direction Register; 0x00000003 ***
			
			;Se habilitan los puertos A y B como Pull up o Pull Down al tener un "1", los display incialmente estan apagados.
			STA PTAPE				;*** PTAPE - Port A Pull Enable Register; 0x00001840 ***
			STA PTBPE				;*** PTBPE - Port B Pull Enable Register; 0x00001848 ***

			;Se habilita los registros B como Lectura, en el caso de que no se le envie una nueva se al mantendra la anterior.
			STA PTBD				;*** PTBD - Port B Data Register; 0x00000002 ***
			
			LDA #%11110001
			;Se habilitan el bit0 del puerto C como salida ya que es el buzzer y los bit1 al 3 seran entradas ("0") para los switchs.			
			STA PTCDD				;*** PTCDD - Port C Data Direction Register; 0x00000005 ***
			         
            
            ;Setea los contadores en cero
			LDA #$0
			STA numero1
			STA numero2
			STA numero3
			STA numero4

			;El controlador RTC, con el bit4 = "1" habilitamos el RTIE (La habilitacion de Interrupcion en Tiempo Real)
			;los 4 bits menos significativos determinan el tiempo de interrupcion
			;1111 = 1 seg
			;1110 = 0.5 seg
			;1101 = 0.1 seg
			;1100 = 16 mseg .... etc.
            LDA #%00011111	;Seteamos en 1 segundo
            STA RTCSC   	;*** RTCSC - RTC Status and Control Register; 0x0000006C ***
            
            ;El contador inicia apagado y sin punto.
            CLR contadorencendido
            CLR puntito

mainLoop:
			JSR botones 		;evalua los switch
			JSR multiplexado	;muestra los valores en los displays
			BRA    mainLoop


multiplexado

			LDA #%00000000
			STA PTAD		;Seleciono el deco 00 o el display de los segundos
			
			
			;LDA #digito0
			;ADD numero1
			;STA PTBD
			;JSR delay	
			
			LDHX #digito0	;me ubico en la representacion del 0
			TXA				;Carga la posicion en A=00XX
			ADD numero1		;me desplazo hacia la representacion del numero que se quiere mostrar
			TAX				;X=XX+numero1
			LDA 0,x			;A=0+X
			STA PTBD		;muestra la unidad de segundo
			JSR delay

			LDA #%0000001
			STA PTAD
			LDHX #digito0	;me ubico en la representacion del 0
			TXA
			ADD numero2		;me desplazo hacia la representacion del numero que se quiere mostrar
			TAX
			LDA 0,x
			STA PTBD		;muestra la decima de segundo
			JSR delay
	
			LDA #%00000010
			STA PTAD
			LDHX #digito0	;me ubico en la representacion del 0
			TXA
			ADD numero3		;me desplazo hacia la representacion del numero que se quiere mostrar
			TAX
			LDA 0,x
			LDX puntito
			BEQ nopuntito
			INCA			;le suma un puntito
nopuntito	STA PTBD		;muestra la unidad de minuto
			JSR delay

			LDA #%00000011
			STA PTAD
			LDHX #digito0	;me ubico en la representacion del 0
			TXA
			ADD numero4		;me desplazo hacia la representacion del numero que se quiere mostrar
			TAX
			LDA 0,x
			STA PTBD		;muestra la decima de minuto
			JSR delay
			
            RTS				;Vuelve al main loop y a registrar los botones

;Velocidad del multiplexado
delay:
			LDA #1			
			STA ciclo		;Habilita el delay
			
vol         feed_watchdog	;En caso de que no regrese por errores de software se reinician los registros
			LDA #10			;Carga 10 hexa en A
			LDHX #25		;Carga 2526 hexa en X
leep		DBNZX leep		;Decrementa y queda en loop hasta que X=0
			DBNZA leep		;Decrementa ,y vuelve X a FFFF
			DEC ciclo		;Apaga el delay
			BNE vol			;Si no se apaga, se fuerza el apagado
			RTS				;Retorna desde donde se llamo (en este caso el Multiplexado)
			
			;aproximadamente 2859075 ciclos de clock que a 40MHZ equivalen a 0.0714 segundos
				
;Evaluacion de switch
botones 
	
	LDA PTCD						;Recibe la entrada de los botones en PTCD

	BRCLR 2,PTCD,iniciarcontador 	;si el bit2 de PTCD es 0 salta hacia iniciarcontador (BOTON INICIO)
	BRCLR 3,PTCD,pausacontador		;si el bit3 de PTCD es 0 salta hacia pausacontador (BOTON PAUSA) 

	RTS								; no se apreto ningun boton
	
iniciarcontador
	BRCLR 3,PTCD,resetcontador		;si ademas del BOTON INICIO tambien esta activado el BOTON PAUSA va a resetcontador
	BSET 7,contadorencendido		;habilita que se incremente la unidad de segundo
	
	RTS
	
pausacontador
	BRCLR 2,PTCD,resetcontador		;si ademas del BOTON PAUSA tambien esta activado el BOTON INICIO va a resetcontador
	BCLR 7,contadorencendido		;deshabilita que se incremente la unidad de segundo
	
	RTS

loopmux								;pausa, muestra y grita
	BSET 0,PTCD
	JSR delay
	BCLR 0,PTCD
	JSR multiplexado
	LDA contadorloopmux
	CMP #$FF						;tiempo que tarda el loop
	BEQ volver
	INCA
	JSR loopmux
	
volver RTS


resetcontador
	clr numero1						;se setean los 4 numeros en cero
	clr numero2
	clr numero3
	clr numero4
	BCLR 7,contadorencendido		;se deshabilita que se incremente la unidad de segundo
	JSR loopmux						;pausa momentaneamente la lectura de los switch
	RTS


interrupcion 
	BSET 7,RTCSC					;resetea el contador del rct
	BRCLR 7,contadorencendido,fin	;chequea si la cuenta esta habilitada o no
	
	INC puntito						;para que el punto parpadee con cada segundo
	LDA puntito
	CMP #$02
	BNE numeritos
	CLR puntito
	
numeritos

	INC numero1						;Cada vez que se realice la interrupcion la unidad de segundo incrementa 1
	LDA numero1
	CMP #$A							;Si el numero menos significativo es igual a 10 debe reiniciarse y afectar al numero siguiente
	BNE fin							;De lo contrario debe es un numero permitido y termina la interrupcion					
	CLR numero1
	INC numero2						;La decima de segundo incrementa 1
	LDA numero2
	CMP #$6							;Si el numero2 es igual a 6 debe reiniciarse y afectar al numero siguiente
	BNE fin							;De lo contrario debe es un numero permitido y termina la interrupcion
	CLR numero2
	INC numero3						;La unidad de minuto incrementa 1
	LDA numero3
	CMP #$A							;Si el numero3 es igual a 10 debe reiniciarse y afectar al numero siguiente
	BNE fin							;De lo contrario debe es un numero permitido y termina la interrupcion
	CLR numero3
	INC numero4						;La decima de minuto incrementa 1
	LDA numero4
	CMP #$6							;Si el numero3 es igual a 6 debe reiniciarse
	BNE fin							;De lo contrario debe es un numero permitido y termina la interrupcion
	CLR numero4
	
fin	RTI

;ubicacion de la interrupcion en ROM	
	org Vrtc
	dcw interrupcion
	
