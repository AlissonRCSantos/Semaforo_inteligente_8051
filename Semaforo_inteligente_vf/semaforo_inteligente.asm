;
;	Programa Semâforo Inteligente
;	Alisson Rodrigues e Nathiele
;
;


;	Registradores utilizados
;	TMOD,TCON,TH0,TL0,IE,IP,PSW,ACC,DTPR
;	PORTS Utilizadas0000000000000
;	P0 = Display de sete Segmentos
;	P3 = Interrupções externas
;	P1.0 Led verde
;	P1.1 Led Amarela
;	P1.2 Led vermelha
;	P1.3 - P1.6 Digitos display
;
;

;	Registradores de uso geral utilizados
;	R0 = Contador Ms
;	R1 = Unidade timer
;	R2 = Dezena Timer
;	R3 = Modo do semâforo(Verde,Amarelo,Vermelho)
;	R4 = Quantidade de veiculos
;	R5 = Modo de emergência (0 = Normal, 1 = Emergência)
;	R6 = Estado atual do semáforo (0 = modo normal, 1 = emergência)
;	PSW.C = Modo Emergenecia ativo
;	PSW.F0 = Alto fluxo de veiculos


;	Configuração inicial
	ORG 0000H	; Começa do endereço 0h
	LJMP INICIO	; Salta para a label Inicio

;	Endereços de mémorias reservados para as interrupções

; |----- Salta para posição de mémoria da INT0 -----|
	ORG 0003h;
	LCALL VEIC_INC	; Chama subrotina para incremento de veiculos
	RETI		; retorna para instrução de parada
	
; |----- Salta para posição de mémoria da TIMER0 -----|
	ORG 000Bh	 ;
	LCALL INTRP_TIMER; Trocar led
	RETI		 ; retorna para instrução de parada
	
; |----- Salta para posição de mémoria da INT1 -----|
	ORG 0013h	;
	LCALL TROCAR_MODO	; Chama a rotina para ativar/desativar o modo de emergência
	RETI		; retorna para instrução de parada
; |----- Salta para posição de mémoria da 01Bh -----|
	ORG 001Bh	;

INICIO:
	MOV	DPTR,#BANCO	; Move o endereço base do BANCO para DTPR
	MOV  R4,#0d		; Inicia R4 com o valor 0
	LCALL   CONF_INTERP	; Configura as interrupções
	LCALL	ATIVA_LED_VERDE	; Ativa sinal verde
	ACALL CONF_TIMER_1	; Configura o timer para 1s
	SETB TR0		; Inicia a temporização

PRINCIPAL:
	; verifica se R0 é maior que 10;
	MOV A,R0	; Carrega em A o valor de R0
	MOV B,#10d	; Carrega o valor 10 em B
	DIV AB		; Divide A por B

	MOV R1,B	;
	MOV R2,A	;
	;MOV A,#00000111B;
	;ORL A,P1	; Apaga Digitos do display
	;MOV P1,A	; Move o resultado da AND para P1

	SETB P1.3;
	SETB P1.4;
	SETB P1.5;
	SETB P1.6;
	; Digito 0
	MOV A,R1	; Carrega no Acumulador o valor de unidades no timer
	MOVC A,@A+DPTR	; Carrega em A o valor no endereço deslocado no banco
	MOV P0,A	; Carrega o valor nos segmentos
	CLR P1.3	; Ativa Digito 0
	CALL	DELAY	;
	
	; Digito 1
	SETB P1.3	; Desativa o digito 0
	MOV A,R2	; Carrega no Acumulador o valor de unidades no timer
	MOVC A,@A+DPTR	; Carrega em A o valor no endereço deslocado no banco
	MOV P0,A	; Carrega o valor nos segmentos
	CLR P1.4	; Ativa Digito 1
	CALL	DELAY	;
	
	; Digito 3
	; Verifica se R4 é maior que 10
	MOV A,R4	; Carrega no Acumulador o valor de unidades no timer
	MOV B,#10d	; Carrega o valor 10 em B
	DIV AB		; Divide A por B
	JNZ MAX_DISPLAY ; Salta para Max display
	MOV A,R4	; Carrega em A q quantidade de veiculos
	MOVC A,@A+DPTR	; Carrega em A o valor no endereço deslocado no banco
	
DIG_3:
	SETB P1.4	; Desativa o digito 1
	MOV P0,A	; Carrega o valor nos segmentos
	CLR P1.6	; Ativa Digito 3
