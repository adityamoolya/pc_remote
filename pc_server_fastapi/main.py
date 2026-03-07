import argparse
import uvicorn
import qrcode
from utils.secret_key_gen import rotate_key, get_or_create_key
import cv2
import numpy as np

def handle_serve_powershell(args):
    uvicorn.run("server:app", host="0.0.0.0", port=8080)
     #removed reload casue powershell function casues delay while shutting down watcher (StatReload)

def handle_serve_debug(args):
    uvicorn.run("server:app", host="0.0.0.0", port=8080 ,reload=True)


def handle_pair(args):
    key = get_or_create_key()
    print(f"PAIRING KEY: {key}")
    
    qr = qrcode.QRCode(
        box_size=10,
        border=4,
    )

    qr.add_data(key)
    qr.make(fit=True)

    img = qr.make_image(fill_color="black", back_color="white")

    # Convert PIL image → OpenCV format
    #alternatively tkinter can also be used but i already have cv2 in requirements.txt 
    img_np = np.array(img.convert("RGB"))
    img_np = cv2.cvtColor(img_np, cv2.COLOR_RGB2BGR)

    cv2.imshow("PyRemote Pairing QR", img_np)
    cv2.waitKey(0)  
    cv2.destroyAllWindows()


def handle_reset(args):
    rotate_key()
    print("Secret key rotated successfully.")
    handle_pair(None)

def main():
    parser = argparse.ArgumentParser(description="PyRemote CLI")

    subparsers = parser.add_subparsers(dest="command")

    # serve
    # serve_parser = subparsers.add_parser("serve", help="Start the server")
    # serve_parser.set_defaults(func=handle_serve)

    # pair
    pair_parser = subparsers.add_parser("pair", help="Show pairing info")
    pair_parser.set_defaults(func=handle_pair)

    # reset
    reset_parser = subparsers.add_parser("reset", help="Rotate secret key")
    reset_parser.set_defaults(func=handle_reset)
    
    # prod mode with hotreload
    reset_parser = subparsers.add_parser("debug", help="start server wit Hot Reload")
    reset_parser.set_defaults(func=handle_serve_debug)

    # Default behavior, debug mode without hotreload (for powershell fucntion)
    parser.set_defaults(func=handle_serve_powershell)

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()