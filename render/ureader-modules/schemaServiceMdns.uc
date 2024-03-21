function moduleServiceMdns(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseAdditionalHostnames(location, value, errors) {
			if (type(value) == "array") {
				function parseItem(location, value, errors) {
					if (type(value) != "string")
						push(errors, [ location, "must be of type string" ]);

					return value;
				}

				return map(value, (item, i) => parseItem(location + "/" + i, item, errors));
			}

			if (type(value) != "array")
				push(errors, [ location, "must be of type array" ]);

			return value;
		}

		if (exists(value, "additional-hostnames")) {
			obj.additional_hostnames = parseAdditionalHostnames(location + "/additional-hostnames", value["additional-hostnames"], errors);
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

return {
	validate: function(location, value, errors) {
		return moduleServiceMdns(location, value, errors);
	}
};
