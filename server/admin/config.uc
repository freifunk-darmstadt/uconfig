/* Copyright (C) 2024 John Crispin <john@phrozen.org> */

'use strict';

import * as config from 'uconfig.server.config';
import * as rpc from 'uconfig.server.rpc';

export function get(connection, msg) {
	return { config: config.get() };
};

export function upload(connection, msg) {
	if (!msg?.params?.config)
		return -1;

	return config.store(connection, msg);
};

export function list() {
	return config.list();
};

export function apply(connection, msg) {
	return config.apply(connection, msg);
};

export function confirm() {
	return config.confirm();
};

export function rollback() {
	return config.rollback();
};
