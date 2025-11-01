import functools
import os
import file_utils 
import ctypes
from network_utils import send_text, send_message, log_message
import traceback 
import subprocess

from comtypes import CLSCTX_ALL
from pycaw.pycaw import AudioUtilities, IAudioEndpointVolume

# --- (Decorator and File/Drive handlers are unchanged) ---
def send_ok_on_success(func):
    """
    Decorator that sends 'OK' on successful execution
    or 'ERROR: <msg>' on failure.
    """ 
    @functools.wraps(func)
    def wrapper(conn, *args, **kwargs):
        try:
            func() 
            send_text(conn, "OK") 
            log_message(f"Successfully executed {func.__name__} and sent OK.")
        except Exception as e:
            log_message(f"ERROR executing {func.__name__}: {e}")
            traceback.print_exc() 
            send_text(conn, f"ERROR: {e}")
            
    return wrapper

def handle_drives(conn, command_parts):
    success, response_str = file_utils.get_drives()
    if success:
        log_message(f" Found drives: {response_str.splitlines()}")
        send_text(conn, response_str)
    else:
        log_message(f"Error getting drives: {response_str}")
        send_text(conn, f"ERROR: {response_str}")

def handle_list_files(conn, command_parts):
    if len(command_parts) < 2: path = '.'
    else: path = command_parts[1].replace("/", "\\")
    success, response_str = file_utils.list_directory(path)
    if success: send_text(conn, response_str)
    else: send_text(conn, f"ERROR: {response_str}")

def handle_download_file(conn, command_parts):
    if len(command_parts) < 2:
        send_text(conn, "ERROR: No file path specified.")
        return
    path = command_parts[1].replace("/", "\\")
    safe_path = os.path.abspath(path)
    if ".." in path or not os.path.isfile(safe_path):
        log_message(f"File Access Denied: {path}")
        send_text(conn, "ERROR: Access Denied or file not found.")
        return
    try:
        with open(safe_path, 'rb') as f: file_bytes = f.read()
        log_message(f"Sending {len(file_bytes)} bytes for file: {safe_path}")
        send_message(conn, file_bytes) 
    except Exception as e:
        log_message(f" Error reading file {safe_path}: {e}")
        send_text(conn, f"ERROR: Could not read file: {e}")

def handle_unknown_command(conn, cmd_str):
    log_message(f"Received unknown command: {cmd_str}")
    send_text(conn, f"ERROR: Unknown command '{cmd_str}'")


# --- MODIFIED: set_volume_live ---
def set_volume_live(conn, command_parts):
    """
    Sets the master volume to a level from 0 to 100.
    Does NOT send a reply, for fast, live updates.
    """
    try:
        if len(command_parts) < 2: return # Ignore if no value
        
        volume_level = int(command_parts[1])
        volume_scalar = max(0.0, min(1.0, volume_level / 100.0))
        
        speakers = AudioUtilities.GetSpeakers()
        volume = speakers.EndpointVolume
        
        volume.SetMasterVolumeLevelScalar(volume_scalar, None)
    except Exception as e:
        log_message(f"Error setting volume: {e}")


def get_current_volume(conn, command_parts):
    """
    Gets the current master volume and sends it back to the client.
    Sends reply like: "VOLUME_IS 72"
    """
    try:
        speakers = AudioUtilities.GetSpeakers()
        volume = speakers.EndpointVolume

        current_scalar = volume.GetMasterVolumeLevelScalar()
        current_percent = int(current_scalar * 100)
        
        reply = f"VOLUME_IS {current_percent}"
        send_text(conn, reply)
        log_message(f"Sent current volume: {current_percent}%")
        
    except Exception as e:
        log_message(f"Error getting volume: {e}")
        send_text(conn, f"ERROR: {e}")



@send_ok_on_success
def toggle_mute():
    log_message("Executing MUTE")
    speakers = AudioUtilities.GetSpeakers()
    volume = speakers.EndpointVolume

    is_muted = volume.GetMute()
    volume.SetMute(not is_muted, None)


@send_ok_on_success
def lock_pc():
    ctypes.windll.user32.LockWorkStation()


@send_ok_on_success
def sleep_pc():
    # Put the system to sleep
    subprocess.run("rundll32.exe powrprof.dll,SetSuspendState 0,1,0", shell=True)


@send_ok_on_success
def shutdown_pc():
    # Shutdown immediately
    os.system("shutdown /s /t 0")


@send_ok_on_success
def restart_pc():
    # Restart immediately
    os.system("shutdown /r /t 0")


@send_ok_on_success
def playPause_media():
    # Send Play/Pause media key
    subprocess.run('powershell -command "$wshell = New-Object -ComObject wscript.shell; $wshell.SendKeys(\'{MEDIA_PLAY_PAUSE}\')"', shell=True)


@send_ok_on_success
def next_media():
    # Send Next Track key
    subprocess.run('powershell -command "$wshell = New-Object -ComObject wscript.shell; $wshell.SendKeys(\'{MEDIA_NEXT_TRACK}\')"', shell=True)


@send_ok_on_success
def previous_media():
    # Send Previous Track key
    subprocess.run('powershell -command "$wshell = New-Object -ComObject wscript.shell; $wshell.SendKeys(\'{MEDIA_PREV_TRACK}\')"', shell=True)


@send_ok_on_success
def taskmanager_os():
    # Open Task Manager
    subprocess.Popen("taskmgr.exe", shell=True)


@send_ok_on_success
def settings_os():
    # Open Windows Settings
    subprocess.Popen("start ms-settings:", shell=True)
   
COMMAND_HANDLERS = {
    'DRIVES': handle_drives,
    'LIST_FILES': handle_list_files,
    'DOWNLOAD_FILE': handle_download_file,
    'SET_VOLUME_LIVE': set_volume_live,
    'GET_VOLUME': get_current_volume,
    'LOCK': lambda conn, parts: lock_pc(conn),
    'SLEEP': lambda conn, parts: sleep_pc(conn),
    'SHUTDOWN': lambda conn, parts: shutdown_pc(conn),
    'RESTART': lambda conn, parts: restart_pc(conn),
    'MUTE': lambda conn, parts: toggle_mute(conn),
    'PLAY_PAUSE': lambda conn, parts: playPause_media(conn),
    'NEXT': lambda conn, parts: next_media(conn),
    'PREVIOUS': lambda conn, parts: previous_media(conn),
    'TASK_MANAGER': lambda conn, parts: taskmanager_os(conn),
    'SETTINGS': lambda conn, parts: settings_os(conn),
}
