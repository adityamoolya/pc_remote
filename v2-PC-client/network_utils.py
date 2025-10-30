import struct
from datetime import datetime

# --- Helper Functions ---

def log_message(message):
    """Prints a message with a timestamp."""
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    print(f"[{timestamp}] {message}")

def send_message(conn, data_bytes):
    """Sends length-prefixed data to the client."""
    try:
        # Pack the length as a 4-byte, big-endian unsigned integer
        conn.sendall(struct.pack('>I', len(data_bytes)))
        # send the actual data
        conn.sendall(data_bytes)
    except Exception as e:
        log_message(f"Error sending message: {e}")

def send_text(conn, message_str):
    """Encodes a string and sends it as a length-prefixed message."""
    send_message(conn, message_str.encode('utf-8'))