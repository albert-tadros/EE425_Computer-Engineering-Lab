;;;;;;; P2 for QwikFlash board ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Use this template for Part 2 of Experiment 2
;
;;;;;;; Program hierarchy ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Mainline
;   Initial
;
;;;;;;; Assembler directives ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        list  P=PIC18F4520, F=INHX32, C=160, N=0, ST=OFF, MM=OFF, R=DEC, X=ON
        #include <P18F4520.inc>
        __CONFIG  _CONFIG1H, _OSC_HS_1H  ;HS oscillator
        __CONFIG  _CONFIG2L, _PWRT_ON_2L & _BOREN_ON_2L & _BORV_2_2L  ;Reset
        __CONFIG  _CONFIG2H, _WDT_OFF_2H  ;Watchdog timer disabled
        __CONFIG  _CONFIG3H, _CCP2MX_PORTC_3H  ;CCP2 to RC1 (rather than to RB3)
        __CONFIG  _CONFIG4L, _LVP_OFF_4L & _XINST_OFF_4L  ;RB5 enabled for I/O
        errorlevel -314, -315          ;Ignore lfsr messages

;;;;;;; Variables ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        cblock  0x000              ;Beginning of Access RAM
        VAR_1                      ;Define variables as needed
        endc

;;;;;;; Macro definitions ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MOVLF   macro  literal,dest
        movlw  literal
        movwf  dest
        endm


;;;;;;; Vectors ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        org  0x0000                    ;Reset vector
        nop 
        goto  Mainline

        org  0x0008                    ;High priority interrupt vector
        goto  $                        ;Trap

        org  0x0018                    ;Low priority interrupt vector
        goto  $                        ;Trap

;;;;;;; Mainline program ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Mainline
        rcall  Initial                 ;Initialize everything

		
L1
		 btg PORTB, RB0					; toggle state of RB0 every time L1 is entered to estimate the sampling frequency of the DAC process

		; NOTE ---------------------------------------------
		; Write your code for AD-DA here
		; Analong to Digital from Part 1
		
		bsf ADCON0, 1				   ;set bit 1 of ADCON0 To signal beginnig of conversion

waitForConversion
			btfsc ADCON0 , 1			
			bra waitForConversion

		; Create Subroutines to make code transparent and easier to debug
		
		; DAC PROTOCOL starts here...
			bcf PORTC, RC0   	;1) clear bit RC0 
			bcf PIR1, SSPIF		;2) clear bit SSPIF
			MOVLF 0x21, SSPBUF  ;3) write 0x21 to SSPBUF. This will send the control byte with address 0x21 to DAC module 
	
	;4) create a loop subroutine that buys some time for the process of transferring the control byte from SSPBUF to DAC module
			rcall checkState
	
	;5) once out of the loop, clear SSPIF again
			bcf PIR1, SSPIF		;clear bit SSPIF
			
	;6) 	move the digital data to DAC module through SSBPUF. The digital data is to be converted to analog
			movff ADRESH, SSPBUF	;note that ADRESH register contains the digital data to be converted to analog
	
	;7) create a loop that buys some time for the process of transferring the data byte from SSPBUF to DAC module
	;checkState2
			rcall checkState    
	
	;8) once out of checkState, set RC0. once RC0 is set, the analog output will be sent to output channel A of the DAC module 
			bsf PORTC, RC0   	;set bit RC0

        bra	L1

checkState   
		btfss PIR1, SSPIF		;if SSPIF = 1, means that transfer is done, then skip next instruction 
		bra checkState			;if SSPIF = 0, branch back to checkState Loop
		return

;;;;;;; Initial subroutine ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; This subroutine performs all initializations of variables and registers.

Initial
        MOVLF  B'00011101',ADCON0		; intializing ADCON0
        MOVLF  B'10001110',ADCON1      	; Enable PORTA & PORTE digital I/O pins
		MOVLF  B'00000100',ADCON2 		; Intialization ADCON2
        MOVLF  B'11100001',TRISA       ;Set I/O for PORTA
        MOVLF  B'11011100',TRISB       ;Set I/O for PORTB
        MOVLF  B'11010000',TRISC       ;Set I/0 for PORTC
        MOVLF  B'00001111',TRISD       ;Set I/O for PORTD
        MOVLF  B'00000100',TRISE       ;Set I/O for PORTE
        MOVLF  B'10001000',T0CON       ;Set up Timer0 for a looptime of 10 ms
        MOVLF  B'00010000',PORTA       ;Turn off all four LEDs driven from PORTA
		MOVLF  B'00100000',SSPCON1     ; Intialize SSPCON1
		MOVLF  B'11000000',SSPSTAT
        return

        end
