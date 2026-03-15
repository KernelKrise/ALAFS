"""Helpers module"""

import os
import stat

from models import FSObjectType


def list_dir(target_dir: str) -> list[str]:
    """List directory.

    Args:
        target_dir (str): Directory to list objects in.

    Returns:
        list[str]: List of objects inside target directory.
    """
    entries = []
    for name in os.listdir(target_dir):
        full_path = os.path.join(target_dir, name)
        mode = os.lstat(full_path).st_mode

        if stat.S_ISDIR(mode):
            entry_type = FSObjectType.DIR
        elif stat.S_ISREG(mode):
            entry_type = FSObjectType.FILE
        elif stat.S_ISLNK(mode):
            entry_type = FSObjectType.SYMLINK
        else:
            entry_type = FSObjectType.UNKNOWN

        entries.append({"type": entry_type, "name": name})
    return entries
