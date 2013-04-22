#!/usr/bin/env python

import socket, time, sys

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect(('192.168.0.7', 8080))
s.sendall('GET /tiles/riverst/8/42/99.json HTTP/1.0\r\n\r\n')
l = 0
while True:
    time.sleep(0)
    d = s.recv(1024)
    l += len(d)
    if len(d) == 0:
        break
    sys.stdout.write("%s" % "*" if len(d) == 1024 else ".")

s.close()
print '\nReceived', l, "bytes"
