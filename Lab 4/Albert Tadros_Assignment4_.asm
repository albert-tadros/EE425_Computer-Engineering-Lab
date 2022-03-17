;;;;;;; P3 Template by AC ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;; INTERRUPTS LAB by Albert Tadros;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;; Fall 2021 ;;;;;;;;;;;;;;;;;;

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
		
		COUNT							; to count looptime
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

		;;; INTCON Register FOR HIGH PRIORITY;;;
		bcf INTCON, 1					; disabling INT0 FLAG initially
		bsf INTCON, 4					; enabling INT0 as an interupt (Always a high priority)					
		bsf INTCON, 6					; enabling GIEL
		bsf INTCON, 7					; enabling GIEH
		
		;;; INTCON3 Register FOR LOW PRIORITY;;;
		bcf INTCON3, 0					; disabling INT1 Flag initially
		bsf INTCON3, 3					; enabling INT1 as an interupt
		bcf INTCON3, 6					; setting INT1 as a low priority interupt
		
		;;; INTCON2 Register For interupt edging;;;
		bsf INTCON2, 6		; INT0 will interupt at a rising edge 
		bsf INTCON2, 5		; INT1 will interupt at a rising edge 

		;; RCON
		bsf RCON, 7
		
		MOVLF 2, COUNT		; store 2 in COUNT variable for waiting 2 iterations of LoopTime
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

waitForStep

    rcall LoopTime
	decfsz  COUNT,F        ;Decrement COUNT, store result in F, skip next instruction if COUNT = 0 
	bra waitForStep			; otherwise, keep branching to "waitForStep"
	MOVLF 2, COUNT			; store 2 in COUNT
	return 

countBits 
	;Step 1
	bsf PORTA, RA1
	bsf PORTA, RA2
	bsf PORTA, RA3  
	rcall waitForStep
	;Step 2
	bsf PORTA, RA1
	bsf PORTA, RA2
	bcf PORTA, RA3
	rcall waitForStep
	;Step 3
	bsf PORTA, RA1
	bcf PORTA, RA2
	bsf PORTA, RA3
	rcall waitForStep
	;Step 4
	bsf PORTA, RA1
	bcf PORTA, RA2
	bcf PORTA, RA3
	rcall waitForStep
	;Step 5
	bcf PORTA, RA1
	bsf PORTA, RA2
	bsf PORTA, RA3
	rcall waitForStep
	;Step 6
	bcf PORTA, RA1
	bsf PORTA, RA2
	bcf PORTA, RA3
	rcall waitForStep
	;Step 7
	bcf PORTA, RA1
	bcf PORTA, RA2
	bsf PORTA, RA3
	rcall waitForStep
	;Step 8
	bcf PORTA, RA1
	bcf PORTA, RA2
	bcf PORTA, RA3
return 

;;;;;;; LPISR ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
LPISR
	movff STATUS, STATUS_TEMP          ; save STATUS and W
	movf W,WREG_TEMP

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		;Write your code here for the following tasks:

			bcf PORTC, RC2 ; Clear pulse train from Mainline

			rcall countBits 	; Initiate counting bits 
									; You MUST do this using a separate SUBROUTINE,
									; and inside that subroutine you may create
									; yet another subroutine which counts LoopTime (0.1ms)

			MOVLF B'00010000',PORTA; Clear all counting bits from LPISR
			bcf INTCON3, 0 ; Clear LP Interrupt FLAG
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	movf WREG_TEMP,W					; restore STATUS and W
	movff STATUS_TEMP,STATUS
retfie



;;;;;;; HPISR ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
HPISR
	bsf PORTC,RC1			;Signal that we are entering HPISR - Added by AC - DO NOT MODIFY
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		;Write your code here for the following tasks:

			bcf PORTC, RC2				;Clear pulse train from RC2
			MOVLF B'00010000',PORTA 	;Clear all counting bits from LPISR

			; Loop to check for human input
			checkHumanInput
				btfss PORTE, RE2		; check value of RE2, skip next instruction if RE2 =1  
				bra checkHumanInput		; otherwise, loop back to branch "checkHumanInput"

			bcf INTCON3, 0  ; Clear LP Interrupt FLAG
			bcf INTCON, 1	; Clear HP Interrupt FLAG
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	

	bcf PORTC,RC1			 ;Signal that we are Leaving HPISR - Added by AC - DO NOT MODIFY
	MOVLF  B'11111111',TMR0H ;Added by AC - DO NOT MODIFY
	MOVLF  B'00000000',TMR0L ;Added by AC - DO NOT MODIFY

retfie FAST

end
