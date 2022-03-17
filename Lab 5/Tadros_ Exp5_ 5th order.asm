 ;;;;;;; P5 for EE425 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Use this template for Experiment 5
; This file was created by AC on 3/31/2020
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

        cblock  0x000           ;Beginning of Access RAM
		; --- BEGIN variables for TABLAT POINTER
		; DO NOT MODIFY (created by AC) 
		value
		counter
		; --- END variables for TABLAT POINTER

		; Create your variables starting from here
		value1 ; first memory location in the buffer 
		value2 ; second memory location in the buffer
		value3 ; third memory location in the buffer
		value4 ; fourth memory location in the buffer
		SMPLCNT ; sample count to keep track of the first three samples in the initial buffer
		dividedSum ; the output of the filter
		periodNumber ; track the number of periods the signal makes

        endc

;;;;;;; Macro definitions ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MOVLF   macro  literal,dest
        movlw  literal
        movwf  dest
        endm


;;;;;;; Vectors ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        org  0x0000             ;Reset vector
        nop
        goto  Mainline

        org  0x0008             ;High priority interrupt vector
        goto  $  ;Trap

        org  0x0018             ;Low priority interrupt vector
        goto  $                  ;Trap

;;;;;;; Mainline program ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Mainline
        rcall  Initial          ;Initialize everything
Loop
	
		MOVLF  10,counter
		MOVLF 10, SMPLCNT ; SMPLCNT is initialized to 10 so that it can be compared with counter
		MOVLF upper SimpleTable,TBLPTRU 
		MOVLF high  SimpleTable,TBLPTRH 
	MOVLF low   SimpleTable,TBLPTRL
	label_A
		TBLRD*+
		movf TABLAT, W
	movwf value ; value = x[n]

		;;;;;;; NOTE FOR STUDENTS:
		; 
		; Write the code for your moving average filter in 
		; the empty spaces below. Please create subroutines 
		; to make code your code transparent and easier to debug
		;
		; DO NOT MODIFY ANY OTHER PART OF THE THIS LOOP IN THE MAINLINE
		;
		; --------------------------------------------------------------
		; BEGIN WRTING CODE HERE 
		
			; ---------------------------------
			; (1) WRITE CODE FOR MEMORY BUFFER HERE
			;       you may write the full code 
			;		here or call a subroutine

				rcall bufferUpdate


	
			; ---------------------------------
			; (2) WRITE CODE FOR ADDER AND "DIVIDER" HERE 
			;       you may write the full code 
			;		here or call a subroutine

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; SampleSum subroutine, which performs the filtering, is defined below and is called inside the bufferUpdate subroutine
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				 

		; FINISH WRTING CODE HERE 
		; --------------------------------------------------------------

		decf  counter,F        
	    bz  label_B
		bra label_A
	label_B

		incf periodNumber, F ; increment periodNumber
        bra	Loop
	
SampleSum
				movlw 0 ; clean working register for addition
				addwf value1, WREG ; x[n-3]
				addwf value4, WREG ; x[n] or the new sample added to the buffer
				movwf dividedSum			; move content of WREG into dvidiedSum
				rrcf dividedSum 	; dividing sum by 2: moving dividedSum to WREG and rotate WREG to right through a carry 
				return

bufferUpdate
				;;;;; checking state of signal
				MOVLF 1, WREG		
				cpfseq periodNumber	; if periodNumber variable = 1, then intialize buffer. Otherwise, keep updating the buffer 
				bra label_F
			
				;;; buffer intialization starts here.....
				movf counter, WREG
				cpfseq SMPLCNT 		; SMPLCNT = 10, first sample to be read in initial buffer
									; SMPLCNT is initialized to 10 so that it can be compared with counter
				bra label_C

				movf value, WREG 
				movwf value1
				bra exit

			label_C
				
				MOVLF 9, SMPLCNT 	; SMPLCNT = 9, second sample to be read in initial buffer
				movf counter, WREG ; note that counter is stored again in WREG after MOVLF as MOVLF will change the value of WREG

				cpfseq SMPLCNT
				bra label_D
				movf value, WREG
				movwf value2
				bra exit
			
			label_D	
				
				MOVLF 8, SMPLCNT ;  SMPLCNT = 8, third sample to be read in initial buffer
				movf counter, WREG 

				cpfseq SMPLCNT 	
				bra label_E
				movf value, WREG
				movwf value3
				bra exit
			
			label_E
				MOVLF 7, SMPLCNT ;  SMPLCNT = 7, fourth sample to be read in initial buffer
				movf counter, WREG 

				cpfseq SMPLCNT 	
				bra label_F
				movf value, WREG
				movwf value4
				rcall SampleSum
				bra exit
			
			label_F
				;updating the buffer when a new sample is added.
				;move value2 of previous buffering into value1 of new buffering
				movf value2, W
				movwf value1		; value1 is the new x[n-3]
				
				;move value3 of previous buffering into value2 of new buffering
				movf value3, W
				movwf value2

				;move value4 of previous buffering into value3 of new buffering
				movf value4, W
				movwf value3

				;value4 of new buffering is the new sample added (denoated by variable value)
				movf value, W
				movwf value4     ; value4 is the new x[n]
				
				rcall SampleSum
				bra exit				
			exit
return
	
;;;;;;; Initial subroutine ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; This subroutine performs all initializations of variables and registers.

Initial
        MOVLF  B'10001110',ADCON1  ;Enable PORTA & PORTE digital I/O pins
        MOVLF  B'11100001',TRISA  ;Set I/O for PORTA 0 = output, 1 = input
        MOVLF  B'11011100',TRISB  ;Set I/O for PORTB
        MOVLF  B'11010000',TRISC  ;Set I/0 for PORTC
        MOVLF  B'00001111',TRISD  ;Set I/O for PORTD
        MOVLF  B'00000000',TRISE  ;Set I/O for PORTE
        MOVLF  B'10001000',T0CON  ;Set up Timer0 for a looptime of 10 ms;  bit7=1 enables timer; bit3=1 bypass prescaler
        MOVLF  B'00010000',PORTA  ;Turn off all four LEDs driven from PORTA ; See pin diagrams of Page 5 in DataSheet
		MOVLF 1, periodNumber	; periodNumber is initially zero 
        return



;;;;;;; TIME SERIES DATA
;
; 	The following bytes are stored in program memory.
;   Created by AC 
;	DO NOT MODIFY
;
SimpleTable 
db 0,50,100,150,200,250,200,150,100,50
; --------------------------------------------------------------

        end


