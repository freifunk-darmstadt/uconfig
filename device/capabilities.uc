/* Copyright (C) 2024 John Crispin <john@phrozen.org> */

'use strict';

import * as fs from 'fs';

export let capabilities = {};
let file = fs.open('/etc/uconfig/capabilities.json', 'r');
if (!file)
	die('failed to load capabilities');
capabilities = json(file.read('all'));
file.close();
