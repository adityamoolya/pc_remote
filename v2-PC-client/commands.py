import os
import file_utils 
import ctypes
from network_utils import send_text, send_message, log_message

# Command Handler Functions ,define a function you need and map it in dictonary at the end

def handle_drives(conn, command_parts):
    """Handles the DRIVES command."""
    success, response_str = file_utils.get_drives()
    if success:
        log_message(f" Found drives: {response_str.splitlines()}")
        log_message("Sending drive list...")
        send_text(conn, response_str)
    else:
        log_message(f"Error getting drives: {response_str}")
        send_text(conn, f"ERROR: {response_str}")

def handle_list_files(conn, command_parts):
    """Handles the LIST_FILES command."""
    if len(command_parts) < 2:
        path = '.' # default to current directory if no path is passed
    else:
        path = command_parts[1]
        
    success, response_str = file_utils.list_directory(path)
    if success:
        send_text(conn, response_str)
    else:
        send_text(conn, f"ERROR: {response_str}")

def handle_download_file(conn, command_parts):
    """Handles the DOWNLOAD_FILE command."""
    if len(command_parts) < 2:
        send_text(conn, "ERROR: No file path specified.")
        return
    
    path = command_parts[1]
    log_message(f"Attempting to send file: {path}")

    # checks if the path even exists
    safe_path = os.path.abspath(path)
    if ".." in path:
        log_message(f"File Access Denied (Path Traversal): {path}")
        send_text(conn, "ERROR: Access Denied.")
    elif not os.path.isfile(safe_path):
        log_message(f"File Access Denied (Not a file or not found): {safe_path}")
        send_text(conn, "ERROR: Not a file or does not exist.")
    else:
        
        try:
            with open(safe_path, 'rb') as f:
                file_bytes = f.read()
            log_message(f"Sending {len(file_bytes)} bytes for file: {safe_path}")
            send_message(conn, file_bytes) 
        except Exception as e:
            log_message(f" Error reading file {safe_path}: {e}")
            send_text(conn, f"ERROR: Could not read file: {e}")

# handles any command not in dictionary
def handle_unknown_command(conn, cmd_str):
    log_message(f"Received unknown command: {cmd_str}")
    send_text(conn, f"ERRORr: Unknown command '{cmd_str}'")

def lock_pc(conn, cmd_str):
    ctypes.windll.user32.LockWorkStation()
    send_text(conn,cmd_str)


# this mapss command strings to their handler functions
COMMAND_HANDLERS = {
    'DRIVES': handle_drives,
    'LIST_FILES': handle_list_files,
    'DOWNLOAD_FILE': handle_download_file,
    'LOCK':lock_pc
}