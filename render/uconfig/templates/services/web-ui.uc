{%
let interfaces = services.lookup_interfaces("web-ui");
let enable = length(interfaces);
services.set_enabled("uconfig-server", !!enable);
if (!enable)
	return;

for (let interface in interfaces):
	let name = ethernet.calculate_name(interface);
%}

add firewall rule
set firewall.@rule[-1].name='Allow-http-{{ name }}'
set firewall.@rule[-1].src='{{ name }}'
set firewall.@rule[-1].dest_port='{{ 80 }}'
set firewall.@rule[-1].proto='tcp'
set firewall.@rule[-1].target='ACCEPT'

add firewall rule
set firewall.@rule[-1].name='Allow-https-{{ name }}'
set firewall.@rule[-1].src='{{ name }}'
set firewall.@rule[-1].dest_port='{{ 443 }}'
set firewall.@rule[-1].proto='tcp'
set firewall.@rule[-1].target='ACCEPT'
{% endfor %}
