.include "./m328Pdef.inc"

; register info:
; r14 is your 0
; r13 is your 1
; r29 is used to hold the status register during the interrupt
; r0-r12 are used to store counters for pins 8-10
; pin registers in form:
;	rn  , rn+1: fast frequency timers (microseconds)
;	rn+2, rn+3: slow noteOn timers    (milliseconds)
; r15 stores the status of pins 8-10, in form:
;	00aaaxxx
;	a: pin is enabled
; 	x: pin is high
; r20-r24 are used for uart receive

.dseg

f1L: .byte 1	; frequency 1
f1H: .byte 1

f2L: .byte 1	; frequency 2
f2H: .byte 1

f3L: .byte 1	; frequency 3
f3H: .byte 1

.def zeroReg=r14
.def oneReg=r13

.cseg

.org $0000						; initial point of entry
	rjmp main

.org $0016						; TIMER1_COMPA interrupt (1kHz)
	rjmp timerint

.org $001C						; TIMER0_COMPA interrupt (fuckin' fast)
	rjmp freqint



timerint:
	in r29,SREG					; save status register
	
counter1:
	sub r7, oneReg
	sbc r6, zeroReg
	brne counter2
	mov r28, r15
	andi r28, ~(1<<0)
	mov r15, r28
counter2:
	sub r9, oneReg
	sbc r8, zeroReg
	brne counter3
	mov r28, r15
	andi r28, ~(1<<1)
	mov r15, r28
counter3:
	sub r11, oneReg
	sbc r10, zeroReg
	brne timerintend
	mov r28, r15
	andi r28, ~(1<<2)
	mov r15, r28
timerintend:
	out SREG, r29				; restore status register
	reti						; return from interrupt
	

freqint:
	in r29,SREG					; save the status register
	clr r19

timer1:
	sub r1, oneReg
	sbc r0, zeroReg
	brne timer2

	mov r19, r15
	andi r19, (1<<0)
	breq timer2
	sbi pinb, 0
	
	lds r0, f1H
	lds r1, f1L

timer2:
	sub r3, oneReg
	sbc r2, zeroReg
	brne timer3

	mov r19, r15
	andi r19, (1<<1)
	breq timer3
	sbi pinb, 1
	

	lds r2, f2H
	lds r3, f2L

timer3:
	sub r5, oneReg
	sbc r4, zeroReg
	brne freqintend

	mov r19, r15
	andi r19, (1<<2)
	breq freqintend
	sbi pinb, 2
	

	lds r4, f3H
	lds r5, f3L

freqintend:
	out SREG, r29
	reti


main:
	clr r15						; initialize with no timers active

	ldi r16, 1
	mov oneReg, r16				; store 1 permanently in r13
	clr zeroReg					; keep r14 as a 0 byte

	ldi r16, $FF
	out DDRB, r16				; set arduino pins 8, 9, 10 to output (also pin 13, the LED pin) (tmp, everything is an output)
	ldi r16, 0
	out PortB, r16				; set all portB to 0

	clr r0						; clear all counter registers
	clr r1
	clr r2
	clr r3
	clr r4
	clr r5
	clr r6
	clr r7
	clr r8
	clr r9
	clr r10
	clr r11
	

	cli							; disable interrupts while setting up timers


	; set up counter0 (high frequency)
	ldi r16, 7					; 250kHz
	out OCR0A, r16
	ldi r16, 1<<WGM01			
	out TCCR0A, r16				; specificies CTC mode
	ldi r16, 1<<CS01
	out TCCR0B, r16				; specifies clk/8 prescaler

	; set up counter1 (low frequency)
	ldi r16, 0b00000111			; to write to 16 bit registers write to HIGH FIRST
	sts OCR1AH, r16				
	ldi r16, 0b11001111			
	sts OCR1AL, r16				; OCR1A contains decimal 1999
	ldi r16, 1<<CS11|1<<WGM12	; specifies clk/8 prescaler in CTC mode
	sts TCCR1B, r16
	
	; set output compare A match for timers 0 and 1
	ldi r16, 1<<OCIE0A
	sts TIMSK0, r16	
	ldi r16, 1<<OCIE1A
	sts TIMSK1, r16


	;set up USART
	clr r16
	sts UBRR0H, r16
	ldi r16, 103
	;ldi r16, 8
	sts UBRR0L, r16						; baud rate of 115200

	ldi r16, (1<<RXEN0);|(1<<TXEN0)         		; enable RX
	sts UCSR0B, r16

	ldi r16, (1<<UCSZ01)|(1<<UCSZ00);|(1<<USBS0)	; no parity, 1 stop bit, eight bit word size
	;ldi r16, (1<<UPM01)|(1<<USBS0)|(1<<UCSZ01)|(1<<UCSZ00)
	sts UCSR0C, r16

	sei							; enable interrupts

	; really shitty way of delaying for about 400ms to settle down 
	sbi pinb, 5

	ldi r16, $FF
	ldi r17, $FF
	ldi r18, 20
	del1:
	subi r16, 1
	brne del1
	del2:
	ldi r16, $FF
	subi r17, 1
	brne del1
	del3:
	ldi r17, $FF
	subi r18, 1
	brne del1

	sbi pinb, 5

USART_Flush:
	LDS r16, UCSR0A
	sbrs r16, RXC0
	jmp loop
	LDS r16, UDR0
	rjmp USART_Flush


loop:
	rjmp receiveBytes			; blocks until it receives 3 new bytes
	rjmp loop	; shouldn't get here




placeNote:
	ldi ZL, LOW(2*note)
	ldi ZH, HIGH(2*note)
	add ZL, r22

try_one:
	mov r16, r15
	andi r16, (1<<0)
	brne try_two

	cli
	mov r16, r15
	ori r16, 1<<0
	mov r15, r16
	mov r6, r21			; store timeOn in r6,r7
	mov r7, r20
	lpm r0, Z+			; store note period in r0,r1
	lpm r1, Z
	sts f1H, r0			; store note period in memory
	sts F1L, r1
	sei
	rjmp loop

try_two:
	mov r16, r15
	andi r16, (1<<1)
	brne try_three

	cli
	mov r16, r15
	ori r16, 1<<1
	mov r15, r16
	mov r8, r21	
	mov r9, r20
	lpm r2, Z+
	lpm r3, Z
	sts f2H, r2
	sts F2L, r3
	sei
	rjmp loop

try_three:
	mov r16, r15
	andi r16, (1<<2)
	brne loop

	cli
	mov r16, r15
	ori r16, 1<<2
	mov r15, r16
	mov r10, r21
	mov r11, r20
	lpm r4, Z+
	lpm r5, Z
	sts f3H, r4
	sts F3L, r5
	sei
	rjmp loop
	




; receive 3 bytes, 2 for note on time, 1 for note
receiveBytes:
receive_one:
    LDS r16, UCSR0A
	sbrs r16, RXC0
	rjmp receive_one
	LDS r20, UDR0				; time on low byte
receive_two:
    LDS r16, UCSR0A
	sbrs r16, RXC0
	rjmp receive_two
	LDS r21, UDR0				; time on high byte
receive_three:
    LDS r16, UCSR0A
	sbrs r16, RXC0
	rjmp receive_three
	LDS r22, UDR0				; note index

	rjmp placeNote




.org 512
note: .db 	$07,$77,$07,$0c,$06,$a7,$06,$47,$05,$ed,$05,$98,$05,$47,$04,$fc,\
			$04,$b4,$04,$70,$04,$31,$03,$f4,$03,$bc,$03,$86,$03,$53,$03,$24,\
			$02,$f6,$02,$cc,$02,$a4,$02,$7e,$02,$5a,$02,$38,$02,$18,$01,$fa,\
			$01,$de,$01,$c3,$01,$aa,$01,$92,$01,$7b,$01,$66,$01,$52,$01,$3f,\
			$01,$2d,$01,$1c,$01,$0c,$00,$fd,$00,$ef,$00,$e1,$00,$d5,$00,$c9,\
			$00,$be,$00,$b3,$00,$a9,$00,$9f,$00,$96,$00,$8e,$00,$86,$00,$7f,\
			$00,$77,$00,$71,$00,$6a,$00,$64,$00,$5f,$00,$59,$00,$54,$00,$50,\
			$00,$4b,$00,$47,$00,$43,$00,$3f,$00,$3c,$00,$38,$00,$35,$00,$32,\
			$00,$2f,$00,$2d,$00,$2a,$00,$28,$00,$26,$00,$24,$00,$22,$00,$20,\
			$00,$1e,$00,$1c,$00,$1b,$00,$19,$00,$18,$00,$16,$00,$15,$00,$14,\
			$00,$13,$00,$12,$00,$11,$00,$10,$00,$0f
