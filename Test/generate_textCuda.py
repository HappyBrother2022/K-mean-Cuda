# -*- coding: utf-8 -*-
"""
Created on Sat Aug 21 23:20:51 2021

@author: ALEX
"""
import random, math

i = 1;

f = open("dataset.txt", "w")
while i < 10000:   
    x1 = random.uniform(1,10000)
    x2 = random.uniform(1,10000)
    x3 = random.uniform(1,10000)
    x4 = random.uniform(1,10000)
    tt = ['first','sec','thir','forth']
    x5 = random.choice(tt)
    f.write(str(x1) + ' '+ str(x2)+' '+ str(x3)+' '+ str(x4) + ' '+ str(x5) + '\n')
    i += 1
f.close()

#open and read the file after the appending:
f = open("dataset.txt", "r")
print(f.read())