/* Copyright (C) 2024 John Crispin <john@phrozen.org> */

'use strict';

import * as ubus from 'uconfig.server.ubus';
import * as fs from 'fs';

function clockms() {
	const t = clock(true);

	return (t[0] * 1000) + (t[1] / 1000000);
}

function filedata(ctype, body) {
	let boundary = match(ctype, /^multipart\/form-data;.*\bboundary=([^;]+)/)?.[1];

	if (!boundary)
		return null;

	if (substr(body, 0, 2) != '--' ||
	    substr(body, 2, length(boundary)) != boundary ||
	    substr(body, 2 + length(boundary), 2) != '\r\n' ||
	    substr(body, -(length(boundary) + 8), 4) != '\r\n--' ||
		substr(body, -(length(boundary) + 4), length(boundary)) != boundary ||
		substr(body, -4, 4) != '--\r\n')
	    return null;

	let chunks = split(
		substr(body, 4 + length(boundary), -(length(boundary) + 8)),
		`\r\n--${boundary}\r\n`
	);

	for (let chunk in chunks) {
		let header_payload = split(chunk, '\r\n\r\n', 2);
		let headers = {};
		let data;

		if (length(header_payload) == 2) {
			for (let header in split(header_payload[1] ? header_payload[0] : '', '\r\n')) {
				let nv = split(header, ':', 2);

				if (length(nv) == 2)
					headers[lc(trim(nv[0]))] = trim(nv[1]);
			}

			data = header_payload[1];
		}
		else {
			data = header_payload[0];
		}

		let cdisp = match(headers['content-disposition'], /^form-data;.*\bfilename=("(([^"\\]|\\.)+)"|'(([^'\\]|\\.)+)'|([^;]+\b))/);

		if (cdisp) {
			return {
				name: trim(length(cdisp[2]) ? cdisp[2] : (length(cdisp[4]) ? cdisp[4] : cdisp[6])),
				type: match(headers['content-type'], /^([^/]+\/[^;\s]+)\b/)?.[1],
				data
			};
		}
	}

	return null;
}

export function onRequest(request, method, uri) {
	request.data({ });
//	warn(`Received request: ${method} ${uri}\n`);
};

export function onBody(request, data) {
	let ctx = request.data();
	if (request.method() == 'POST') {
		if (length(ctx.body) + length(data) > 0x2000000) {
			return request.reply({
				'Status': '413 Payload Too Large',
				'Content-Type': 'text/plain'
			}, 'Please do not upload files larger than 32MB');
		}

		if (length(data)) {
			ctx.body = ctx.body ? ctx.body + data : data;

			return;
		}
	} else {
		return request.reply({
			'Status': '405 Method Not Allowed',
			'Content-Type': 'text/plain'
		}, 'Please only send POST requests');
	}

	let file = filedata(request.header('Content-Type'), ctx.body);

	if (!file) {
		return request.reply({
			'Status': '422 Unprocessable Entity',
			'Content-Type': 'text/plain'
		}, 'Unable to find file data in POST request body');
	}

	let path = '/tmp/upgrade.bin';
	fs.writefile(path, file.data);

	let validate = ubus.ctx.call('system', 'validate_firmware_image', { path }) || {};
	let ret = { valid: validate.valid || false };
	if (validate.valid)
		ret.checksum = validate.checksum;
	else
		fs.unlink(path);

	return request.reply({
		'Status': '200 OK',
		'Content-Type': 'application/json'
	}, ret);

	return 1;
};
