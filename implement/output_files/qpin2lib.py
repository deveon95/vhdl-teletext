#!/usr/bin/env python3
# Generate KiCAD Symbol library from Quartus Pin Assignments for Intel (Altera) FPGAs
# To use run like: qpin2lib.py output_files/my_project.pin >my_library.lib 
# TODO: Add pin sorting options
# TODO: Add map of part numbers to package footprints
#       and add footprint annotations
# TODO: (longterm) make less janky schematic editor for pcbnew
# TODO: (Help wanted) make more pythonic (idiomatic)
# 

import sys
from itertools import filterfalse
filename = sys.argv[1];
boxtop = 150
def iscrud(l):
    global quartus_version
    global design
    global part
    if(l.find('Quartus')==0):
        quartus_version = l
        return True
    if(l.count(':')!=6):
        if(l.find('CHIP')==0):
            design = l.split('"')[1]
            part = l.split('ASSIGNED TO AN: ')[1]
        return True
    if(l.find('Pin Name/Usage')==0):
        global us
        us = l
        return True
    return False
def removecrud(a):
       return filterfalse(iscrud, a)
def removecomments(a):
    return map(lambda  x: x.split('--')[0], a)
def removeblanklines(a):
    return filterfalse(lambda x: x.isspace(), a)
def removewhitespacefromline(l):
    return ''.join(c for c in l if not c.isspace())
def removewhitespace(a):
    return map(lambda x: removewhitespacefromline(x), a)
with open(filename) as f:
    lines = removewhitespace(removecrud(removeblanklines(removecomments(f.read().splitlines()))))

def fixSignalName(s):
    return s.replace('[','_').replace(']','')

banks = dict()
class Bank:
    nextunit = 1
    def __init__(self,name):
        self.width = 400
        self.pins = []
        self.unit = Bank.nextunit
        Bank.nextunit += 1
        self.name = name
    def computeWidth(self):
        self.width = 600
        for p in self.pins:
            pwidth = len(p.signalName) * 50
            if pwidth + 100 > self.width:
                self.width = int(pwidth/100)*100 + 100
def getBank(name):
    if (name in banks):
        return banks[name]
    else:
        banks[name] = Bank(name)
        return banks[name]
def isJTAG(name):
    jtag_names = ['ALTERA_TDO','ALTERA_TDI','ALTERA_TCK','ALTERA_TMS']
    for i in jtag_names:
        if(i in name):
            return True
    return False
    
class Pin:
    def __init__(self,l):
        (signame, location, direction,
         ioStd, voltage,
         ioBank, userAssignment) = l.split(':')
        self.signalName = fixSignalName(signame)
        self.pinNo = location
        self.elecType = 'U'
        if(isJTAG(self.signalName)):
            ioBank = 'JTAG'
        if(direction in ['gnd', 'power']):
            ioBank = 'Power'
            self.elecType = 'W'
        if(direction=='bidir'):
            self.elecType = 'B'
        if(direction=='input'):
            self.elecType = 'I'
        if(direction=='output'):
            self.elecType = 'O'
        if(len(ioBank)==0):
            ioBank = 'Unknown'
        if(ioBank[0].isdigit()):
            ioBank = 'IOBank_'+ioBank
        bank = getBank(ioBank)
        bank.pins.append(self)

pins = []

for l in lines:
    pins.append(Pin(l))

def mapstr(*l):
    return map(lambda x: str(x), l)
def quote(s):
    return '"%s"' % (s)

def refcmd(ref):
    x = 0
    size = 60
    y = int((size / 4) * 5)
    visible = 'V'
    text_orient = 'H'
    htext_justify = 'C'
    vtext_justify = 'CNN'
    return ' '.join(mapstr('F0', quote(ref), x, y, size, text_orient,
                     visible, htext_justify, vtext_justify))
def namecmd(ref):
    x = 0
    y = boxtop
    size = 60
    visible = 'V'
    text_orient = 'H'
    htext_justify = 'C'
    vtext_justify = 'BNN'
    return ' '.join(mapstr('F1', quote(ref), x, y, size, text_orient,
                    visible, htext_justify, vtext_justify))
def fplistcmd():
    return []
def drawBank(b):
    unit = b.unit
    x1 = -b.width/2
    y1 = boxtop
    x2 = b.width/2
    y2 = -100 - len(b.pins) * 100
    # T direction posx posy text_size text_type unit convert text text_italic text_hjustify text_vjustify
    return ['S %0.f %0.f %0.f %0.f %d 0 0 N' % (x1,y1,x2,y2,unit),
            'T 0 %0.f %0.f 60 0 %d 0 %s Normal 0 L C' % (x1,y1-50,unit, b.name)
    ]

def drawPin(bank,pin,x,y):
    #XXX
    length = 200
    direction = 'L'
    name_text_size = 50
    num_text_size = 50
    electrical_type = pin.elecType
    pin_type = ''
    convert = 0
    # X name num posx posy length
    # direction
    # name_text_size num_text_size
    # unit convert electrical_type pin_type
    return [' '.join(mapstr('X', pin.signalName, pin.pinNo, x, y, length,
                            direction,
                            name_text_size,num_text_size,
                            bank.unit, convert,
                            electrical_type,pin_type))]

def drawlist():
    l = ['DRAW']
    for (bname,b) in banks.items():
        b.computeWidth()
        l += drawBank(b)
        i = 1
        for p in b.pins:
            l += drawPin(b,p, int(b.width/2 + 200), i * -100)
            i += 1
    l.append('ENDDRAW')
    return l
def writelib():
    name = '_'.join((part,design))
    ref = 'U'
    text_offset = 40
    nbanks = len(banks)
    lines = [
        'EESchema-LIBRARY Version 2.3',
        '#encoding utf-8',
        '#', '# %s' % (name),'#',
        ' '.join(mapstr('DEF', name, ref, 0, text_offset, 'Y', 'Y', nbanks, 'L', 'N')),
        refcmd(ref),
        namecmd(name),
        'F2 "" 0 0 60 H I C CNN',
        'F3 "" 0 0 60 H I C CNN']+fplistcmd()+drawlist()+[
            'ENDDEF', '#', '#End Library']
    for l in lines: print(l)

writelib()
