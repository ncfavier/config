#!/usr/bin/env python3
import sys
import os
from getopt import getopt
from pathlib import Path
from hashlib import md5
from xdg.BaseDirectory import xdg_cache_home
from gi.repository import Gio, GLib
import dbus
from dbus.mainloop.glib import DBusGMainLoop

sizes = ['normal', 'large']
recursive = False
hidden = False
delete = False
dry_run = False
files = []

def get_thumbnail_path(uri, size):
    return f'{xdg_cache_home}/thumbnails/{size}/{md5(uri.encode()).hexdigest()}.png'

def add_path(p, depth=0):
    if not hidden and p.name.startswith('.') and depth > 0:
        return
    if p.is_dir():
        if recursive or depth == 0:
            for child in p.iterdir():
                add_path(child, depth+1)
    elif p.is_file():
        files.append(p)

opts, args = getopt(sys.argv[1:], ':rhdns:')
for o, arg in opts:
    if o == '-r':
        recursive = True
    elif o == '-h':
        hidden = True
    elif o == '-d':
        delete = True
    elif o == '-n':
        dry_run = True
    elif o == '-s':
        sizes = [arg]
for p in args:
    add_path(Path(p))

uris = []
mimes = []

for path in files:
    f = Gio.File.new_for_path(str(path))
    uri = f.get_uri()
    if delete:
        for size in sizes:
            Path(get_thumbnail_path(uri, size)).unlink(missing_ok=True)
    if not dry_run:
        uris.append(uri)
        i = f.query_info(Gio.FILE_ATTRIBUTE_STANDARD_CONTENT_TYPE, Gio.FileQueryInfoFlags.NONE)
        mimes.append(i.get_content_type())

if not dry_run:
    bus = dbus.SessionBus(mainloop=DBusGMainLoop())
    thumbnailer = bus.get_object('org.freedesktop.thumbnails.Thumbnailer1', '/org/freedesktop/thumbnails/Thumbnailer1')
    interface = dbus.Interface(thumbnailer, 'org.freedesktop.thumbnails.Thumbnailer1')
    def on_ready(handle, uris):
        for uri in uris:
            print(get_thumbnail_path(uri, handles[handle]))
    def on_finished(handle):
        del handles[handle]
        if not handles:
            loop.quit()
    interface.connect_to_signal('Ready', on_ready)
    interface.connect_to_signal('Finished', on_finished)
    handles = {}
    for size in sizes:
        handles[interface.Queue(uris, mimes, size, 'foreground', 0)] = size
    loop = GLib.MainLoop()
    loop.run()
