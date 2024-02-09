/* Copyright (C) 2024 John Crispin <john@phrozen.org> */

'use strict';

import * as settings from 'uconfig.server.settings';
import { ulog, LOG_INFO } from 'log';
import * as users from 'uconfig.server.users';
import * as rpc from 'uconfig.server.rpc';
import { timer } from 'uloop';

import * as system from 'uconfig.server.admin.system';
import * as config from 'uconfig.server.admin.config';
import * as event from 'uconfig.server.admin.event';
import * as user from 'uconfig.server.admin.user';
import * as get from 'uconfig.server.admin.get';

let handlers = {
	system,
	config,
	event,
	user,
	get,
};

let admins = {};

export function onData(connection, data, final) {
	let info = connection.info();

	try {
		let msg = json(data);

		if (msg)
			warn(`${connection.info().peer_address}: RX ${msg}\n`);

		if (!msg || !handlers[msg.action] || !handlers[msg.action][msg.method]) {
			ulog(LOG_INFO, 'invalid message\n');
			return;
		}

		if (!users.acl(connection, msg)) {
			ulog(LOG_INFO, `${connection.data().username} has an ACL violation\n`);
			rpc.reply(connection, msg, -1);
			return;
		}
	
		let ret = handlers[msg.action][msg.method](connection, msg);
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
	delete admins[name];
};

function connect_cb(connection) {
	try {
		let event = 'login-required';

		if (!settings.data.configured)
			event = 'setup-required';
		else if (connection.data().username)
			event = 'authenticated';

		rpc.send(connection, 'event', event);
	} catch(e) {
		warn(`${e.stacktrace[0].context}\n`);
		return;
	}
}

export function onConnect(connection) {
	let info = connection.info();
	let name = `${info.peer_address}:${info.peer_port}`;

	if (info.x509_peer_subject) {
		let cn = split(info.x509_peer_subject, '.');
		if (length(cn) != 2 || cn[0] != 'user' || !users.exist(cn[1]))
			return connection.close(1003, 'Unsupported protocol requested');
		connection.data().username = cn[1];
	}

	connection.data().id = 1;
	admins[name] = connection;
	ulog(LOG_INFO, name + ' connected\n'); 
	timer(1000, () => connect_cb(connection));

	return connection.accept('config');
};
