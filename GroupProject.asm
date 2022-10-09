;
; GroupProject.asm
; CDA 3104 Group Project
; Authors : Mohammed Siddiqui, Jacob Hanson, Rachel Gonzalez
;

;Need:    two external interrupt switches, one slow speed after press, one high speed after press, use falling-edge interrupts for pull-up input switches on both [X]
;         three LEDs, one green, one yellow, one red. Red for no fan movement, yellow for slow fan speed, green for high fan speed                                [X]
;         timer for how long the fan will run after switch is pressed (4 seconds) called from ISRs                                                                [X]
;         configure and implement step motor for slow and high speed                                                                                              [ ]

;Process: 1. Start with fan off, Red LED on by default indicating the fan is not moving.
;         2. Program waits in infinite loop for input on slow-speed switch (D2), or fast-speed switch (D3).
;         3. Once a switch is pressed, begin external hardware ISR and jump to the appropriate subroutine.
;         4. LEDs are toggled so the LED representing the current fan speed is the only one enabled.
;         5. Step motor begins spinning fan.
;         6. 4 second timer begins.
;         7. Once timer finishes, the step motor turns off and the LEDs are toggled to represent current fan speed.

;Possible improvements?
;         Could make another subroutine to contain the timers (lines 103-107 & 124-128) for the ISRs to call

; Interrupt Vector Table
;----------------------------------------------------------
.org 0x00                ; reset
     rjmp Main
.org INT0_vect           ; left switch press
     rjmp Fan_Slow
.org INT1_vect           ; right switch press
     rjmp Fan_Fast
.org INT_VECTORS_SIZE    ; end of vector table

; Main
;----------------------------------------------------------
Main:
     ; initialize stack pointer
     ldi  r16,high(RAMEND)
     out  SPH,r16
     ldi  r16,low(RAMEND)
     out  SPL,r16

     
     ; configure I/O
     cbi  DDRD,DDD2                               ; make D2 input
     sbi  PORTD,PD2                               ; pull-up mode for slow-mode switch external interrupt
     
     cbi  DDRD,DDD3                               ; make D3 input
     sbi  PORTD,PD3                               ; pull-up mode for fast-mode switch external interrupt
     
     sbi  DDRB,DDB0                               ; make B0 output
     sbi  PORTB,PB0                               ; LED for no fan movement (on by default)
     
     sbi  DDRB,DDB1                               ; make B1 output
     cbi  PORTB,PB1                               ; LED for slow fan movement (off by default)
     
     sbi  DDRB,DDB2                               ; make B2 output
     cbi  PORTB,PB2                               ; LED for fast fan movement (off by default)


     ; configure External Hardware Interrupts
     ldi r20,(1<<INT0)|(1<<INT1)                  ; enable External Interrupt Request 0 & 1
     sts EIMSK,r20

     ldi r20,(1<<ISC01)                           ; enable falling-edge-triggered interrupt on D2
     sts EICRA,r20

     ldi r20,(1<<ISC11)                           ; enable falling-edge-triggered interrupt on D3
     sts EICRA,r20

     sei                                          ; enable global interrupts

     
     ; configure Timer1 in CTC Mode               
     clr  r20
     sts  TCNT1H,r20                              ; clear TCNT1 for CTC
     sts  TCNT1L,r20            
     
     ldi  r20,high(62500-1)                       ; set CTC timer for 4s @ 16Mhz
     sts  OCR1AH,r20 
     ldi  r20,low(62500-1)
     sts  OCR1AL,r20
     
     clr  r20
     sts  TCCR1A,r20                              ; ctc mode 
     ldi  r20,(1<<WGM12)|(1<<CS12)|(1<<CS10)      ; prepare values to start timer, setting clock bits inside ISRs for ctc prescaler clk/1024, 4s @ 16MHz 

     ; configure step motor
     ; ...

     
Interrupt_Wait:
    rjmp Interrupt_Wait


; Slow Speed
;----------------------------------------------------------
Fan_Slow:
     cbi  PORTB,PB0       ; turn off no-movement LED
     sbi  PORTB,PB1       ; turn on slow-movement LED

     ; TURN ON STEP MOTOR AT SLOW SPEED HERE

     sts  TCCR1B,r20     ; start the timer for ctc prescaler clk/1024 @ 16MHz

OCF1_Wait:
     sbis T1FR1,OCF1A    ; monitor output compare flag
     rjmp OCF1_Wait

     ;TURN OFF STEP MOTOR HERE

     cbi  PORTB,PB1       ; turn off slow-movement LED
     sbi  PORTB,PB0       ; turn on no-movement LED
     reti                 ; end Fan_Slow


; Fast Speed
;----------------------------------------------------------
Fan_Fast:
     cbi  PORTB,PB0       ; turn off no-movement LED
     sbi  PORTB,PB2       ; turn on fast-movement LED

     ; TURN ON STEP MOTOR AT HIGH SPEED HERE

     sts  TCCR1B,r20      ; start the timer for ctc prescaler clk/1024 @ 16MHz

OCF1_Wait:
     sbis T1FR1,OCF1A     ; monitor output compare flag
     rjmp OCF1_Wait

     ;TURN OFF STEP MOTOR HERE     

     cbi  PORTB,PB2       ; turn off fast-movement LED
     sbi  PORTB,PB0       ; turn on no-movement LED
     reti                 ; end Fan_Fast