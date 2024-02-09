/* Copyright (C) 2024 John Crispin <john@phrozen.org> */

'use strict';

import { readfile } from 'fs';

export let settings = readfile('/etc/uconfig/settings');
if (settings)
	settings = json(settings);

if (!settings?.server || !settings?.port)
	die('invalid settings\n');
