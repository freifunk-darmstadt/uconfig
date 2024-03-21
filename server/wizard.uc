/* Copyright (C) 2024 John Crispin <john@phrozen.org> */

'use strict';

import * as settings from 'uconfig.server.settings';
import * as rpc from 'uconfig.server.rpc';
import * as config from 'uconfig.server.config';
import { ulog, LOG_INFO } from 'log';
import { timer } from 'uloop';

function generate(msg) {

	let cfg = {
		'uuid': time(),
		'unit': {
			'name': 'uconfig AP',
			'location': 'Home',
			'timezone': 'CET-1',
			'leds-active': true
		},
		'country-code': 'US',
		'radios': {
			'2G': {
				'channel-mode': 'HE',
				'channel-width': 40
			},
			'5G': {
				'channel-mode': 'HE',
				'channel-width': 80,
				'channel': 36
			}
		},
		'interfaces': {
			'wan': {
				'role': 'upstream',
				'services': [ 'mdns', 'ssh',  'web-ui' ],
				'ports': {
					'wan*': 'auto',
					'lan*': 'auto'
				},
				'ipv4': {
					'addressing': 'dynamic'
				},
				'ipv6': {
					'addressing': 'dynamic'
				},
				'ssids': {
				},
			}
		},
		'services': {
			'ssh': {
				'port': 22
			},
			'mdns': {
				'additional-hostnames': [
					'config'
				]
			}
		}
	};

	if (msg.device.hostname)
		cfg.unit.hostname = msg.device.hostname;

	if (msg.wan?.addressing == 'static')
		cfg.interfaces.wan.ipv4 = {
			addressing: 'static',
			subnet: msg.wan.subnet,
			gateway: msg.wan.gateway,
			'use-dns': [ msg.wan.dns ]
		};

	if (msg.wifi?.ssid && msg.wifi?.password) {
		cfg.interfaces.wan.ssids.main = {
			'ssid': msg.wifi.ssid,
			'wifi-radios': [ '2G', '5G' ],
			'bss-mode': 'ap',
			'encryption': {
				'proto': (msg.wifi.security == 'max') ? 'sae' : 'sae-mixed',
				'key': msg.wifi.password,
				'ieee80211w': (msg.wifi.security == 'max') ? 'required' : 'optional'
			}
		};
	
		if (msg.guest?.enable == 'enable' && msg.guest?.password) {
			cfg.interfaces.wan.ssids.guest = {
				'ssid': msg.wifi.ssid + '-Guest',
				'wifi-radios': [ '2G', '5G' ],
				'bss-mode': 'ap',
				'encryption': {
					'proto': (msg.wifi.security == 'max') ? 'sae' : 'sae-mixed',
					'key': msg.guest.password,
					'ieee80211w': (msg.wifi.security == 'max') ? 'required' : 'optional'
				}
			};
		}

		if (msg.iot?.enable == 'enable' && msg.iot?.password) {
			cfg.interfaces.wan.ssids.iot = {
				'ssid': msg.wifi.ssid + '-IoT',
				'wifi-radios': [ '2G', '5G' ],
				'bss-mode': 'ap',
				'encryption': {
					'proto': (msg.wifi.security == 'max') ? 'sae' : 'sae-mixed',
					'key': msg.iot.password,
					'ieee80211w': (msg.wifi.security == 'max') ? 'required' : 'optional'
				}
			};
		}
	}
		
	config.store(null, { params: cfg }, (ret) => {
		settings.configured(ret);
	});
}

export function apply(msg) {
	if (settings.data.configured)
		return -1;

	timer(2000, () => generate(msg.params));

	rpc.broadcast(global.admins, { method: 'event', action: 're-configuring'});

	return 0;
};
