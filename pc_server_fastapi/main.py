import argparse
import qrcode
import uvicorn
import logging
import subprocess
import re
import atexit
from utils.secret_key_gen import rotate_key, get_or_create_key
import server

logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")
logger = logging.getLogger(__name__)


def handle_pair(reset: bool = False):
    if reset:
        rotate_key()
        logger.info("SECRET KEY ROTATED")
    key = get_or_create_key()
    logger.info(f"PAIRING KEY: {key}")
    qrcode.make(key).show()


def _start_local(debug: bool):
    server.app = server.create_app(mdns=True)
    uvicorn.run("server:app", host="0.0.0.0", port=8080, reload=debug)


def _start_broadcast(debug: bool):
    server.app = server.create_app(mdns=False)

    uvicorn_cmd = ["uvicorn", "server:app", "--host", "0.0.0.0", "--port", "8080"]
    if debug:
        uvicorn_cmd.append("--reload")

    uvicorn_process = subprocess.Popen(uvicorn_cmd)
    atexit.register(uvicorn_process.terminate)

    cloudflared_process = subprocess.Popen(
        ["cloudflared", "tunnel", "--url", "http://localhost:8080"],
        stderr=subprocess.PIPE
    )
    atexit.register(cloudflared_process.terminate)

    for line in cloudflared_process.stderr:
        match = re.search(r"https://[\w-]+\.trycloudflare\.com", line.decode())
        if match:
            url = match.group(0)
            logger.info(f"PUBLIC URL: {url}")
            qrcode.make(url).show()
            break

    cloudflared_process.wait()


def main():
    parser = argparse.ArgumentParser(description="PyRemote CLI")
    parser.add_argument("mode", choices=["broadcast", "local"], help="broadcast: Cloudflare tunnel, local: local network")
    parser.add_argument("--pair",  action="store_true", help="Show pairing QR before starting server")
    parser.add_argument("--debug", action="store_true", help="Start server with hot reload")
    parser.add_argument("--reset", action="store_true", help="Rotate secret key and exit")

    args = parser.parse_args()

    if args.reset:
        rotate_key()
        logger.info("SECRET KEY ROTATED")
        return

    if args.pair:
        handle_pair()

    if args.mode == "broadcast":
        logger.info("STARTING SERVER ON CLOUDFLARE TUNNEL")
        _start_broadcast(args.debug)
    else:
        logger.info("STARTING SERVER ON LOCAL NETWORK")
        _start_local(args.debug)


if __name__ == "__main__":
    main()