"""Models module"""

from enum import Enum
from pathlib import Path

from pydantic import BaseModel, ConfigDict, computed_field

from constants import PROJECT_DIRPATH


class ListDirectoryRequest(BaseModel):
    """Request model for list_directory()"""

    model_config = ConfigDict(
        extra="ignore",
        validate_assignment=True,
        validate_default=True,
    )

    # Target path
    path: Path

    # Absolute target path
    @computed_field
    @property
    def full_path(self) -> Path:
        """Absolute path, no path traversal.

        Returns:
            Path: Absolute path.
        """
        # Resolve against root to neutralize any ../ or symlinks
        resolved = (PROJECT_DIRPATH / self.path).resolve()

        # Resolved path must be inside the project dir
        if not resolved.is_relative_to(PROJECT_DIRPATH):
            raise ValueError(
                f"Path traversal detected: '{self.path}' resolves outside project root"
            )

        return resolved


class FSObjectType(Enum):
    """Filesystem object type"""

    FILE: str = "FILE"
    DIR: str = "DIR"
    SYMLINK: str = "SYMLINK"
    UNKNOWN: str = "UNKNOWN"


class ListDirectoryResponseEntry(BaseModel):
    """Response model entry for list_directory()"""

    model_config = ConfigDict(
        extra="ignore",
        validate_assignment=True,
        validate_default=True,
    )

    # Filesystem object type
    type: FSObjectType

    # Name
    name: str


class ListDirectoryResponse(BaseModel):
    """Response model for list_directory()"""

    model_config = ConfigDict(
        extra="ignore",
        validate_assignment=True,
        validate_default=True,
    )

    # Project directory objects list
    objects: list[ListDirectoryResponseEntry]
