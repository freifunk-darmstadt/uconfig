/* Copyright (C) 2024 John Crispin <john@phrozen.org> */

'use strict';

import { ulog, LOG_INFO, LOG_ERR } from 'log';
import * as libubus from 'ubus';

let methods = {};

export let ctx = libubus.connect();

export function publish() {
	if (ctx) 
		ctx.publish("uconfig", methods);
	else
		ulog(LOG_ERR, 'failed to connect to ubus\n');

};

export function add(name, call, args) {
	/* store the method inside the dictionary*/
	methods[name] = {
		call,
		args: args || {},
	};
};
