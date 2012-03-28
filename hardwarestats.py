#!/usr/bin/python

import os,sys
import numpy

f = open(sys.argv[1])

hwtotal = dict()
hwmemory = dict()
hwcpupercent = dict()
hwcpuload = dict()
highmemory = dict()
lowmemory = dict()

for line in f:
    values = line.split('\t')
    if ("-1" in values):
        continue
    os = values[4]
    hardware = values[5].rstrip()
    if (hardware == "Dell Inc. OptiPlex 980"):
        hardware = "OptiPlex 980"
    totalmemory = int(values[6])
    totalcommit = int(values[7])
    totalcpus = int(values[8])
    usedmem = int(values[9])
    committedmem = int(values[10])
    pagefaultspersecond = float(values[11])
    cpupercent = float(values[12])
    cpuload = float(values[13])

    if hardware not in hwtotal:
        hwtotal[hardware] = 0
        hwmemory[hardware] = numpy.array([])
        hwcpupercent[hardware] = numpy.array([])
        hwcpuload[hardware] = numpy.array([])
        highmemory[hardware] = usedmem
        lowmemory[hardware] = usedmem

    hwtotal[hardware] = hwtotal[hardware] + 1
    numpy.append(hwmemory[hardware], [usedmem])
    numpy.append(hwcpupercent[hardware],[cpupercent])
    numpy.append(hwcpuload[hardware],[cpuload])

    if (usedmem > highmemory[hardware]):
        highmemory[hardware] = usedmem
    if (usedmem < lowmemory[hardware]):
        lowmemory[hardware] = usedmem

f.close()


for hardware in sorted(hwtotal.keys()):
    print hardware
    print hwmemory[hardware]
    print "\tAverage memory used: %2.2f (%2.2f standard deviation)" % (numpy.average(hwmemory[hardware]), numpy.std(hwmemory[hardware]))
    print "\tAverage CPU Percent: %%%2.1f (%2.2f standard deviation)" % (numpy.average(hwcpupercent[hardware]), numpy.std(hwcpupercent[hardware]))
    print "\tAverage CPU Load: %2.2f (%2.2f standard deviation)" % (numpy.average(hwcpuload[hardware]), numpy.std(hwcpuload[hardware]))
    print "\tHighest memory in use: %i" % (highmemory[hardware])
    print "\tLowest memory in use: %i" % (lowmemory[hardware])
