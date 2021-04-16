list = [
0,
1,
1,
2,
3,
3,
4,
5,
6,
6,
7,
8,
8,
9,
10,
10,
11]

list2 = [
    "\"C"  ,
    "\"Cs" ,
    "\"Db" ,
    "\"D"  ,
    "\"Ds" ,
    "\"Eb" ,
    "\"E"  ,
    "\"F"  ,
    "\"Fs" ,
    "\"Gb" ,
    "\"G"  ,
    "\"Gs" ,
    "\"Ab" ,
    "\"A"  ,
    "\"As" ,
    "\"Bb" ,
    "\"B"
]

for i in range(7):
    for j in range(17):
        print(list2[j] + str(i + 2) + "\":" + str(list[j] + 12*i) + ",")
