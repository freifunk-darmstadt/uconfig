/* Copyright (C) 2024 John Crispin <john@phrozen.org> */

'use strict';

import * as rpc from 'uconfig.server.rpc';
import * as fs from 'fs';
export let data;

export function store() {
	fs.writefile('/etc/uconfig/settings', data);
};

export function configured(state) {
	data.configured = state;
	this.store();
	rpc.broadcast(global.admins, { method: 'event', action: state ? 'login-required' : 'setup-required' });
};

data = fs.readfile('/etc/uconfig/settings');
if (data)
	data = json(data);

if (!data) {
	data = { configured: false };
	store();
}
