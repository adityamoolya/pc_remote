# import secrets
from fastapi import Security, HTTPException, status, Depends
from fastapi.security.api_key import APIKeyHeader
from .secret_key_gen import get_or_create_key

#the name of the header the mobile app must send
API_KEY_NAME = "PLEASE_LET_ME_IN"
api_key_header = APIKeyHeader(name=API_KEY_NAME, auto_error=False)

CURRENT_SECRET_KEY = get_or_create_key()


async def validate_api_key(api_key: str = Security(api_key_header)):
    """
    dependency that checks if the 'PLEASE_LET_ME_IN' header matches our SECRET_KEY.
    """
    print(f"[AUTH DEBUG] Received: '{api_key}' | Expected: '{CURRENT_SECRET_KEY}'")
    
    if api_key == CURRENT_SECRET_KEY:
        return api_key
    
    raise HTTPException(
        status_code=status.HTTP_403_FORBIDDEN,
        detail="Invalid API Key. Please authenticate first."
    )