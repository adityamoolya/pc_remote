# TEST_server.py (Updated to be a full client)

import socket
import struct
import os # For handling file paths

def send_command_and_get_response(sock, command_str):
    """
    Sends a command, gets the response, and smartly handles
    text vs. file data.
    """
    print(f"\nSending command: '{command_str}'")
    sock.sendall(command_str.encode('utf-8'))

    # Receive the 4-byte header for the message size
    header = sock.recv(4)
    if not header:
        print("Server closed connection unexpectedly.")
        return None
    
    # Unpack the header to get the message size
    try:
        message_size = struct.unpack('>I', header)[0]
    except struct.error:
        print(f"Error: Received invalid header. Server might have sent text (like AUTH_FAIL) instead.")
        print(f"Raw data: {header}")
        return None
        
    print(f"Server is sending {message_size} bytes...")

    # Receive the full payload
    response_data = b''
    while len(response_data) < message_size:
        chunk = sock.recv(message_size - len(response_data))
        if not chunk:
            break
        response_data += chunk
    
    # --- Smart response handling ---
    command_parts = command_str.strip().split(' ', 1)
    cmd_type = command_parts[0].upper()

    if cmd_type == 'DOWNLOAD_FILE' and len(command_parts) > 1:
        # This is a file, save it
        try:
            filename = os.path.basename(command_parts[1]) # Get "file.txt" from "C:\path\to\file.txt"
            if not filename: filename = "downloaded_file" # Failsafe
            
            with open(filename, 'wb') as f:
                f.write(response_data)
            print(f"--- File Saved: {filename} ({message_size} bytes) ---")
        except Exception as e:
            print(f"Error saving file: {e}")
    else:
        # This is text, decode and print it
        try:
            response_str = response_data.decode('utf-8')
            print(f"--- Server Response for '{command_str}' ---")
            print(response_str)
            print("-" * (len(command_str) + 24))
        except UnicodeDecodeError:
            print("--- Received binary data but did not expect it ---")

# --- The main script logic starts here ---
try:
    # --- NEW: Parse the full connection string ---
    connect_string = input("Paste the full connection URL from the server (e.g., tcp://...): ")
    
    # Parse the string
    # 1. Remove "tcp://"
    cleaned_string = connect_string.replace("tcp://", "")
    
    # 2. Split into address and key
    parts = cleaned_string.split('|')
    if len(parts) != 2:
        print("Error: Invalid format. Expected 'ip:port|key'")
        exit()

    address = parts[0]
    secret_key = parts[1]

    # 3. Split address into host and port
    address_parts = address.split(':')
    if len(address_parts) != 2:
        print("Error: Invalid address format. Expected 'ip:port'")
        exit()
        
    host = address_parts[0]
    port = int(address_parts[1])
    
    print(f"Parsed - Host: {host}, Port: {port}, Key: {secret_key}")
    # --- END NEW ---

    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        print(f"\nAttempting to connect to {host}:{port}...")
        s.connect((host, port))
        print("✅ Connection successful.")

        # 1. Send authentication
        auth_command = f"AUTH {secret_key}\n" # Added \n for robustness
        print(f"Sending authentication...")
        s.sendall(auth_command.encode('utf-8'))
        
        # 2. Wait for auth response
        auth_response = s.recv(1024).decode('utf-8').strip()
        print(f"Server says: {auth_response}")

        # 3. Only proceed if auth is OK
        if auth_response == 'AUTH_OK':
            print("\nType your full command and press Enter.")
            print("Examples:")
            print("  DRIVES")
            print("  LIST_FILES C:\\")
            print("  DOWNLOAD_FILE C:\\Users\\YourName\\Desktop\\test.txt")
            print("  exit")
            
            while True:
                # --- General command loop ---
                command_to_send = input("\nCommand: ")
                if command_to_send.lower() == 'exit':
                    break
                if not command_to_send:
                    continue
                
                send_command_and_get_response(s, command_to_send)
                # --- END ---
        else:
            print("❌ Authentication failed. Disconnecting.")

except ConnectionRefusedError:
    print("❌ Connection failed. Is the server.py script running?")
except (ValueError, IndexError):
    print("❌ Error: Could not parse the connection string. Make sure it's in the exact format.")
except Exception as e:
    print(f"An error occurred: {e}")

print("\nConnection closed.")

