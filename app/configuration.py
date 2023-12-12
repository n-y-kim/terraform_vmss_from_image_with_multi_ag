from configparser import SafeConfigParser
from logconfig import logger

config = SafeConfigParser()
#loading config file
config.read('config.ini')