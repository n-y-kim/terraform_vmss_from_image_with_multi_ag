# logging_example.py

import logging

# Create a custom logger
logger = logging.getLogger(__name__)
logger.setLevel(logging.WARNING)

# Create handlers
c_handler = logging.StreamHandler()
f_handler = logging.FileHandler('vmss_lifcycle_hook.log')
c_handler.setLevel(logging.WARNING)
f_handler.setLevel(logging.WARNING)

# Create formatters and add it to handlers
c_format = logging.Formatter('%(name)s - %(levelname)s - %(message)s')
f_format = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
c_handler.setFormatter(c_format)
f_handler.setFormatter(f_format)

# Add handlers to the logger
logger.addHandler(c_handler)
logger.addHandler(f_handler)