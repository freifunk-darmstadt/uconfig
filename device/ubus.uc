'use strict';

import { connect } from 'ubus';
export let ubus = connect();

if (!ubus)
	die('ERROR: failed to load UBUS context');
