import socket
from zeroconf import IPVersion, ServiceInfo, Zeroconf #type:ignore
# import time

#helper to get the actual local IP of the PC on the Wi-Fi network.
def get_local_ip():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        #don't actually connect, but this identifies the right interface
        s.connect(('10.254.254.254', 1))
        ip = s.getsockname()[0]
    except Exception:
        ip = '127.0.0.1'
    finally:
        s.close()
    return ip

#Starts broadcasting the PC Remote service over mDNS.
def start_mdns_broadcast(port: int):
    hostname = socket.gethostname()
    local_ip = get_local_ip()
    
    # Properties can include metadata like version or PC name , completely optional btw
    properties = {
        "version": "2.0.0",
        "pc_name": hostname
    }

    # Define the service: _pcremote._tcp.local.
    info = ServiceInfo(
        "_pcremote._tcp.local.",
        f"{hostname}._pcremote._tcp.local.",
        addresses=[socket.inet_aton(local_ip)],
        port=port,
        properties=properties,
        server=f"{hostname}.local.",
    )

    zc = Zeroconf(ip_version=IPVersion.V4Only)
    zc.register_service(info)
    
    # print(f"mDNS Broadcast started: {hostname}.local ({local_ip})")
    return zc, info


 #stops the broadcast
def stop_mdns_broadcast(zc: Zeroconf, info: ServiceInfo):
   
    if zc:
        zc.unregister_service(info)
        zc.close()
        # print("mDNS Broadcast stopped.")


# if __name__=="__main__":
#     start_mdns_broadcast(8080)
    
