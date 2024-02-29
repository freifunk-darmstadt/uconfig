import { ubus } from 'uconfig.ubus';
import * as rtnl from 'rtnl';

import * as fs from 'fs';

let capabilities = json(fs.readfile('/etc/uconfig/capabilities.json'));

export function board_info() {
	return ubus.call('system', 'board');
};

export function system_info() {
	let info = ubus.call('system', 'info');

	delete info.root;
	delete info.swap;
	delete info.tmp;

	return info;
};

export function network_devices() {
	let status = ubus.call('network.device', 'status');
	let devices = {};

	for (let k, v in capabilities.network)
		for (let dev in v)
			if (status[dev]) {
				devices[dev] = {};
				for (let p in [ 'carrier', 'speed' ])
					devices[dev][p] = status[dev][p] || false;
				for (let p in [ 'tx_bytes', 'tx_packets', 'rx_bytes', 'rx_packets' ])
					devices[dev][p] = status[dev]['statistics'][p];
			}
	return devices;
};

export function fingerprints() {
	let data = ubus.call('fingerprint', 'list');
	let fingerprints = {};

	for (let k, v in data) {
		fingerprints[k] = {};
		for (let prop in [ 'device_name', 'vendor', 'device', 'class' ])
			if (v[prop])
				fingerprints[k][prop] = v[prop][0][0];
	}

	return fingerprints;
};

export function wifi_clients() {
	let status = ubus.call('network.wireless', 'status');
	let clients = {};

	for (let radio in status)
		for (let iface in status[radio].interfaces) {
			let ssid = ubus.call('hostapd.' + iface.ifname, 'get_status').ssid;
			for (let client, data in ubus.call('hostapd.' + iface.ifname, 'get_clients').clients)
				clients[client] = {
					ssid,
					bytes: data.bytes,
					packets: data.bytes,
					signal: data.signal,
					bytes: data.bytes,
				};
			}
	return clients;
};

export function neigh_table() {
	let dump = rtnl.request(rtnl.const.RTM_GETNEIGH, rtnl.const.NLM_F_DUMP);
	let neigh = {};

	for (let n in dump) {
		if (n.dev == 'lo' || !n.lladdr || !n.dst)
			continue;
		if (split(n.dst || '', '.')[0] == '224')
			continue;
		if (split(n.dst || '', ':')[0] == 'ff02')
			continue;
		neigh[n.lladdr] ??= { dev: n.dev };
		switch(n.family) {
		case 2:
			neigh[n.lladdr].ipv4 ??= [];
			push(neigh[n.lladdr].ipv4, n.dst);
			break;
		case 10:
			neigh[n.lladdr].ipv6 ??= [];
			push(neigh[n.lladdr].ipv6, n.dst);
			break;
		}
	}
	
	return neigh;
};

export function bridge_fdb() {
	let dump = rtnl.request(rtnl.const.RTM_GETNEIGH, rtnl.const.NLM_F_DUMP, { family: rtnl.const.AF_BRIDGE });
	let fdb = {};

	for (let n in dump)
		fdb[n.lladdr] = n.dev;

	return fdb;
};

export function dump_clients() {
	let neigh = neigh_table();
	let fdb = bridge_fdb();
	let wifi = wifi_clients();
	let fingerprint = fingerprints();
	let clients = {};

	for (let m, n in neigh) {
		clients[m] = {};
		if (n.ipv4)
			clients[m].ipv4 = n.ipv4;
		if (n.ipv6)
			clients[m].ipv6 = n.ipv6;
		clients[m].dev = fdb[m] || n.dev;
		if (wifi[m])
			clients[m].wifi = wifi[m];
		if (fingerprint[m])
			clients[m].info = fingerprint[m];
	}

	return clients;
};

export function dump_ssids() {
	let status = ubus.call('network.wireless', 'status');
	let ssids = {};

	for (let radio in status)
		for (let iface in status[radio].interfaces) {
			let hapd = ubus.call('hostapd.' + iface.ifname, 'get_status');
			ssids[iface.ifname] = {
				bssid: hapd.bssid,
				ssid: hapd.ssid,
				freq: hapd.freq,
				channel: hapd.channel,
				band: status[radio].config.band
			};
		}
	return ssids;
};

