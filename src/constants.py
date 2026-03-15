"""Constants module"""

from pathlib import Path

MCP_NAME: str = "ALAFS"
MCP_HOST: str = "0.0.0.0"
MCP_PORT: int = 5000

PROJECT_DIRNAME: str = "project"
PROJECT_DIRPATH: Path = Path(PROJECT_DIRNAME).resolve()

LOGGER_NAME: str = MCP_NAME
