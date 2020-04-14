from pwn import *
import os
import argparse
import shutil
import tempfile

parser = argparse.ArgumentParser()
parser.add_argument("-d", help="Run exploit locally and attach debugger", action="store_true")
parser.add_argument("-r", help="Run exploit on remote service", action="store_true")
parser.add_argument("-e", help="Run binary", action="store_true")
args = parser.parse_args()


def _gdbserver_args(args, env=None):
    gdbserver = ''
    gdbserver = which('gdbserver')
    gdbserver_args = [gdbserver, '--multi', '--no-disable-randomization']
    if env:
        env_args = []
        for key in tuple(env):
            if key.startswith('LD_'):
                env_args.append('{}={}'.format(key, env.pop(key)))
        if env_args:
            gdbserver_args += ['--wrapper', 'env'] + env_args + ['--']
    gdbserver_args += ['localhost:0']
    gdbserver_args += args
    return gdbserver_args

def _gdbserver_port(gdbserver, ssh):
    process_created = gdbserver.recvline()
    gdbserver.pid = int(process_created.split()[-1], 0)
    listening_on = b''
    while b'Listening' not in listening_on:
        listening_on = gdbserver.recvline()
    port = int(listening_on.split()[-1])
    return port

def attach(target, gdbscript, exe):
    gdbscript = f"gef-remote :{target}\n{gdbscript}\n"
    tmp = tempfile.NamedTemporaryFile(prefix='pwn', suffix='.gdb',
                                      delete=False, mode='w+')
    gdbscript = f"shell rm {tmp.name}\n{gdbscript}"
    tmp.write(gdbscript)
    tmp.close()
    cmd = f'{which("gdb")} -x "{tmp.name}"'
    gdb_pid = run_in_new_terminal(cmd)

def debug(args, gdbscript, env=None):
    args = _gdbserver_args(args, env=env)
    exe = which(args[0])
    gdbserver = process(args, env=env, aslr=1)
    gdbserver.executable = exe
    port = _gdbserver_port(gdbserver, ssh)
    host = '127.0.0.1'
    attach(port, gdbscript, exe)
    gdbserver.recvline(timeout=1)
    gdbserver.recvline_startswith(b"Remote debugging from host ", timeout=1)
    return gdbserver

def craft(link_libc, binary, libc, ld, gdbscript, ip, port, log_level) -> (process, ELF, ELF):
    context.binary = binary
    context.terminal = ['tmux', 'splitw', '-h']
    context.log_level = log_level

    libc_dir = os.path.dirname(libc)

    if link_libc:
        if not os.path.exists(f"{binary}__linked"):
            shutil.copy2(binary, f"{binary}__linked")
            os.system(f"patchelf --set-interpreter {ld} {binary}__linked")
            os.system(f"patchelf --set-rpath {libc_dir} {binary}__linked")
        binary = f"{binary}__linked"

    elf = ELF(binary)
    if libc != "":
        libc = ELF(libc)
    else:
        libc = None

    if args.d:
        r = debug([binary], gdbscript)
    elif args.r:
        r = remote(ip, port)
    elif args.e:
        r = process(binary)
        r.interactive()
        exit(0)
    else:
        r = process(binary)

    return r, elf, libc