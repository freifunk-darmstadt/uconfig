/* Copyright (C) 2024 John Crispin <john@phrozen.org> */

'use strict';

function transmit(connection, data) {
	warn(`${connection.info().peer_address}: TX ${data}\n`);
	connection.send(`${data}`);
}

export function broadcast(clients, msg) {
	for (let name, connection in clients)
		this.reply(connection, msg);
};

export function reply(connection, msg, params) {
	let data = {
		uconfig: 1,
		method: msg.method
	};

	if (msg.action)
		data.action = msg.action;
	
	if (msg.id)
		data.id = msg.id;

	if (type(params) == 'int')
		data.result = params;
	else if (params)
		data.params = params;

	transmit(connection, data);
};

export function send(connection, action, method, params) {
	/* prepare the actual jsondata message */
	let data = {
		uconfig: 1,
		id: connection.data().id++,
		action,
		method,
	};
	
	if (params)
		data.params = params;
	
	transmit(connection, data);
};
