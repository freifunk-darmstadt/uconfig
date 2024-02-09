/* Copyright (C) 2024 John Crispin <john@phrozen.org> */

'use strict';

import * as ubus from 'uconfig.server.ubus';

import { ulog_open, ulog, ULOG_SYSLOG, ULOG_STDIO, LOG_DAEMON } from 'log';
ulog_open(ULOG_SYSLOG | ULOG_STDIO, LOG_DAEMON, 'uconfig.server');

import * as admin from 'uconfig.server.admin.delegate';
import * as device from 'uconfig.server.device.delegate';
import * as upload from 'uconfig.server.upload';

ubus.publish();

export function onConnect(connection, protocols)
{
	if (global.shutdown)
		return connection.close(1012, 'Server is restarting');

	let protocol;
	let delegate;

	if ('config' in protocols)
		delegate = admin;
	else if ('device' in protocols)
		delegate = device;
	else
		return connection.close(1003, 'Unsupported protocol requested');
 
	connection.data({
		counter: 0,
		n_messages: 0,
		n_fragments: 0,
		msg: '',
		delegate,
	});

	return delegate.onConnect(connection);
};

export function onData(connection, data, final)
{
	if (global.shutdown)
		return connection.close(1012, 'Server is restarting');

	let ctx = connection.data();

	if (length(ctx.msg) + length(data) > 32 * 1024)
		return connection.close(1009, 'Message too big');

	ctx.msg = ctx.n_fragments ? ctx.msg + data : data;
	if (final) {
		ctx.n_messages++;
		ctx.n_fragments = 0;
	}
	else {
		ctx.n_fragments++;
		return;
	}

	return ctx.delegate.onData(connection, ctx.msg, final);
};

export function onClose(connection, code, reason)
{
	let ctx = connection.data();
	if (ctx.delegate)
		return ctx.delegate.onClose(connection, code, reason);
};

export function onRequest(request, method, uri) {
	return upload.onRequest(request, method, uri);
};

export function onBody(request, data) {
	return upload.onBody(request, data);
};
