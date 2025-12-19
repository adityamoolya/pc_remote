import os
import secrets
import string
from dotenv import load_dotenv, set_key


ENV_PATH = ".env"

#generates a fresh secret api key
def generate_random_key(length=8):
    alphabet = string.ascii_uppercase + string.digits
    return ''.join(secrets.choice(alphabet) for _ in range(length))


# Loads the existing key from .env. If it doesn't exist, creates a new one and saves it.
def get_or_create_key():
    
    load_dotenv(ENV_PATH)
    key = os.getenv("PC_REMOTE_SECRET_KEY")
    
    if not key:
        # No key found, generate the first one
        key = generate_random_key()
        set_key(ENV_PATH, "PC_REMOTE_SECRET_KEY", key)
        print(f"✨ New Secret Key generated and saved: {key}")
    
    return key


# Forces the generation of a new key and overwrites the .env file.
def rotate_key():
    new_key = generate_random_key()
    set_key(ENV_PATH, "PC_REMOTE_SECRET_KEY", new_key)
    print(f" Secret Key rotated! New key: {new_key}")
    return new_key

# If run directly, it will rotate the key
if __name__ == "__main__":
    rotate_key()