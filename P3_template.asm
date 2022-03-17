;;;;;;; P3 Template by AC ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;; INTERRUPTS LAB ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        list  P=PIC18F4520, F=INHX32, C=160, N=0, ST=OFF, MM=OFF, R=DEC, X=ON
        #include <P18F4520.inc>
        __CONFIG  _CONFIG1H, _OSC_HS_1H  ;HS oscillator
        __CONFIG  _CONFIG2L, _PWRT_ON_2L & _BOREN_ON_2L & _BORV_2_2L  ;Reset
        __CONFIG  _CONFIG2H, _WDT_OFF_2H  ;Watchdog timer disabled
        __CONFIG  _CONFIG3H, _CCP2MX_PORTC_3H  ;CCP2 to RC1 (rather than to RB3)
        __CONFIG  _CONFIG4L, _LVP_OFF_4L & _XINST_OFF_4L  ;RB5 enabled for I/O
        errorlevel -314, -315          ;Ignore lfsr messages

;;;;;;; Variables ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        cblock  0x000                  ;Beginning of Access RAM
        TMR0LCOPY                      ;Copy of sixteen-bit Timer0 used by LoopTime
        TMR0HCOPY
        INTCONCOPY                     ;Copy of INTCON for LoopTime subroutine

		WREG_TEMP						;Added by AC - DO NOT MODIFY
		STATUS_TEMP						;Added by AC - DO NOT MODIFY
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
		goto HPISR                     ;execute High Priority Interrupt Service Routine


        org  0x0018                    ;Low priority interrupt vector
        goto LPISR                     ;execute Low Priority Interrupt Service Routine

;;;;;;; Mainline program ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Mainline
        rcall  Initial                 ;Initialize everything
        
L1
         btg  PORTC,RC2               ;Toggle pin, to generate pulse train
         rcall  LoopTime              ;Looptime is set to 0.1ms delay
         bra	L1


;;;;;;; Initial subroutine ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Initial
	
        MOVLF  B'10001110',ADCON1      ;Enable PORTA & PORTE digital I/O pins
        MOVLF  B'11100001',TRISA       ;Set I/O for PORTA
        MOVLF  B'11011111',TRISB       ;Set I/O for PORTB
		MOVLF  B'11010000',TRISC       ;Set I/0 for PORTC
        MOVLF  B'00001111',TRISD       ;Set I/O for PORTD
        MOVLF  B'00000100',TRISE       ;Set I/O for PORTE
        MOVLF  B'10001000',T0CON       ;Set up Timer0 for a looptime of 10 ms
        MOVLF  B'00010000',PORTA       ;Turn off all four LEDs driven from PORTA
		MOVLF  B'11111111',TMR0H 		;Added by AC - DO NOT MODIFY
        MOVLF  B'00000000',TMR0L 		;Added by AC - DO NOT MODIFY
		bcf PORTC,RC1 					;Added by AC - DO NOT MODIFY

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;Write your code here for the following tasks:		
		; Enable and set up interrupts
		; Initialize appropriate priority bits
		; Clear appropriate interrupt flags
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
return

;;;;;;; LoopTime subroutine ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;; DO NOT MODIFY	    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Bignum  equ     65536-250+12+2
LoopTime
		btfss INTCON,TMR0IF            ;Wait for rollover
        bra	LoopTime
		movff  INTCON,INTCONCOPY       ;Disable all interrupts to CPU
        bcf  INTCON,GIEH
        movff  TMR0L,TMR0LCOPY         ;Read 16-bit counter at this moment
        movff  TMR0H,TMR0HCOPY
        movlw  low  Bignum
        addwf  TMR0LCOPY,F
        movlw  high  Bignum
        addwfc  TMR0HCOPY,F
        movff  TMR0HCOPY,TMR0H
        movff  TMR0LCOPY,TMR0L         ;Write 16-bit counter at this moment
        movf  INTCONCOPY,W             ;Restore GIEH interrupt enable bit
        andlw  B'10000000'
        iorwf  INTCON,F
        bcf  INTCON,TMR0IF             ;Clear Timer0 flag
        return


;;;;;;; LPISR ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
LPISR
	movff STATUS, STATUS_TEMP          ; save STATUS and W
	movf W,WREG_TEMP

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		;Write your code here for the following tasks:
			; Clear pulse train from Mainline
			; Initiate counting bits 
					; You MUST do this using a separate SUBROUTINE,
					; and inside that subroutine you may create
					; yet another subroutine which counts LoopTime (0.1ms)
			; Clear all counting bits from LPISR
			; Clear LP Interrupt FLAG
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	movf WREG_TEMP,W					; restore STATUS and W
	movff STATUS_TEMP,STATUS
retfie



;;;;;;; HPISR ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
HPISR
	bsf PORTC,RC1;Signal that we are entering HPISR - Added by AC - DO NOT MODIFY
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		;Write your code here for the following tasks:
			;Clear pulse train from RC2
			;Clear all counting bits from LPISR
			; Loop to check for human input
			; Clear LP Interrupt FLAG
			; Clear HP Interrupt FLAG
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	

	bcf PORTC,RC1;Signal that we are Leaving HPISR - Added by AC - DO NOT MODIFY
	MOVLF  B'11111111',TMR0H ;Added by AC - DO NOT MODIFY
	MOVLF  B'00000000',TMR0L ;Added by AC - DO NOT MODIFY

retfie FAST




end
