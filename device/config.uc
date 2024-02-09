/* Copyright (C) 2024 John Crispin <john@phrozen.org> */

'use strict';

import { ulog, LOG_INFO } from 'log';
let uconfig = require('uconfig.uconfig');
import * as fs from 'fs';

export let uuid = 1;

export function apply(config, test) {
	let file = sprintf('/etc/uconfig/uconfig.cfg.%010d', config.uuid);
	let message = "failed to apply";
	let code = 1;

	try {
		ulog(LOG_INFO, 'applying config uuid: %s\n', config.uuid);
		message = { rejected: uconfig.generate(file, false, test) };
		code = 0;
		uuid = config.uuid;
	} catch (e) {
		warn('Fatal error while generating UCI: ', e, '\n');
		warn(e.stacktrace[0].context, '\n');
		message = e.message;
	}

	gc();

	return { code, message };
};

export function load(path) {
	let config = json(fs.readfile(sprintf('/etc/uconfig/%s', path)));

	if (config) {
		ulog(LOG_INFO, 'loaded %s\n', path);
		uuid = config.uuid;
	}
	return config || {};
};

export function store(config) {
	fs.writefile(sprintf('/etc/uconfig/uconfig.cfg.%010d', config.uuid), config);
	return true;
};

export function active(uuid) {
	let file = sprintf('/etc/uconfig/uconfig.cfg.%10d', uuid);
	fs.unlink('/etc/uconfig/uconfig.active');
	fs.symlink(file, '/etc/uconfig/uconfig.active');
};

let config = load('uconfig.active');
if (!config)
	config = load('uconfig.cfg.0000000001');

apply(config, true);
