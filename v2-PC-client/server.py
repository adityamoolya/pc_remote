import socket
import threading
import qrcode
import random, string
import commands
from network_utils import log_message
import comtypes
import traceback 
import argparse

HOST = '0.0.0.0'
PORT = 8080
SECRET_KEY = ""




#handles a single client, requiring authentication first via secret key
def client_handler(conn, addr):
    client_ip = addr[0]
    log_message(f"New connection attempt from {client_ip}") 
    
    comtypes.CoInitialize() # Initialize COM for this thread
    
    try:
        #authentication 
        auth_data = conn.recv(1024).decode('utf-8').strip().split(' ', 1) 
        
        if len(auth_data) != 2 or auth_data[0].upper() != 'AUTH' or auth_data[1] != SECRET_KEY:
            log_message(f"Authentication failed for {client_ip}. Disconnecting.")
            conn.sendall(b'AUTH_FAIL\n') 
            conn.close()
            return

        log_message(f"Authentication successful for {client_ip}.")
        conn.sendall(b'AUTH_OK\n') # so the client knows connection is authenticated

        
        buffer = ""
        while True:
            data = conn.recv(1024)
            if not data:
                break # client disconnected
            
            buffer += data.decode('utf-8')
            
            # processess all complete commands in the buffer
            while '\n' in buffer:
                # Split at the first newline found
                command, buffer = buffer.split('\n', 1)
                command = command.strip()
                
                if not command:
                    continue # Skip empty lines
                
                log_message(f"Processing command: {command}")
                command_parts = command.split(' ', 1)
                cmd_str = command_parts[0].upper()
                
                handler_func = commands.COMMAND_HANDLERS.get(cmd_str)
                
                if handler_func:
                    handler_func(conn, command_parts)
                else:
                    commands.handle_unknown_command(conn, cmd_str)
       
    except ConnectionResetError:
        log_message(f"Client {client_ip} forcefully disconnected.")
    except Exception as e:
        log_message(f"💥 An error occurred with client {client_ip}: {e}")
        traceback.print_exc()
    finally:
        log_message(f"🔌 Connection with {client_ip} closed.")
        comtypes.CoUninitialize() # Uninitialize COM for this thread
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

def pair():
    SECRET_KEY = generate_secret_key()
    local_ip = get_local_ip()
    # MODIFIED: Use ws:// (WebSocket) as the protocol for clarity, though tcp:// works
    server_url_with_key = f"ws://{local_ip}:{PORT}|{SECRET_KEY}"

    print("="*50) 
    print("Server Started")
    print(f"Secret key: {SECRET_KEY}")
    print("Scan the QR code with the app to connect")
    print("="*50)

    qr = qrcode.QRCode()
    qr.add_data(server_url_with_key)
    qr.print_tty()
    
    print(f"\nConnect URL: {server_url_with_key}")



# parser = argparse.ArgumentParser(description="A simple test script.")

# parser.add_argument(
#     '--pair', 
#     action='store_true', 
#     help="Run in pairing mode."
# )

# parser.add_argument(
#     '--name', 
#     help="Provide a name."
# )
# args = parser.parse_args()
# if args.pair:
#     print("Pairing mode is ON.")
#     pair()

# elif args.name:
#     print(f"hello, {args.name}!")
    
# else:
#     print("...Running in normal mode...")

# creates a QR with tcp url and secret key ,then listens in the given port until client sends AUTH 
if __name__ == "__main__":
    pair()
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
        log_message("\n🚫Server is shutting down.")
    finally:
        server_socket.close()
        log_message("Server socket closed. Exiting.")
