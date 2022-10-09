;
; main.asm
;    Final Project - Fan Controller using Buttons
;    
;
;
;
; Created: 12/5/2021 8:25:17 PM
; Author : Jake Hanson, Rachel Gonzalez, Mohammed Siddiqui

.macro __INIT_STACK           ; stack initialization
     ldi  r16,HIGH(RAMEND)
     out  SPH,r16
     ldi  r16,LOW(RAMEND)
     out  SPL,r16
.endmacro

; Vector table -------------------------------------------------------
.org 0x00                     ; reset
     jmp  Main
.org 0x02                     ; External Interrupt INT0 (D2)
     jmp  EX0_ISR_Slow
.org 0x04                     ; External Interrupt INT1 (D3)
     jmp  EX1_ISR_Fast
.org INT_VECTORS_SIZE

; Start Main ------------------------------------------------------------------
Main:
     __INIT_STACK                  ; stack macro

; Configure I/O
     cbi  DDRD,DDD2                ; make D2 input
     sbi  PORTD,PD2                ; set D2 high (pull up)

     cbi  DDRD,DDD3                ; make D3 input
     sbi  PORTD,PD3                ; set D3 high (pull up)

     sbi  DDRD,DDD5                ; make D5 output
     sbi  PORTD,PD5                ; LED for no fan movement (on by default)

     sbi  DDRD,DDB6                ; make D6 output
     cbi  PORTD,PD6                ; LED for slow fan movement (off by default)

     sbi  DDRD,DDB7                ; make D7 output
     cbi  PORTD,PD7                ; LED for fast fan movement (off by default)

; stepper motor I/O
     sbi  DDRD,DDB0                ; make B0 output
     cbi  PORTB,PB0                ; off by default

     sbi  DDRD,DDB1                ; make B1 output
     cbi  PORTB,PB1                ; off by default

     sbi  DDRD,DDB2                ; make B2 output
     cbi  PORTB,PB2                ; off by default

     sbi  DDRD,DDB3                ; make B3 output
     cbi  PORTB,PB3                ; off by default

; Configure interrupts for I/O
     ldi  r20,(1<<INT0)|(1<<INT1)       ; enable INT0 and INT1
     out  EIMSK,r20

     ldi  r20,(1<<ISC01)|(1<<ISC11)     ; INT0 + INT1 falling edge trigger... INT1 triggers when you pull input wire D3...
     sts  EICRA,r20


     ; main program (stepper here?)
     ;ldi  r20,0x06       ; load step sequence
;L1:
     ;out  PORTD,r20      ; PORTB = r20
     ;lsr  r20            ; shift right
     ;brcc L2             ; if not carry skip next
     ;ori  r20,0x8
;L2:
     ;rcall DELAY         ; wait
     ;rjmp L1
;DELAY:
     ;ldi r17,255
;D_L0:
     ;ldi r16,255
;D_L1:
     ;nop
     ;dec  r16
     ;brne D_L1
     ;dec  r17
     ;brne D_L0
     ;ret

     sei                           ; enable global interrupts

Here:
     rjmp Here

; Stepper Motor Control -----------------------------------------------------------



; Interrupt Service Routines ------------------------------------------------------
; SLOW MODE (PORTD PD2)
EX0_ISR_Slow:
     ldi  r23,0b00001000                     ; PORTD PD6 is the only pin turned on -- hope this doesn't mess up the input pins
     out  PORTD,r23                          ; turn off PORTD Pin 5, turn on PORTD Pin 6 (slow mode)
     call T1Normal                           ; 4 second delay
     ldi  r23,0b00010000                     ; turn on PORTD Pin 5, turn off PORTB Pin 6
     out  PORTD,r23
     reti

; FAST MODE (PORTD PD3)
EX1_ISR_Fast:
     ldi  r23,0b01000000                     ; PORTB PB2 is the only pin turned on
     out  PORTD,r23                          ; turn off PORTB Pin 5, turn on PORTB Pin 7 (fast mode)
     call T1Normal                           ; 4 second delay
     ldi  r23,0b00010000                     ; turn on PORTD Pin 5, turn off PORTB Pin 7
     out  PORTD,r23
     reti


; Timer 1 --------------------------------------------------------------------------
T1Normal:
	; load TCNT1 with initial count (4 seconds @ 16 MHz)
	ldi	r20,HIGH (62500-1)
	sts	OCR1AH,r20
	ldi	r20,LOW (62500-1)
	sts	OCR1AL,r20

	ldi  r20,0
	sts	TCNT1H,r20
	sts	TCNT1L,r20		; TCNT1L = 0x00, TCNT1H = TEMP

	ldi	r20,0x00
	sts	TCCR1A,r20		; WGM11:10 = 00
	ldi	r20,0x5			; prescaler 1024
	sts	TCCR1B,r20		; WGM13:12=00, normal mode, clk/1024

Again:
	sbis	TIFR1,OCF1A	     ; if OCF1A set, skip next instruction
	rjmp Again

	ldi	r19,0
	sts	TCCR1B,r19		; stop timer
	sts  TCCR1A,r19
	ldi	r20,1<<OCF1A
	out	TIFR1,r20		     ; clear OCF1A flag
	ret