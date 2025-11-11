"""Simple logger stub"""

import logging
logger = logging.getLogger('ift4001')

def setup():
    logging.basicConfig(level=logging.INFO)
    return logger