RET_PRINCIPAL:
	CALL	DELAY	;
	AJMP  PRINCIPAL	;
;	Banco com os valores para o display de sete segmentos	
MAX_DISPLAY:
	MOV A,#088H	; Move para A o valor hexadeciaml para A no display
	JMP DIG_3	; Pula para o laço principal
BANCO:
	DB      0C0h             ; Numero 0
	DB      0F9h             ; Numero 1
        DB      0A4h             ; Numero 2
        DB      0B0h             ; Numero 3
        DB      099h             ; Numero 4
        DB      092h             ; Numero 5
        DB      082h             ; Numero 6
        DB      0F8h             ; Numero 7
        DB      080h             ; Numero 8
        DB      090h             ; Numero 9

DELAY:
	NOP	;
	NOP	;
	NOP	;
	NOP	;
	NOP	;
	RET	;
;	Configura as interrupções para o programa
RETORNO:
	RET	;
	
CONF_INTERP:
	MOV IE,#10010111b	; Ativa as interrupções externas 0 e 1 e do timer 0
	MOV IP,#00000101b	; Da prioridade para IT0 depois IT1 e depois  T0
	MOV TCON,#00000000b	; Configura as interrupções no modo de nivel
	RET;
;	Configura o timer para contar 10ms

;	troca o led aceso
INTRP_TIMER:
	DEC R0			; Decrementa R0
	MOV A,R0		; Move o contedo de R0 para ACC
	JZ  TROCAR_LED		; Salta Para trocar LED se o acumulador chegou em 0
INTRP_TIMER1:
	ACALL CONF_TIMER_1	; Configura o timer para 1s
	SETB TR0		; Inicia a temporização
	RET
;	Verifica qual o modo atual e troca para o proximo
;	Verifica qual o modo atual e troca para o proximo
TROCAR_LED:
	; Verifica se o sistema está em emergência (R5 = 1)
	MOV A, R6         ; Verifica o valor de R6 (modo emergência)
	JZ CONTINUAR      ; Se não estiver em emergência, troca o LED normalmente
	
	; Se estiver em emergência, apenas retorna sem alterar o semáforo
	ACALL DESATIVAR_EMERGENCIA
	RET

CONTINUAR:
	MOV A,R3		; Move para o Acumulador o valor de R3 (modo do sinal)
	JZ AUX1			; Se R3 era igual a 0 então o sinal estava verde
	DEC A			; Decrementa o acumulador
	JZ AUX2			; Se R3 era igual a 1 então o sinal estava amarelo
	ACALL	AUX3	        ; Ativa led verde
	RET			; Retorna a chamada da subrotina
	
AUX1:
	ACALL ATIVA_LED_AMARELA	; Chama a rotina para ativar led amarela
	AJMP INTRP_TIMER1	; Continua tratamento da interrupção
;	AUX2 ativa a led vermelha
AUX2:
	ACALL ATIVA_LED_VERMELHA; Chama a rotina para ativar ler amarela
	AJMP INTRP_TIMER1	; Continua tratamento da interrupção
AUX3:
	ACALL ATIVA_LED_VERDE; Chama a rotina para ativar led verde
	AJMP INTRP_TIMER1	; Continua tratamento da interrupção

; subrotina para incremento de veiculos
VEIC_INC:
	MOV A,R3	; Carrega em A o modo atual
	JNZ RET_INC	; Se não estiver no sinal verde retorna da função
	MOV A,R4	; Carrega em A o total de veiculos
	INC A		; Incrementa a quantidade de veiculos;
	MOV R4,A	; Carrega em R4 a nova quantidade de veiculos
	
	XRL A,#5	; Verifica se a quantidade de veiculos é igual a 5;
	JNZ RET_INC	; Pula para label de atualização da exibição do display caso não seja 5
	; se for cinco ativa o modo estendido
	MOV C,F0	; Move a flag de uso geral para C
	JC RET_INC	; Pula para o fim interrupção se o Carry está setado
	MOV R0,#15d	; Carrega o semaforo para 15 segundos
	SETB F0	; Ativa a flag de modo  extendido
RET_INC:
	RET	;
	
