# TCP socket client example in Python
import socket

IP = '127.0.0.1'  # The server's hostname or IP address
PORT = 2000        # The port used by the server

def local(MESSAGE):
    data = bytes(MESSAGE, 'utf-8')

    print("TCP target IP: %s" % IP)
    print("TCP target port: %s" % PORT)
    print("Message: %s" % data)

    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.connect((IP, PORT))
        s.sendall(data)
        data = s.recv(1024)
    
    print('Received %s' %list(data))
    print()

while True:
    x = input("updates? ")
    local(x)