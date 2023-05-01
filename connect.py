import serial
import serial.tools.list_ports
from time import sleep
from keys import keysdict
from os import walk


port_list = []
filename = ""

def print_ports():
    port_list.clear()
    ports = serial.tools.list_ports.comports()
    count = 1
    for port, desc, hwid in sorted(ports):
        port_list.append(port)
        print(str(count) + ":", port)
        count += 1

entered = False

while (not entered):
    print_ports()
    print("Please select the serial port to connect to (r to refresh ports)")
    words = input()
    if (words != "r"):
        words = int(words)
        words -= 1
        if words >= 0 and words < len(port_list):
            ser = serial.Serial(port=port_list[words],
                                baudrate=9600,
                                parity=serial.PARITY_NONE,
                                stopbits=serial.STOPBITS_ONE,
                                bytesize=serial.EIGHTBITS)
            entered = True
        else:
            print("invalid port")
sleep(1)

def send(v, time):
    b = bytearray([(time - 20) % 256, (time - 20) // 256, v*2])

    print("sending: ", end="")
    for byte in b:
        print(hex(byte), end=" ")
    print("")
    ser.write(b)


def doThings():
    intervals = {
        "t":0,
        "dt":0,
        "s":0,
        "ds":0,
        "e":0,
        "de":0,
        "q":0,
        "dq":0,
        "h":0,
        "dh":0,
        "w":0,
        "dw":0,
        "d":0,
        "dd":0
    }

    f = open(filename)
    lines = f.readlines()
    f.close()

    intervals["s"] = int(lines[0].split(":")[1].strip("\n"))
    intervals["t"] = round(intervals["s"] / 2)
    intervals["e"] = intervals["s"] * 2
    intervals["q"] = intervals["e"] * 2
    intervals["h"] = intervals["q"] * 2
    intervals["w"] = intervals["h"] * 2
    intervals["d"] = intervals["w"] * 2

    intervals["dt"] = round(intervals["t"] * 1.5)
    intervals["ds"] = round(intervals["s"] * 1.5)
    intervals["de"] = round(intervals["e"] * 1.5)
    intervals["dq"] = round(intervals["q"] * 1.5)
    intervals["dh"] = round(intervals["h"] * 1.5)
    intervals["dw"] = round(intervals["w"] * 1.5)
    intervals["dd"] = round(intervals["d"] * 1.5)

    for line in lines[1:]:
        if "-" not in line:
            line = line.strip("\n ")
            if line != "":
                notes = line.split(";")
                for note in notes:
                    note = note.strip()
                    parts = note.split(":")
                    interval_ms = 0
                    print(line)
                    if "+" in parts[1]:
                        for interval in parts[1].split("+"):
                            interval_ms += intervals[interval]
                    else:
                        interval_ms += intervals[parts[1]]
                    send(keysdict[parts[0]], interval_ms)
            sleep(intervals["s"]/1000)

entered = False
while (not entered):
    print("Please select the song to play:")
    f = []
    for (dirpath, dirnames, filenames) in walk("songs/"):
        f.extend(filenames)
        break
    i = 0
    for name in f:
        print(str(i + 1) + ": " + name)
        i += 1
    words = int(input())
    words -= 1
    if words >= 0 and words < len(f):
        filename = "songs/" + f[words]
        entered = True
    else:
        print("file invalid")

i = "d"
while (i != "e"):
    i = input("d to send data, e to exit\n")
    if (i == "d"):
        doThings()


ser.close()