; Ativa led_verde;
ATIVA_LED_VERDE:
	MOV R5,#0d		; Limpa a flag de emergência
	MOV R3,#0d		; Move o valor 0 para R3, com R3 em 0 indica que o lede verde está ativo
	;ACALL CONF_TIMER_1	; Configura o timer para 1s
	MOV R0,#10d		; Carrega R0 com 10
	;SETB TR0		; Inicia a temporização
	MOV P1,#0FFh		; Apaga todas LEds da P1
	CLR P1.0		; Ativa Led verde
	RET			; Retorna para função que chamou a subrotina

; Ativa led_amarela;
ATIVA_LED_AMARELA:
	CLR F0			; Limpa a Flag de modo extendido
	MOV R4,#0d		; Limpa quantidade de veiculos
	MOV R3,#1d		; Move o valor 1 para R3, com R3 em 1 indica que o led amarelo está ativo
	;ACALL CONF_TIMER_1	; Configura o timer para 1s
	MOV R0,#3d		; Carrega R0 com 3
	;SETB TR0		; Inicia a temporização
	MOV P1,#0FFh		; Apaga todas LEds da P1
	CLR P1.1		; Ativa Led Amarela
	RET			; Retorna para função que chamou a subrotina

; Ativa led_vermelha;
ATIVA_LED_VERMELHA:
	MOV R3,#2d		; Move o valor 2 para R3, com R3 em 2 indica que o led vermelho está ativo
	;ACALL CONF_TIMER_1	; Configura o timer para 1ms
	MOV R0,#7d		; Carrega R0 com 7
	;SETB TR0		; Inicia a temporização
	MOV P1,#0FFh		; Apaga todas LEds da P1
	CLR P1.2		; Ativa Led vermelha
	RET			; Retorna para função que chamou a subrotina
		
CONF_TIMER_1:
	; Para contar 1ms o timer deve contar 1 milpulsos
	; O timer é iniciado com 64536d em hexa FC18
	MOV TMOD,#00001001b	; Configura o timer 0 no modo de timer 16 bits com interrupção
	MOV TH0,#0FCh		; Carrega THIGH0 com os bits mais significativos 
	MOV TL0,#018h		; Carrga TLOW0 com os bits menos significativos
	RET;
; A partir daqui Nathiele
; ==================================================================================================================
TROCAR_MODO:
	MOV A, R6        ; Carrega o valor de R6 (modo atual) no acumulador
	JZ MODO_NORMAL   ; Se R6 for 0 (modo normal), continua para mudar para emergência
	; Se já estiver em emergência (R6 = 1), retorna sem fazer nada
	RET

MODO_NORMAL:
	CPL A            ; Complementa (inverte) o valor de A (alternando entre modo normal e emergência)
	MOV R6, A        ; Atualiza o valor de R6 com o novo modo (0 para normal, 1 para emergência)
	JNZ ATIVAR_EMERGENCIA  ; Se R6 for 1, chama a função para ativar o modo de emergência
	RET              ; Se não for emergência, retorna

ATIVAR_EMERGENCIA:
	SETB TR0        	; Inicia o temporizador
	MOV R3,#2d		; Move o valor 2 para R3, com R3 em 2 indica que o led vermelho está ativo
	MOV P1,#0FFh		; Apaga todas LEds da P1
	CLR P1.2		; Ativa Led vermelha
	MOV R0, #15     	; Define a duração do vermelho para 15 segundos
	CALL ATUALIZAR_DISPLAY  ; Atualiza o display com o tempo restante
	RET             	; Retorna da sub-rotina

DESATIVAR_EMERGENCIA:
	CLR TR0         	; Para o temporizador
	MOV R6,#0d		; Muda para modo normal
	LCALL ATIVA_LED_VERDE   ; Retorna ao estado normal do semáforo (sinal verde)
	LCALL INTRP_TIMER1	; Continua tratamento da interrupção
	RET             	; Retorna da sub-rotina

ATUALIZAR_DISPLAY:
	MOV A, R0       ; Carrega o valor do temporizador em A
	MOV B, #10      ; Divide por 10 para obter dezenas e unidades
	DIV AB          ; Resultado: A = dezenas, B = unidades
	MOV R1, B       ; Salva unidades
	MOV R2, A       ; Salva dezenas
	
	SETB P1.3       ; Configura o display
	SETB P1.4
	MOV A, R1       ; Mostra unidade
	MOVC A, @A+DPTR
	MOV P0, A
	CLR P1.3
	CALL DELAY
	
	SETB P1.3
	MOV A, R2       ; Mostra dezena
	MOVC A, @A+DPTR
	MOV P0, A
	CLR P1.4
	CALL DELAY
	RET

	END;