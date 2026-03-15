"""Module to setup logging"""

import logging

from constants import LOGGER_NAME

# Get logger
logger = logging.getLogger(LOGGER_NAME)
logger.propagate = False
logger.setLevel(logging.DEBUG)

# Console handler
console_handler = logging.StreamHandler()
console_handler.setLevel(logging.DEBUG)
console_formatter = logging.Formatter(
    "[%(asctime)s] %(levelname)s: %(message)s", datefmt="%Y-%m-%dT%H:%M:%S%z"
)
console_handler.setFormatter(console_formatter)

# Add handler to logger
logger.addHandler(console_handler)
