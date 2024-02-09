/* Copyright (C) 2024 John Crispin <john@phrozen.org> */

'use strict';

import * as rpc from 'uconfig.server.rpc';
import * as uloop from 'uloop';
import { ulog, LOG_INFO } from 'log';
import * as fs from 'fs';

let rollback_timer;
export let pending = false;

function symlink(target, path) {
	fs.unlink(path);
	fs.symlink(target, path);
}

function uuid(path) {
	return +split(path, '.')[2];
}

function rollback_cb() {
	let config = fs.readlink('/etc/uconfig/uconfig.pending');

	if (!config)
		return -1;
	
	ulog(LOG_INFO, `rollback config UUID: ${uuid(config)}\n`);
	fs.unlink('/etc/uconfig/uconfig.pending');

	pending = false;

	return 0;
}

export function get() {
	let config = fs.readfile('/etc/uconfig/uconfig.active');

	if (!config)
		return {};

	config = json(config);
	if (!config)
		return {};
	
	return config;
};

export function store(connection, msg) {
	if (pending)
		return -1;

	let config = msg.params.config;

	config.uuid = time();
	ulog(LOG_INFO, `received new config with uuid: ${config.uuid}, verifying it now\n`);
	let path = sprintf('/etc/uconfig/uconfig.cfg.%10d', config.uuid);
	fs.writefile(path, config);

	pending = true;
	uloop.task(
		function(pipe) {
			let stdout = fs.popen('sleep 3');
			let result = stdout.read("all");
			let error = stdout.close();
			return { result, error };
		},
		
		function(res) {
			let ret = { uuid: config.uuid };

			pending = false;
			if (res.error) {
				fs.unlink(path);
				ret = -1;				
			}
			rpc.reply(connection, msg, ret);
		}
	);
};

export function apply(connection, msg) {
	if (pending || !msg.params?.uuid)
		return -1;

	let rollback = msg.params.rollback || false;
	let path = sprintf('/etc/uconfig/uconfig.cfg.%10d', msg.params.uuid);
	let active = fs.readlink('/etc/uconfig/uconfig.active');

	if (!fs.stat(path))
		return -1;

	ulog(LOG_INFO, `applying config uuid: ${msg.params.uuid}, rollback: ${msg.params.rollback || false}\n`);
	if (rollback)
		symlink(path, '/etc/uconfig/uconfig.pending');
	else
		symlink(path, '/etc/uconfig/uconfig.active');

	pending = true;
	uloop.task(
		function(pipe) {
			let stdout;
			
			if (fs.stat('/sbin/render_config'))
				stdout = fs.popen('/sbin/render_config ' + path);
			else
				stdout = fs.popen('sleep 3');
			let result = stdout.read("all");
			let error = stdout.close();
			return { result, error };
		},
		
		function(res) {
			let ret = { uuid: msg.params.uuid, rollback };

			if (res.error) {
				ret = -1;
				if (rollback)
					fs.unlink('/etc/uconfig/uconfig.pending');
				else
					symlink(active, '/etc/uconfig/uconfig.active');
				pending = false;
			} else {
				pending = rollback;
			}

			if (pending)
				rollback_timer = uloop.timer(10000, rollback_cb);
			rpc.reply(connection, msg, ret);
		}
	);
};

export function list() {
	let list = fs.glob('/etc/uconfig/uconfig.cfg.*');
	let active = fs.readlink('/etc/uconfig/uconfig.active');
	let pending = fs.readlink('/etc/uconfig/uconfig.pending');
	let ret = { configs: [] };

	for (let k, v in list)
		push(ret.configs, uuid(v));

	ret.configs = sort(ret.configs);

	if (active)
		ret.active = uuid(active);
	
	if (pending)
		ret.pending = uuid(pending);

	return ret;
};

export function rollback() {
	let active = fs.readlink('/etc/uconfig/uconfig.pending');

	if (!pending || !active || !rollback_timer || !rollback_timer.remaining())
		return -1;

	return rollback_cb();
};

export function confirm() {
	let active = fs.readlink('/etc/uconfig/uconfig.pending');

	if (!pending || !active || !rollback_timer || !rollback_timer.remaining())
		return -1;

	fs.unlink('/etc/uconfig/uconfig.pending');
	symlink(active, '/etc/uconfig/uconfig.active');
	rollback_timer?.cancel();

	pending = false;

	return 0;
};
