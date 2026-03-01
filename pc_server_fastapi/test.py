import cv2
import socket
import numpy as np

UDP_IP = "0.0.0.0"
UDP_PORT = 9999
MAX_DGRAM = 65507 

def run_test_client():
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.bind((UDP_IP, UDP_PORT))
    # Set a 1-second timeout so the script doesn't freeze
    sock.settimeout(1.0)
    
    print(f"--- Receiver Active on Port {UDP_PORT} ---")
    print("Waiting for data... (Trigger the stream in Swagger UI now)")
    print("Press 'q' to quit or use Ctrl+C")

    try:
        while True:
            try:
                # Receive packet
                packet, addr = sock.recvfrom(MAX_DGRAM)
                
                # If we get here, we received data!
                nparr = np.frombuffer(packet, np.uint8)
                frame = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
                
                if frame is not None:
                    cv2.imshow("Stream Test", frame)
                
            except socket.timeout:
                # This prevents the script from freezing if no data arrives
                continue
            
            if cv2.waitKey(1) & 0xFF == ord('q'):
                break
    except KeyboardInterrupt:
        print("\nStopping script...")
    finally:
        sock.close()
        cv2.destroyAllWindows()

if __name__ == "__main__":
    run_test_client()