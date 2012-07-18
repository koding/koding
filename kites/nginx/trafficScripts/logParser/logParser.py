#!/usr/bin/env python
"""
adjust this script if yiy have not opportunity to configure log format in your web-server
"""

import sys
import socket

# web-server log record example
#["egych.kodingen.com"] 82.145.208.212 - - [06/Dec/2011:08:55:40 -0500] "GET /poll.swf HTTP/1.1" 200 61283 "http://www.mmm-tasty.ru/main/last" "Opera/9.80 (J2ME/MIDP; Opera Mini/4.2.21260/26.1235; U; ru) Presto/2.8.119 Version/10.54"

def parse(log_record):

    line = log_record.rstrip().split()
    vhostname = line[0]
    date      = line[4].replace('[','')
    request   = line[7].split('?')[0]
    out       = line[10]
    try:
        socket.inet_aton(vhostname)
        return False # if vhost is IP (nonexestent in lsws ). return False
    except socket.error:
        if out is not "-":
            return('{"vhostname":"%s","date":"%s","request":"%s","out":"%s","iscounted":"false"}\n' %
                   (vhostname.split('"')[1],date,request,out))



def main():
    sys.exit(0)



if __name__ == '__main__':
    main()
