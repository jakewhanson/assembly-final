;
; fanControl.asm
;    Final Project - Fan Controller using Buttons
;    Two switches on a breadboard are connected to the PORTD D2 and D3 pins, allowing for external interrupts.
;    When a user presses one of these buttons, either D2 (slow mode) or D3 (fast mode) is activated, sending
;    power to either the yellow (slow) or green (fast) LED, along with calling the motor to give it the speed
;    it needs. Two seperate instances of Timer1 are used, in order to allow the external interrupts to control
;    the speed of the motor.
;
; Created: 12/1/2021
; Due: 12/9/2021
; Authors: Jake Hanson, Rachel Gonzalez, Mohammed Siddiqui
; --------------------------------------------------------------------------------------------------------------

; Interrupt Vector table -----------------------------------------
.org 0
     jmp  Main
.org 0x02
     jmp  EX0_ISR_Slow
.org 0x04
     jmp  EX1_ISR_Fast
.ORG 0x16
     jmp  TIMER_ISR
.org INT_VECTORS_SIZE
; End vector table -----------------------------------------------

; Main -----------------------------------------------------------
Main:
; Initialize Stack
     LDI  r20,HIGH(RAMEND)
     OUT  SPH,r20
     LDI  r20,LOW(RAMEND)
     OUT  SPL,r20

; GPIO Configuration
     CBI  DDRD,DDD2                ; make D2 input
     SBI  PORTD,PD2                ; set D2 high

     CBI  DDRD,DDD3                ; make D3 input
     SBI  PORTD,PD3                ; set D3 high

     SBI  DDRD,DDD5                               
     SBI  PORTD,PD5                ; LED for no fan movement (red, on by default)

     SBI  DDRD,DDD6                               
     CBI  PORTD,PD6                ; LED for slow fan movement (yellow, off by default)

     SBI  DDRD,DDD7                               
     CBI  PORTD,PD7                ; LED for fast fan movement (green, off by default)

; Interrupt Configuration
     LDI  r20,(1<<INT0)|(1<<INT1)       ; Enable INT0 and INT1 interrupts
     OUT  EIMSK,r20
     LDI  r20,(1<<ISC01)|(1<<ISC11)     ; INT0 + INT1 falling edge trigger
     STS  EICRA,R20

     SEI                                ; enable global interrupts
; end interrupt stuff

HERE:
     JMP  HERE

;-----------------RESET AFTER 4 SECONDS-------------
TIMER_ISR:
     LDI R20, 0x00       ; STEPPER OFF
     OUT DDRB, R20                        
     JMP  Main           ; SET LEDS


;------------------STEPPER_SLOW_START--------------------------
EX0_ISR_Slow:                                     
     cbi  PORTD,PD5                ; LED for no fan movement (red, OFF)
     sbi  DDRD,DDD6
     sbi  PORTD,PD6                ; LED for slow fan movement (yellow, ON)
     
T1Normal_0:                   
     ldi       r20,HIGH(62500-1)       
     sts       OCR1AH,r20
     LDI       r20,LOW(62500-1)     
     sts       OCR1AL,r20

     ldi       r20,0x00
     sts       TCCR1A,r20
     ldi       r20,0xD
     sts       TCCR1B,r20

     ldi       r20,(1<<OCIE1A)
     sts       TIMSK1,r20
     SEI                           ; enable Timer interrupt

     ldi       r20,0x00
     sbi       PORTB,PINB3

Step_0:
     LDI R20, 0b00001111           ; bitmask (B0-B3)
     OUT DDRB, R20
     LDI R20, 0x06                 ; stepper motor sequence (0110)
L1_0:
     OUT PORTB, R20
     LSR R20                       ; load step sequence
     BRCC L2_0
     ORI R20, 0x8
L2_0:
     RCALL DELAY                   ; wait for motor to complete sequence
     rjmp L1_0
DELAY:
     ldi r17,250                   ; value of 250 allows loop to run longer, resulting in slower motor speed
D_L0_0:
     ldi r16,200                   ; value of 200 allows loop to run longer, resulting in slower motor speed
D_L1_0:
     nop
     dec  r16
     brne D_L1_0
     dec  r17
     brne D_L0_0
     ret
;------------------STEPPER_SLOW_END----------------------------


;------------------STEPPER_FAST_START--------------------------

EX1_ISR_Fast:                                     
     cbi  PORTD,PD5                ; LED for no fan movement (red, OFF)
     sbi  DDRD,DDD7
     sbi  PORTD,PD7                ; LED for fast fan movement (green, ON) 

T1Normal_1:                   
     ldi       r20,HIGH(62500-1)       
     sts       OCR1AH,r20
     LDI       r20,LOW(62500-1)     
     sts       OCR1AL,r20

     ldi       r20,0x00
     sts       TCCR1A,r20
     ldi       r20,0xD
     sts       TCCR1B,r20

     ldi       r20,(1<<OCIE1A)
     sts       TIMSK1,r20
     SEI                           ; enable Timer interrupt

     ldi       r20,0x00
     sbi       PORTB,PINB3

Step_1:
     LDI R20, 0b00001111           ; bitmask (B0-B3)
     OUT DDRB, R20
     LDI R20, 0x06                 ; stepper motor sequence (0110)
L1_1:
     OUT PORTB, R20
     LSR R20                       ; load step sequence
     BRCC L2_1
     ORI R20, 0x8
L2_1:
     RCALL DELAY_1                   ; wait
     rjmp L1_1
DELAY_1:
     ldi r17,250                   ; value of 250 allows loop to run shorter, resulting in faster motor speed
D_L0_1:
     ldi r16,40                    ; value of 40 allows loop to run shorter, resulting in faster motor speed
D_L1_1:
     nop
     dec  r16
     brne D_L1_1
     dec  r17
     brne D_L0_1
     ret

;------------------STEPPER_FAST_END--------------------------