/* Copyright (C) 2024 John Crispin <john@phrozen.org> */

'use strict';

import * as fs from 'fs';
export let data;

export function store() {
	fs.writefile('/etc/uconfig/settings', data);
};

data = fs.readfile('/etc/uconfig/settings');
if (data)
	data = json(data);

if (!data) {
	data = { configured: false };
	store();
}
