;
; Sempl.asm
;
; Created: 1/22/2022 10:23:36 PM
; Author : Admin
;
.include "m328pdef.inc"
.equ num0=0b00111111;0
.equ num1=0b00000110;1
.equ num2=0b01011011;2
.equ num3=0b01001111;3
.equ num4=0b01100110;4
.equ num5=0b01101101;5
.equ num6=0b01111101;6
.equ num7=0b00000111;7
.equ num8=0b01111111;8
.equ num9=0b01101111;9
.equ pin=1
.equ skip=0xcc
.equ convert=0x44
.equ read=0xbe

.macro wait
	
	ldi r16, @1
	wn1:
	dec r16
	breq ec

	ldi r17, @0
	wn2:
	dec r17
	breq wn1

	ldi r18, 1
	wn3:
	dec r18
	brne wn3
	rjmp wn2
	ec:

.endmacro

.def temp=r16
.def try=r17
.def other=r18
.def num=r19
.def temp2=r20


.dseg
.org SRAM_START
numbers: .byte 10
sdvig: .byte 1
var:	.byte 1
razr:	.byte 3
segment: .byte 3;0x105
ds18: .byte 1



.cseg 
.org 0x00
rjmp reset

.org 0x0020
rjmp segm

reset:
ldi temp, low(ramend)
out spl, temp
ldi temp, high(ramend)
out sph, temp

ldi temp, 251
sts sdvig, temp

ldi r30, low(segment)
ldi r31, high(segment)

ser temp
out DDRB, temp
out PORTB, temp
out DDRD, temp
clr temp
out PORTD, temp

ldi temp, 2
out TCCR0B, temp
ldi temp, 1
sts TIMSK0, temp

ldi temp, num0
sts numbers, temp
ldi temp, num1
sts numbers+1, temp
ldi temp, num2
sts numbers+2, temp
ldi temp, num3
sts numbers+3, temp
ldi temp, num4
sts numbers+4, temp
ldi temp, num5
sts numbers+5, temp
ldi temp, num6
sts numbers+6, temp
ldi temp, num7
sts numbers+7, temp
ldi temp, num8
sts numbers+8, temp
ldi temp, num9
sts numbers+9, temp

ldi temp, 156
sts var, temp

clr r21
sei
main:
	;rcall calc
	;rcall disp
	rcall check
	;-------------------
	ldi temp, skip
	sts ds18, temp 
	rcall wbyte
	
	wait 150,4

	ldi temp, convert
	sts ds18, temp
	rcall wbyte

	wait 255, 40
	;-------------------
	rcall check

	ldi temp, skip
	sts ds18, temp
	rcall wbyte

	wait 150,4

	ldi temp, read
	sts ds18, temp
	rcall wbyte
	;------------------------
	wait 150,4
	rcall rbyte
	lds temp, ds18
	wait 10,4
	rcall rbyte
	lds try, ds18

	ldi other, 4
	sdv:
	lsl temp
	brcs n1

	lsl try
	rjmp et

	n1:
	lsl try
	inc try
	et:
	dec other
	brne sdv
	sts var, try

	rcall calc
	rcall disp
	
rjmp main

check:
	
	sbi DDRC, 1
	wait 255, 4

	cbi DDRC, 1
	wait 70, 2
	sbic PINC, 1
	rjmp k1

	;ldi temp, 1
	;sts var, temp
	wait 255, 4
	rjmp k2
	k1:
	;ldi temp, 0
	;sts var, temp
	wait 255, 4
	rjmp check
	k2:
ret

wr1:
cli
	sbi DDRC, pin
	wait 3,4;1.2ns
	cbi DDRC, pin
	wait 45,4;60ns
	sei
ret

wr0:
cli
	sbi DDRC, pin
	wait 45,4; 60ns
	cbi DDRC, pin
	wait 15,4; 20us
	sei
ret

wbyte:
cli
	lds r21, ds18
	ldi r20, 8
loop:
	lsr r21
	brcs we1
	rcall wr0
	rjmp end
we1: 
	rcall wr1
end: 
	dec r20
	brne loop
	sei
ret

rbit:
cli
	lds temp, ds18
	sbi DDRC, pin
	wait 3,4
	cbi DDRC, pin
	wait 10,4
	lsr temp
	sbic PINC, pin
	ori temp, 0x80
	sts ds18, temp
	wait 30, 4
sei
ret

rbyte:
cli
	ldi r20, 8
	fv:
	rcall rbit
	dec r20
	brne fv
ret
calc:
	clr try
	lds temp, var
	c1:
	cpi temp, 100
	brcs c2
	subi temp, 100
	inc try 
	rjmp c1

	c2:
	sts razr, try
	clr try
	c3:
	cpi temp, 10
	brcs c4
	subi temp, 10
	inc try
	rjmp c3

	c4:
	sts razr+1, try
	sts razr+2, temp
ret

disp:
	ldi YL, low(numbers)
	ldi YH, high(numbers)
	lds temp, razr
	lds try, razr+1
	lds other, razr+2
	clr num

	d1:
	cp other, num
	brne d2
	ld temp2, Y
	sts segment, temp2

	d2:
	cp try, num
	brne d3
	ld temp2, Y
	sts segment+1, temp2

	d3:
	cp temp, num
	brne d4
	ld temp2, Y
	sts segment+2, temp2
	
	d4:
	cpi num, 9
	breq dEX
	inc num
	adiw Y, 1
	rjmp d1

	dEX:
	clr num
ret
segm:
	push temp
	in temp, sreg
	push temp
	push try
	
	ld try, Z+
	lds temp, sdvig
	out PORTD, try
	out PORTB, temp
	asr temp
	cpi temp, 255
	breq wt1
	rjmp ex

	wt1:
	ldi temp, 0b11111011; 
	ldi r30, low(segment)
	ldi r31, high(segment)

	ex:
	sts sdvig, temp
	
	pop try
	pop temp
	out sreg, temp
	pop temp
reti
