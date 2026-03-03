import time
from zeroconf import Zeroconf, ServiceBrowser

class MyListener:
    def remove_service(self, zeroconf, type, name):
        print(f"Service {name} removed")

    def add_service(self, zeroconf, type, name):
        info = zeroconf.get_service_info(type, name)
        print(f"Service {name} added, service info: {info}")

    def update_service(self, zeroconf, type, name):
        pass

zeroconf = Zeroconf()
listener = MyListener()
browser = ServiceBrowser(zeroconf, "_pcremote._tcp.local.", listener)
print("Browsing for _pcremote._tcp.local. services...")
try:
    time.sleep(5)
finally:
    zeroconf.close()
