import sys
import socket
import numpy
import struct
from matplotlib import pylab as pt
from PIL import Image

# create TCP socket
sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

HOST = ''
PORT = 2000

sock.bind((HOST, PORT))
print("Bound socket to ", HOST, ":", PORT)


# listen
sock.listen()
print("Listening for connections")

def readintoarray(data):
  imgarray = numpy.empty(76800, dtype=numpy.uint8)
  once = False
  idx=0
  for b in struct.iter_unpack('3B', data):
    
    r0 = numpy.uint8( (b[0] & 0xf0))
    if not once:
      print(b) 
      print(r0)
      once = True
    g0 = numpy.uint8((b[0] & 0x0f) << 4)
    b0 = numpy.uint8( (b[1] & 0xf0) )
    r1 = numpy.uint8( (b[1] & 0x0f) << 4)
    g1 = numpy.uint8( (b[2] & 0xf0) )
    b1 = numpy.uint8( (b[2] & 0x0f) << 4)
    imgarray[idx] = r0
    idx += 1
    imgarray[idx] = g0
    idx += 1
    imgarray[idx] = b0
    idx += 1
    imgarray[idx] = r1
    idx += 1
    imgarray[idx] = g1
    idx += 1
    imgarray[idx] = b1
    idx += 1

    
  print(imgarray[0])
  print(numpy.shape(imgarray))
  img3darr = numpy.reshape(imgarray, (40, 640 , 3))
  print(img3darr[1,2,2])
  pt.imshow(img3darr, interpolation='nearest')
  pt.show()
  # img = Image.fromarray(img3darr, 'RGB')
  # img.show()


while True:
  # This returns an open connection once established
  connection, cli_addr = sock.accept()
  print("Connected to ", cli_addr)

  try:

    # Receive the data in small chunks and retransmit it
    while True:
        data = connection.recv(38400, socket.MSG_WAITALL)
        
        print('received data of size %d', len(data))
        readintoarray(data)

        num = input("Enter data to send to client")

        if num != 'q':
          data_to_send = bytes(num, 'utf-8')
          connection.sendall(data_to_send)
        
        else:
          print("Closing connection")

  finally:
      # Clean up the connection
      connection.close()



