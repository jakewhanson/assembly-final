;
; fanControl.asm
;    Final Project - Fan Controller using Buttons
;    Two switches on a breadboard are connected to the PORTD D2 and D3 pins, allowing for external interrupts.
;    When a user presses one of these buttons, either D2 (slow mode) or D3 (fast mode) is activated, sending
;    power to either the yellow (slow) or green (fast) LED, along with calling the motor to give it the speed
;    it needs.
;
; Created: 12/5/2021 8:25:17 PM
; Author : Jake Hanson, Rachel Gonzalez, Mohammed Siddiqui

.macro __INIT_STACK                ; stack initialization
     ldi  r16,HIGH(RAMEND)
     out  SPH,r16
     ldi  r16,LOW(RAMEND)
     out  SPL,r16
.endmacro

; Vector table -------------------------------------------------------
.org 0x00                          ; reset
     jmp  Main
.org 0x02                          ; External Interrupt INT0 (D2)
     jmp  EX0_ISR
.org 0x04                          ; External Interrupt INT1 (D3)
     jmp  EX1_ISR
.org 0x16
     jmp  TIMER_ISR
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

/*; stepper motor I/O
     sbi  DDRD,DDB0                ; make B0 output
     cbi  PORTB,PB0                ; off by default

     sbi  DDRD,DDB1                ; make B1 output
     cbi  PORTB,PB1                ; off by default

     sbi  DDRD,DDB2                ; make B2 output
     cbi  PORTB,PB2                ; off by default

     sbi  DDRD,DDB3                ; make B3 output
     cbi  PORTB,PB3                ; off by default*/

; Configure interrupts for I/O
     ldi  r20,(1<<INT0)|(1<<INT1)       ; enable INT0 and INT1
     out  EIMSK,r20

     ldi  r20,(1<<ISC01)|(1<<ISC11)     ; INT0 + INT1 falling edge trigger
     sts  EICRA,r20

     sei                           ; enable global interrupts

Here:
     rjmp Here

;-----------------RESET AFTER 4 SECONDS-------------
TIMER_ISR:
     ldi  R20,0x00        ; STEPPER OFF
     out  DDRB,R20                        
     jmp  Main           ; SET LEDS


;------------------STEPPER_SLOW_START--------------------------
EX0_ISR:                                     
     cbi  PORTD,PD5                ;LED for no fan movement OFF

     sbi  DDRD,DDD6                ; LED for slow fan movement ON
     sbi  PORTD,PD6 
     
T1Normal_0:                   
     ldi         r20,HIGH(62500-1)       
     sts       OCR1AH,r20
     LDI       r20,LOW(62500-1)     
     sts       OCR1AL,r20

     ldi       r20,0x00
     sts       TCCR1A,r20
     ldi       r20,0xD
     sts       TCCR1B,r20

     ldi       r20,(1<<OCIE1A)
     sts       TIMSK1,r20
     sei                      ; enable interrupts

     ldi       r20,0x00
     sbi       PORTB,PINB3


Step_0:
     LDI R20, 0b00001111 

     OUT DDRB, R20
     LDI R20, 0x06
L1_0:
     OUT PORTB, R20
     LSR R20
     BRCC L2_0   ; load step sequence;
     ORI R20, 0x8
L2_0:
     RCALL DELAY ;wait
     rjmp L1_0
DELAY:
     ldi r17,255
D_L0_0:
     ldi r16,150
D_L1_0:
     nop
     dec  r16
     brne D_L1_0
     dec  r17
     brne D_L0_0
     ret
;------------------STEPPER_SLOW_END--------------------------


;------------------STEPPER_FAST_START--------------------------

EX1_ISR:                                     
     cbi  PORTD,PD5      ;LED for no fan movement OFF
                                           
     sbi  DDRD,DDD7     ; LED for fast fan movement ON
     sbi  PORTD,PD7 

T1Normal_1:                   
     ldi         r20,HIGH(62500-1)       
     sts       OCR1AH,r20
     LDI       r20,LOW(62500-1)     
     sts       OCR1AL,r20

     ldi       r20,0x00
     sts       TCCR1A,r20
     ldi       r20,0xD
     sts       TCCR1B,r20

     ldi       r20,(1<<OCIE1A)
     sts       TIMSK1,r20
     sei                      ; enable interrupts

     ldi       r20,0x00
     sbi       PORTB,PINB3

Step_1:
     LDI R20, 0b00001111 ;Port B as output

     OUT DDRB, R20
     LDI R20, 0x06
L1_1:
     OUT PORTB, R20
     LSR R20
     BRCC L2_1   ; load step sequence;
     ORI R20, 0x8
L2_1:
     RCALL DELAY ;wait
     rjmp L1_1
DELAY_1:
     ldi r17,255
D_L0_1:
     ldi r16,40
D_L1_1:
     nop
     dec  r16
     brne D_L1_1
     dec  r17
     brne D_L0_1
     ret

;------------------STEPPER_FAST_END--------------------------