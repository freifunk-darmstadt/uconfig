/* Copyright (C) 2022 John Crispin <john@phrozen.org> */

'use strict';

import { capabilities } from 'uconfig.device.capabilities';
import { settings } from 'uconfig.device.settings';
import * as context from 'uconfig.device.context';
import * as config from 'uconfig.device.config';
import { ubus } from 'uconfig.device.ubus';
import { ulog, LOG_INFO } from 'log';
import * as fs from 'fs';

let methods;

function notification(method, params) {
	let msg = {
		uconfig: 1,
		method
	};
	if (params)
		msg.params = params;

	printf(`TX: ${msg}\n`);
	global.connection.send(msg);
}

function response(id, result) {
	let msg = {
		uconfig: 1,
		id
	};

	if (result.code)
		msg.error = result;
	else
		msg.result = result.message;

	printf(`TX: ${msg}\n`);
	global.connection.send(msg);
}

export function handle(msg) {
	if (msg.uconfig != 1 || !msg.method)
		return false;

	let handler = methods[msg.method];
	if (!handler) {
		response(msg.id, { code: 2, message: 'Unknown method.' });
		return false;
	}

	let result;
	try {
		result = handler(msg);
	} catch(e) {
		if (e?.code !== null)
			result = e;
		else
			result = { code: 2, message: e.message };
	}

	if (result?.code != null) {
		ulog(LOG_INFO, '\'%s\' command was executed - \'%s\' (%d)\n',
			  msg.method, result.message, result.code);
		response(msg.id, result);
	}
};

export function connect() {
	warn('onConnect\n');
	notification('connect', {
		uuid: config.uuid,
		capabilities: capabilities,
	});
};

export function event(msg) {
	notification('event', msg);
};

export function crashlog() {
	let file = fs.open('/sys/fs/pstore/dmesg-ramoops-0', 'r');
	let line, crashlog = [];

	while (line = file.read('line'))
	        push(crashlog, trim(line));
	file.close();

	fs.unlink('/sys/fs/pstore/dmesg-ramoops-0');
	notification('crashlog', { crashlog });
};

export function keepalive() {
	notification('keepalive');
};

methods = {
	configure: function(msg) {
		let cfg = msg.params;

		if (!cfg.uuid)
			die({code: 2, message: 'config is missing its uuid'});

		ulog(LOG_INFO, 'received a new configuration\n');

		if (!config.store(cfg))
			die({code: 2, message: 'failed to store new configuration'});

		let response = config.apply(cfg);
		if (response.code)
			return response;

		config.active(cfg.uuid);

		uloop_timeout(function() {
				ulog(LOG_INFO, 'trigger config reload\n');
				system('reload_config');
			}, 2000);

		return response;
	},

	reboot: function(msg) {
		uloop_timeout(function() {
				global.connection.close();
				ubus.call('system', 'reboot');
			}, 2000);

		return { code: 0, message: 'rebooting' };
	},

	factory: function(msg) {
		uloop_timeout(function() {
				global.connection.close();
				system('/sbin/jffs2reset -y -r');
			}, 2000);

		return { code: 0, message: 'factory resetting' };
	},

	leds: function(msg) {
		switch (msg.params?.pattern) {
		case 'on':
			system('/etc/init.d/led turnon');
			break;

		case 'off':
			system('/etc/init.d/led turnoff');
			break;

		case 'blink':
			ulog(LOG_INFO, 'start blinking the LEDs\n');
			uloop_process(function(retcode, priv) {
					ulog(LOG_INFO, 'stop blinking the LEDs\n');
					response(priv.id, { code: 0, message: 'success' });
				},
				[ '/usr/libexec/uconfig.device/led_blink.sh', msg.params?.duration || 10 ], { id: msg.id });
			return;

		default:
			return { code: 2, message: 'invalid LED pattern' };
		}

		return { code: 0, message: 'success' };
	},

	upgrade: function(msg) {
		let image_path = '/tmp/uconfig.upgrade';
		let download_cmdline = [ 'wget', '-O', image_path, msg.params.url ];
		let rc = system(download_cmdline);
		let fw_validate = ubus.call('system', 'validate_firmware_image', { path: image_path });
		if (!fw_validate?.valid) {
			fs.unlink(image_path);
			return { code: 1, message: 'Firmware failed to be validated.' };
		}

		let sysupgrade_cmdline = [ 'sysupgrade' ];
		if (msg.params.keep_controller) {
			let archive_cmdline = [
				'tar', 'czf', '/tmp/sysupgrade.tgz',
				'/etc/uconfig/settings'
			];
		        let active_config = fs.readlink("/etc/uconfig/uconfig.active");
			if (active_config)
		                push(archive_cmdline, '/etc/uconfig/uconfig.active', active_config);
			let rc = system(archive_cmdline);
			if (rc)
				return { code: 1, message: 'Failed to create /tmp/sysupgrade.tgz.' };

			push(sysupgrade_cmdline, '-f');
			push(sysupgrade_cmdline, '/tmp/sysupgrade.tgz');
		} else
			push(sysupgrade_cmdline, '-n');
		push(sysupgrade_cmdline, image_path);

		/* perfofmt he sysupgrade */
		uloop_timeout(function() {
				global.connection.close();
				system(sysupgrade_cmdline);
			}, 2000);

		return { code: 0, message: 'Performing sysupgrade' };
	},
};
