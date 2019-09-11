#!/usr/bin/python

# Accel-PPP collectd python plugin v0.1
# $Rev: 20 $
# Vladimir Yavorskiy <vovka@krevedko.su>

# This file is part of AccelCollPlug.

# AccelCollPlug is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# AccelCollPlug is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with AccelCollPlug.  If not, see <http://www.gnu.org/licenses/>.

import collectd
import socket

CONFS = []

def config(config):
    for child in config.children:
        config = {}
        args = child.values
        if child.key == 'Server':
            host, port = args[0].split(':')
            log('Server {}:{}'.format(host, port))
        elif child.key == 'Service':
            service = args[0]
            log('Service {}'.format(service))

    CONFS.append({
        'host': host,
        'port': port,
        'service': service
    })

def fetch_show_stat(host, port):
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    try:
        s.connect((host, int(port)))
    except socket.error, err:
        s.close()
        log('Connect to {}:{} {}'.format(host, port, err),
            log_level='ERROR')
        raise
    s.sendall('show stat\n')
    s.shutdown(socket.SHUT_WR)
    recvStat = ''
    while 1:
        recv = s.recv(1024)
        if recv == '':
            break
        recvStat = recvStat + recv
    s.close()
    return recvStat


def parse_stat(data):
    stat = {}
    parent = None
    for line in data.splitlines():
        k, v = line.rstrip().split(':', 1)
        if v is None or v is '':
            parent = k
            stat[k] = {}
        elif k.startswith(' '):
            stat[parent][k.strip()] = v.strip()
        else:
            stat[k] = v.strip()
    return stat


def read_stat(data=None):
    for conf in CONFS:
        data = fetch_show_stat(conf['host'], conf['port'])
        if data is None:
            log('Failed to get statistics from accel-ppp server',
                log_level='ERROR')
            return
        stat_map = parse_stat(data)
        log('Collected stats: \n{}'.format(stat_map),
            log_level='INFO')
        read_pppoe(stat_map, conf['service'])
        read_ipoe(stat_map, conf['service'])


def dispatch_value(value,
                   type='gauge',
                   plugin='accel-ppp',
                   interval=10,
                   type_instance='',
                   plugin_instance='',
                   *args,
                   **kwargs):
    # Format: [<hostname>/]<plugin>[-<plugin_instance>]/<type>[-<type_instance>]
    val = collectd.Values(plugin=plugin)
    val.plugin_instance = plugin_instance
    val.type = type
    val.type_instance = type_instance
    val.interval = interval
    val.values = [value]
    val.dispatch()
    log('Dispatch {} {} {} to {}-{}/{}-{}'.format(type,
                                         type_instance,
                                         value,
                                         plugin,
                                         plugin_instance,
                                         type,
                                         type_instance),
        log_level='INFO')


def read_pppoe(stat, plugin_instance, type_instance='pppoe'):
    pppoe = stat[type_instance]
    for k, v in pppoe.iteritems():
        if k == 'recv PADR(dup)':
            continue
        dispatch_value(int(v),
                       type_instance='{}_{}'.format(type_instance, k),
                       plugin_instance=plugin_instance)

def read_ipoe(stat, plugin_instance, type_instance='ipoe'):
    ipoe = stat[type_instance]
    for k, v in ipoe.iteritems():
        dispatch_value(int(v),
                       type_instance='{}_{}'.format(type_instance, k),
                       plugin_instance=plugin_instance)

def log(msg,
        prefix='Accel-ppp',
        log_level='INFO'):
    log_msg = '[{}] {}: {}'.format(log_level.upper(), prefix, msg)
    try:
        getattr(collectd, log_level.lower())(log_msg)
    except AttributeError:
        err_msg = ("Log level '{}' is not defined use one of the following "
                   'log levels [error, warning, notice, info, debug]'
                   ).format(log_level)
        log(err_msg, log_level='ERROR')
        raise

collectd.register_read(read_stat)
collectd.register_config(config)
