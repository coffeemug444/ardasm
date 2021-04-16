# Synth

true 3 tone polyphony!!!
Note range from C2 - C9!!!

originally written in C but had to rewrite entirely in assembly because C wasn't fast enough, in particular storing and retrieving variables from memory and context switching. (Almost) everything is stored within the 32 general purpose registers for maximum speed (How else are you going to run interrupts at 250kHz on a 16MHz clock?)

I can say now that I sort of understand assembly, and I'm also never touching it again.
