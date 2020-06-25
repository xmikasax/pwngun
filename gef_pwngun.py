class FileInspect(GenericCommand):
    """Inspect _IO_FILE_plus structure."""
    _cmdline_ = "fi"
    _syntax_  = "{:s} ADDRESS".format(_cmdline_)

    @only_if_gdb_running
    def do_invoke(self, argv):
        if len(argv) < 1:
            self.usage()
            return

        try:
            address = int(gdb.parse_and_eval(argv[0]))
        except gdb.error:
            err("Failed to parse '{:s}'".format(argv[0]))
            return

        gdb.execute("p *(struct _IO_FILE_plus*) {:d}".format(address))
        return

register_external_command(FileInspect())
