#!/usr/bin/env python3

from craft_sploit import craft
from pwn import *

# SETTINGS

BINARY = ""

IP = "IP_ADDR"
PORT = None

LINK_LIBC = False
LIBC = ""
LD = ""
GDBSCRIPT = """
"""

LOG_LEVEL = "DEBUG"

r, elf, libc = craft(LINK_LIBC, BINARY, LIBC, LD, GDBSCRIPT, IP, PORT, LOG_LEVEL)

# SPLOIT #

r.interactive()