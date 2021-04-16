a:	sound.asm
	avra sound.asm
u:	sound.hex
	avrdude -p atmega328p -c arduino -b 115200 -P /dev/ttyUSB0 -U flash:w:sound.hex
clean:
	rm *.hex sound.obj

g:	a u
