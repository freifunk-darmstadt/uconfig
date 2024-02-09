/* Copyright (C) 2024 John Crispin <john@phrozen.org> */

'use strict';

import * as config from 'uconfig.device.config';

export let active = 0;
export let reconnect = 10;

export function connected() {
	active = time();
};

export function disconnected() {
	active = 0;
};

export function status() {
	return {
		connected: active ? time() - active : 0,
		latest: config.uuid,
	};
};
