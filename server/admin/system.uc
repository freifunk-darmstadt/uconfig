/* Copyright (C) 2024 John Crispin <john@phrozen.org> */

'use strict';

import * as ubus from 'uconfig.server.ubus';
import * as rpc from 'uconfig.server.rpc';
import { ulog, LOG_INFO } from 'log';
import { timer } from 'uloop';
import * as fs from 'fs';

export function reboot(connection, msg) {
	if (!ubus.ctx)
		return -1;

	timer(2000, () => {
		ulog(LOG_INFO, 'rebooting\n');
		ubus.ctx.call('system', 'reboot')
	});

	global.shutdown = true;

	return 0;
};

export function factory(connection, msg) {
	timer(2000, () => {
		ulog(LOG_INFO, 'factory reset\n');
		system('jffs2reset -y -r');
	});
	
	global.shutdown = true;

	return 0;
};

export function sysupgrade(connection, msg) {
	if (!fs.stat('/tmp/upgrade.bin'))
		return -1;

	timer(2000, () => {
		ulog(LOG_INFO, 'sysupgrade\n');
		system('sysupgrade -n /tmp/upgrade.bin');
	});
	
	global.shutdown = true;

	return 0;
};

export function delete_upgrade(connection, msg) {
	fs.unlink('/tmp/upgrade.bin');

	return 0;
};

export function info(connection, msg) {
	let info = ubus.ctx.call('system', 'info');

	for (let l = 0; l < 3; l++)
		info.load[l] /= 65535;

	return info;
};

export function board(connection, msg) {
	return ubus.ctx.call('system', 'board');
};
