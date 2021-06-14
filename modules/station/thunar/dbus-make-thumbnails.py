#!/usr/bin/env python3
import sys
import os
import dbus
from dbus.mainloop.glib import DBusGMainLoop
from getopt import getopt
from pathlib import Path
from glob import glob
from hashlib import md5
from contextlib import suppress
from xdg.BaseDirectory import xdg_cache_home
from gi.repository import Gio, GLib

sizes = ['large', 'normal']

recursive = False
hidden = False
delete = False
dry_run = False
files = []

def add_path(p, depth=0):
    if not hidden and p.name.startswith('.') and depth > 0:
        return
    if p.is_dir():
        if recursive or depth == 0:
            for child in p.iterdir():
                add_path(child, depth+1)
    elif p.is_file():
        files.append(p)

opts, args = getopt(sys.argv[1:], ':rhdn')
for o, _ in opts:
    if o == '-r':
        recursive = True
    elif o == '-h':
        hidden = True
    elif o == '-d':
        delete = True
    elif o == '-n':
        dry_run = True
for p in args:
    add_path(Path(p))

uris = []
mimes = []

for path in files:
    f = Gio.File.new_for_path(str(path))
    u = f.get_uri()
    if delete:
        h = md5(u.encode()).hexdigest()
        for size in sizes:
            p = Path(f'{xdg_cache_home}/thumbnails/{size}/{h}.png')
            p.unlink(missing_ok=True)
    if not dry_run:
        uris.append(u)
        i = f.query_info(Gio.FILE_ATTRIBUTE_STANDARD_CONTENT_TYPE, Gio.FileQueryInfoFlags.NONE)
        mimes.append(i.get_content_type())

if not dry_run:
    bus = dbus.SessionBus(mainloop=DBusGMainLoop())
    thumbnailer = bus.get_object('org.freedesktop.thumbnails.Thumbnailer1', '/org/freedesktop/thumbnails/Thumbnailer1')
    interface = dbus.Interface(thumbnailer, 'org.freedesktop.thumbnails.Thumbnailer1')
    def on_finished(handle):
        handles.remove(handle)
        if not handles:
            loop.quit()
    handles = []
    for size in sizes:
        handle = interface.Queue(uris, mimes, size, 'foreground', 0)
        handles.append(handle)
    interface.connect_to_signal('Finished', on_finished)
    loop = GLib.MainLoop()
    loop.run()
