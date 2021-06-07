# TCP socket client example in Python
import socket

IP = '127.0.0.1'  # The server's hostname or IP address
PORT = 2001        # The port used by the server

with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
    def local():
        f = open("public/bitmap.bmp","rb")
        data = f.read()

        print("TCP target IP: %s" % IP)
        print("TCP target port: %s" % PORT)
        print("Message: %s" % data)

        s.send(data)
        data = s.recv(1024)
        
        print('Received %s' %list(data))
        print()

    s.connect((IP, PORT))

    while True:
        x = input("updates? ")
        if x=="end" or x=="exit":
            s.close()
            break
        local()
    

    

