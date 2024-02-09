/* Copyright (C) 2024 John Crispin <john@phrozen.org> */

'use strict';

import * as settings from 'uconfig.server.settings';
import * as users from 'uconfig.server.users';
import * as rpc from 'uconfig.server.rpc';
import { ulog, LOG_INFO } from 'log';

export function authenticate(connection, msg) {
	if (!users.login(msg.params?.username, msg.params?.password))
		return -1;

	ulog(LOG_INFO, `${msg.params.username} logged in \n`);
	connection.data().username = msg.params.username;

	return 0;
};

export function password(connection, msg) {
	if (users.passwd(connection, msg.params?.username, msg.params?.password))
		return -1;

	return 0;
};
