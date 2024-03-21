{%-
	if (!services.is_present("umdns"))
		return;

	let interfaces = services.lookup_interfaces("mdns");
	let enable = length(interfaces);
	services.set_enabled("umdns", !!enable ? 'reload' : false);
	if (!enable)
		return;

	let hosts = {
		[ global.capabilities.serial + ".local" ]: {
			"hostname": global.capabilities.serial + ".local"
		}
	};
	for (let hostname in mdns?.additional_hostnames || [])
		hosts[hostname + ".local"] = {
			hostname: hostname + ".local" 
		};
	fs.writefile('/etc/umdns/uconfig.json', hosts);
%}

# Configure MDNS
{%	for (let interface in interfaces): %}
add_list umdns.@umdns[0].network={{ s(ethernet.calculate_name(interface)) }}
{%	endfor
	for (let interface in interfaces):
		let name = ethernet.calculate_name(interface);
%}

# Configure MDNS firewall
add firewall rule
set firewall.@rule[-1].name='Allow-mdns-{{ name }}'
set firewall.@rule[-1].src='{{ name }}'
set firewall.@rule[-1].dest_port='5353'
set firewall.@rule[-1].proto='udp'
set firewall.@rule[-1].target='ACCEPT'
{%	endfor %}
