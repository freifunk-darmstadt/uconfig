/* Copyright (C) 2024 John Crispin <john@phrozen.org> */

'use strict';

import * as settings from 'uconfig.server.settings';
import { ulog, LOG_INFO } from 'log';
import * as rpc from 'uconfig.server.rpc';
import { timer } from 'uloop';

import * as methods from 'uconfig.server.device.methods';

export let devices = {};

export function onData(connection, data, final) {
	let info = connection.info();

	try {
		let msg = json(data);

		if (msg)
			warn(`${connection.info().peer_address}: RX ${msg}\n`);

		if (!msg || !methods[msg.method]) {
			ulog(LOG_INFO, 'invalid message\n');
			return;
		}

		let ret = methods[msg.method](connection, msg);
		if (ret != null)
			rpc.reply(connection, msg, ret);
	} catch(e) {
		warn(`${e.stacktrace[0].context}\n`);
		return;
	}
};

export function onClose(connection, code, reason) {
	let info = connection.info();
	let name = `${info.peer_address}:${info.peer_port}`;
	
	ulog(LOG_INFO, name + ' disconnected\n'); 
	delete devices[name];
};

function connect_cb(connection) {
	try {
		rpc.send(connection, 'event', 'connect');
	} catch(e) {
		warn(`${e.stacktrace[0].context}\n`);
		return;
	}
}

export function onConnect(connection) {
	let info = connection.info();
	let name = `${info.peer_address}:${info.peer_port}`;

	if (!info.x509_peer_subject)
		return connection.close(1003, 'Unsupported protocol requested');

	let cn = split(info.x509_peer_subject, '.');
	if (length(cn) != 2 || cn[0] != 'device')
		return connection.close(1003, 'Unsupported protocol requested');

	connection.data().id = 1;
	devices[name] = connection;
	ulog(LOG_INFO, name + ' connected\n'); 
	timer(1000, () => connect_cb(connection));

	return connection.accept('device');
};
