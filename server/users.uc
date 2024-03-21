/* copyright (c) 2024 john crispin <john@phrozen.org> */

'use strict';

import * as settings from 'uconfig.server.settings';
import * as utils from 'uconfig.utils';
import * as math from 'math';
import * as fs from 'fs';

let users = fs.readfile('/etc/uconfig/users');
if (users)
	users = json(users) || {};

math.srand(time());

function random_string(len) {
	let chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
	let mod = length(chars) - 1;
	let str = '';

	for (let  i = 0; i < len; i++)
		str += substr(chars, math.rand() % mod, 1);

	return str;
}

export function exist(username) {
	return users[username];
};

export function login(username, password) {
	if (!username || !password || !users[username]?.crypt ||
	    users[username].crypt != utils.crypt(password, `$5$${split(users[username].crypt, '$')[2]}`))
		return null;
	
	return users[username];
};

export function passwd(connection, username, password) {
	if (!users[username] || !password)
		return -1;
	
	if (!(connection.data().username in [ 'admin', username ]))
		return -1;

	users[username].crypt = utils.crypt(password, `$5$${random_string(16)}`);;

	fs.writefile('/etc/uconfig/users', users);
};

export function acl(connection, msg) {
	if (!settings.data.configured) 
		return (msg.action == 'config' && msg.method == 'wizard') ||
		       (msg.action == 'event' && msg.method == 'ping');

	if (!connection.data().username)
		return (msg.action == 'user' && msg.method == 'authenticate');

	if (!users[connection.data().username].acl)
		return false;

	let acl = users[connection.data().username].acl[msg.action];
	switch(type(acl)) {
	case 'bool':
		return acl;

	case 'array':
		return msg.method in acl;
	}

	return false;
};
