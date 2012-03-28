#!/usr/bin/python

# Schema of database
# CREATE TABLE labstats(timestamp integer, hostname text, operatingsystem text, model text, totalmemory integer, totalcommittedmemory integer, totalcpu integer, usedmemory integer, committedmemory integer, pagefaultspersecond real, cpupercent real, cpuload real, numusers integer, userloggedin integer);


import os,sys, fileinput

try:
    import sqlite
except ImportError:
    import pysqlite2.dbapi2 as sqlite



con = sqlite.connect("labstats.db")
cur = con.cursor()
#insertstatment = """
#insert into labstats (timestamp, hostname, operatingsystem, model, totalmemory, totalcommittedmemory, totalcpu, usedmemory, committedmemory, pagefaultspersecond, cpupercent, cpuload, numusers, userloggedin) values (?, "?", "?", "?", ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
#"""
insertstatment = """
insert into labstats values (?,?,?,?,?,?,?,?,?,?,?,?,?,?);
"""
lines=0

for line in fileinput.input():
    try:
        fields = line.split('\t')
        timestamp = fields[2]
        hostname = fields[3]
        operatingsystem = fields[4]
        model = fields[5]
        totalmemory = fields[6]
        totalcommittedmemory = fields[7]
        totalcpu = fields[8]
        usedmemory = fields[9]
        committedmemory = fields[10]
        pagefaultspersec = float(fields[11])
        cpupercent = float(fields[12])
        cpuload = float(fields[13])
        numusers = int(fields[14])
        userloggedin = int(fields[15])
        #print "%s (%s) has %i (%i) users logged in\n" % (hostname, operatingsystem, numusers, userloggedin)
    except Exception, e:
        print "Error: %s" % e

    try:
        lines = lines + 1
        con.execute(insertstatment, (timestamp, hostname, operatingsystem, model, totalmemory, totalcommittedmemory, totalcpu, usedmemory, committedmemory, pagefaultspersec, cpupercent, cpuload, numusers, userloggedin))
        if (lines % 100 == 0):
            # only commit every 100 lines
            con.commit()
    except sqlite.Error, e:
        print "An SQLite error occurred: ", e
        print "timestamp: %s, hostname: %s, operatingsystem: %s, model: %s, totalmemory: %s, totalcommittedmemory: %s, totalcpu: %s, usedmemory: %s, committedmemory: %s, pagefaultspersec: %f, cpupercent: %f, cpuload: %f, numusers: %i, userloggedin: %i" % (timestamp, hostname, operatingsystem, model, totalmemory, totalcommittedmemory, totalcpu, usedmemory, committedmemory, pagefaultspersec, cpupercent, cpuload, numusers, userloggedin)
        sys.exit(1)
