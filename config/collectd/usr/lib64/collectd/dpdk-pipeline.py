#!/usr/bin/python

import collectd
import socket
import sys
import socket
import telnetlib

CONFS = []

def config(config):
    for child in config.children:
        config = {}
        obj = {}
        for c in child.children:
            obj[c.key] = c.values
        CONFS.append(obj)
    log('CONFS {}'.format(CONFS))


def send_telnet_command(host, port, service, table):
    command = "pipeline {}|{} cycle stats read 0 0 clear\n".format(service, table) + "\n"
    log("Send to {}:{} command {}".format(host, port, command))
    command = command.encode('ascii')
    prompt = b">"
    tn = telnetlib.Telnet()
    try:
        tn.open(host, port)
        tn.read_until(prompt)
        tn.write(command)
        return tn.read_until(prompt)
    except err:
        log('Connect to {}:{} {}'.format(host, port, err), log_level='ERROR')
        return None

def read_stat(data=None):
    log('red_stat')
    for pipeline in CONFS:
        for table in pipeline['Tables']:
            res = send_telnet_command(pipeline['Server'][0], pipeline['Port'][0], pipeline['Service'][0], table)
            log('telnet return: {}'.format(res))
            parse_and_dispatch(res, pipeline['Service'][0], table)

def parse_and_dispatch(stats, service, table):
    if not stats:
        return
    stats = stats.splitlines()
    for line in stats:
        r = line.split(' ')
        if len(r) == 2:
            log('dispatch: {} {} {} {}'.format(service, table, r[0], r[1]))
            if r[0] == 'Rx/Pkts/Call:':
                k = r[0][:-1]
                v = float(r[1])
            else:
                k = r[0]
                v = int(r[1])
            val = collectd.Values(plugin='dpdk-pipeline')
            val.plugin_instance = '{}_{}'.format(service, table)
            val.type = 'gauge'
            val.type_instance = k
            val.interval = 10
            val.values = [v]
            val.dispatch()


def log(msg,
        prefix='dpdk-pipeline',
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
