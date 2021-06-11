import socket

# create TCP socket
sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

HOST = ''
PORT = 2001
SERVER = 2002

sock.bind((HOST, PORT))
print("Bound socket to ", HOST, ":", PORT)
s.connect((HOST,SERVER))

# listen
sock.listen()
print("Listening for connections")

def savebitmap(data):
    f = open('bitmap.bmp', 'wb')
    try:
        f.write(data)
    finally:
        f.close()
    s.send(data)
    

while True:
    # This returns an open connection once established
    connection, cli_addr = sock.accept()
    print("Connected to ", cli_addr)

    try:

        # Receive the data in small chunks and retransmit it
        while True:
            data = connection.recv(77880, socket.MSG_WAITALL)
            
            if len(data) == 0:
                break
            print('received data of size %d', len(data))
            savebitmap(data)

    finally:
            connection.close()