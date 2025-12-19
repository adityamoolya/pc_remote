# file_utils.py

import os
import string

# REMOVED: No longer need ROOT_DIR

# file_utils.py

def get_drives():
    drives = []
    for letter in string.ascii_uppercase:
        drive_path = f"{letter}:\\"
        if os.path.exists(drive_path):
            # This line should NOT have f"D:" at the beginning
            drives.append(drive_path) 
    return (True, "\n".join(drives))

def list_directory(path):
    """Lists contents of any valid directory path."""
    try:
        # The path is now used directly without being joined to a root dir.
        absolute_path = os.path.abspath(path)

        if not os.path.isdir(absolute_path):
            return (False, "Error: Path is not a directory or does not exist")

        items = os.listdir(absolute_path)
        response_items = []
        for item in sorted(items):
            item_path = os.path.join(absolute_path, item)
            item_type = "D" if os.path.isdir(item_path) else "F"
            response_items.append(f"{item_type}:{item}")
        
        return (True, "\n".join(response_items))

    except Exception as e:
        return (False, f"Error: {e}")