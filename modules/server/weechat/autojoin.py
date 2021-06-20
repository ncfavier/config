# Copyright (c) 2009 by xt <xt@bash.no>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

# Modified by Naïm Favier <n@monade.li> to
# - autosave on join/part
# - sort channel names to keep config deterministic

import weechat as w
import re

SCRIPT_NAME    = "autojoin"
SCRIPT_AUTHOR  = "xt <xt@bash.no>"
SCRIPT_VERSION = "0.3.1"
SCRIPT_LICENSE = "GPL3"
SCRIPT_DESC    = "Configure autojoin for all servers according to currently joined channels"
SCRIPT_COMMAND = "autojoin"

# script options
settings = {
    "autosave": "off",
}

if w.register(SCRIPT_NAME, SCRIPT_AUTHOR, SCRIPT_VERSION, SCRIPT_LICENSE, SCRIPT_DESC, "", ""):

    w.hook_command(SCRIPT_COMMAND,
                   SCRIPT_DESC,
                   "[--run]",
                   "   --run: actually run the commands instead of displaying\n",
                   "--run",
                   "autojoin_cb",
                   "")

    w.hook_signal('*,irc_in2_join', 'autosave_channels_on_activity', '')
    w.hook_signal('*,irc_in2_part', 'autosave_channels_on_activity', '')
    w.hook_signal('quit',           'autosave_channels_on_quit', '')

# Init everything
for option, default_value in settings.items():
    if w.config_get_plugin(option) == "":
        w.config_set_plugin(option, default_value)


def autosave_channels_on_quit(signal, callback, callback_data):
    ''' Autojoin current channels '''
    if w.config_get_plugin(option) != "on":
        return w.WEECHAT_RC_OK

    items = find_channels()

    # print/execute commands
    for server, channels in items.items():
        process_server(server, channels)

    return w.WEECHAT_RC_OK


def autosave_channels_on_activity(signal, callback, callback_data):
    ''' Autojoin current channels '''
    if w.config_get_plugin(option) != "on":
        return w.WEECHAT_RC_OK

    items = find_channels()

    # print/execute commands
    for server, channels in items.items():
        nick = w.info_get('irc_nick', server)
        pattern = "^:%s![^ ]* +(JOIN|PART) " % re.escape(nick)

        if re.match(pattern, callback_data):
            process_server(server, channels)

    return w.WEECHAT_RC_OK


def autojoin_cb(data, buffer, args):
    if args == '--run':
        run = True
    elif args != '':
        w.prnt('', 'Unexpected argument: %s' % args)
        return w.WEECHAT_RC_ERROR
    else:
        run = False

    # Old behaviour: doesn't save empty channel list
    # In fact should also save open buffers with a /part'ed channel
    # But I can't believe somebody would want that behaviour
    items = find_channels()

    # print/execute commands
    for server, channels in items.items():
        process_server(server, channels, run)

    return w.WEECHAT_RC_OK


def process_server(server, channels, run=True):
    option = "irc.server.%s.autojoin" % server
    channels = channels.rstrip(',')
    oldchans = w.config_string(w.config_get(option))

    if not channels:  # empty channel list
        return

    # Note: re already caches the result of regexp compilation
    sec = re.match('^\${sec\.data\.(.*)}$', oldchans)
    if sec:
        secvar = sec.group(1)
        command = "/secure set %s %s" % (secvar, channels)
    else:
        command = "/set irc.server.%s.autojoin '%s'" % (server, channels)

    if run:
        w.command('', command)
    else:
        w.prnt('', command)


def find_channels():
    """Return list of servers and channels"""
    # TODO: make it return a dict with more options like "nicks_count etc."
    items = {}
    infolist = w.infolist_get('irc_server', '', '')
    # populate servers
    while w.infolist_next(infolist):
        items[w.infolist_string(infolist, 'name')] = ''

    w.infolist_free(infolist)

    # populate channels per server
    for server in items.keys():
        channels = []
        infolist = w.infolist_get('irc_channel', '',  server)
        while w.infolist_next(infolist):
            if w.infolist_integer(infolist, 'nicks_count') == 0:
                # parted but still open in a buffer: bit hackish
                continue
            if w.infolist_integer(infolist, 'type') == 0:
                name = w.infolist_string(infolist, "name")
                key = w.infolist_string(infolist, "key")
                channels.append((name, key))
        # sort by name, keyed channels first
        channels.sort(key = lambda c: (not c[1], c[0]))
        items[server] = ','.join(name for name, key in channels)
        keys = ','.join(key for name, key in channels if key)
        if keys:
            items[server] += ' ' + keys
        w.infolist_free(infolist)

    return items
