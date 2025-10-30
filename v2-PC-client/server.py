import socket
import threading
# import os
import qrcode
import random, string
import commands
from network_utils import log_message


HOST = '0.0.0.0'
PORT = 8080
SECRET_KEY = ""

#handles a single client, requiring authentication first via secret key
def client_handler(conn, addr):
    client_ip = addr[0]
    log_message(f"New connection attempt from {client_ip}") 
    
    
    try:
        auth_data = conn.recv(1024).decode('utf-8').strip().split(' ', 1) 
        
        if len(auth_data) != 2 or auth_data[0].upper() != 'AUTH' or auth_data[1] != SECRET_KEY:
            log_message(f"Authentication failed for {client_ip}. Disconnecting.")
            conn.sendall(b'AUTH_FAIL\n') # Keep this simple send
            conn.close()
            return

        log_message(f"Authentication successful for {client_ip}.")
        conn.sendall(b'AUTH_OK\n') # so the client knows connection is authenticated

        #checks the command sent by client and processes it using commands.py
        while True:
            data = conn.recv(1024)
            if not data:
                break
            
            command_parts = data.decode('utf-8').strip().split(' ', 1)
            if not command_parts or command_parts[0] == '':
                continue # skip empty commands
                
            cmd_str = command_parts[0].upper()
            
            # gets the correct function from the imported dictionary
            handler_func = commands.COMMAND_HANDLERS.get(cmd_str)
            
            if handler_func:
                # calls the function we found in commands.py
                handler_func(conn, command_parts)
            else:
                # if it didn't find the command, calls the unknown handler
                commands.handle_unknown_command(conn, cmd_str)
       

    except Exception as e:
        log_message(f"💥 An error occurred with client {client_ip}: {e}")
    finally:
        log_message(f"🔌 Connection with {client_ip} closed.")
        conn.close()



def get_local_ip():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(('8.8.8.8', 80))
        ip = s.getsockname()[0]
    except Exception:
        ip = '127.0.0.1'
    finally:
        s.close()
    return ip

def generate_secret_key(length=6):
    return ''.join(random.choices(string.ascii_uppercase + string.digits, k=length))


# creates a QR with tcp url and secret key ,then listens in the given port until client sends AUTH 
if __name__ == "__main__":
    SECRET_KEY = generate_secret_key()
    local_ip = get_local_ip()
    server_url_with_key = f"tcp://{local_ip}:{PORT}|{SECRET_KEY}"

    print("="*50) 
    print("Server Started")
    print(f"Secret key: {SECRET_KEY}")
    print("Scan the QR code with the app to connect")
    print("="*50)

    qr = qrcode.QRCode()
    qr.add_data(server_url_with_key)
    qr.print_tty()
    
    print(f"\nConnect URL: {server_url_with_key}")
    print("\nListening for connections... (Press Ctrl+C to stop)")

    server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    try:
        server_socket.bind((HOST, PORT))
        server_socket.listen()
        
        server_socket.settimeout(1.0) 

        while True:
            try:
                conn, addr = server_socket.accept()
                thread = threading.Thread(target=client_handler, args=(conn, addr))
                thread.daemon = True
                thread.start()
                
            except socket.timeout:
                continue 
                
    except KeyboardInterrupt: #used to shut down the server instead of killin it in taskmanger
        log_message("\n🚫 Server is shutting down.")
    finally:
        server_socket.close()
        log_message("Server socket closed. Exiting.")