'''
prints hex delay values for all notes C2 - C8 inclusive for a given interrupt frequency
'''

interrupt_frequency = 125000

ratio = 2 ** (1/12)
A = 440

notes = [A]

for i in range(12*4 + 3):
    notes.append(440 * (ratio**(i + 1)))

for i in range(12*3 - 3):
    notes.insert(0, 440/(ratio**(i + 1)))

things = []

for note in notes:
    print(hex(round(interrupt_frequency/note)))
