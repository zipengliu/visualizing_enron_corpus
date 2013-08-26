var matrix = [],
	g_name_mapping = [],
	g_emails = {},
	g_start_date = new Date(2001, 10, 1),
	g_end_date = new Date(2001, 11, 31, 12, 59, 59);

function cal_matrix(len, start_date, end_date) {
	// initialize matrix
	for (var i = 0; i < len; i++) {
		matrix[i] = [];
		for (var j = 0; j < len; j++) matrix[i][j] = 0;
	}
	start = Date.parse(start_date);
	end = Date.parse(end_date);
	for (var person in g_emails) {
		var person_id = parseInt(person)
		for (var i in g_emails[person]["recv"]) {
			mail = g_emails[person]["recv"][i];
			d = Date.parse(mail["Date"]);
			if (mail.hasOwnProperty("XFrom") && mail["XFrom"] != null && parseInt(mail["XFrom"]) != person_id && start <= d && d <= end) {
				matrix[parseInt(mail["XFrom"])][person_id] += 2;
				matrix[person_id][parseInt(mail["XFrom"])] += 2;
			}
		}
	}
}

function to_array(hash) {
	arr = [];
	for (var id in hash) 
		arr[parseInt(id)] = hash[id];
	return arr;
}

function print_matri(matrix) {
	var table = d3.select("body")
		.append("table")
		.attr("border", "1");

	var rows = table.selectAll("tr")
	.data(matrix)
	.enter()
	.append("tr");

	var cells = rows.selectAll("td")
	.data(function(row) { return row; })
	.enter()
	.append("td")
	.text(function(d) { return d; });
}

function groupTicks(d) {
	return {
		angle: (d.endAngle - d.startAngle) / 2,
		index: d.index
	};
}

function highlight(mode) {
	if (mode == 0) {
		return function(d, i) {
			d3.select("body").select("#chord-graph").select("svg").select("g").selectAll(".chord path")
				.filter(function(d) { return d.source.index != i && d.target.index != i; })
				.transition()
				.style("opacity", 0.05);
			d3.select("body").select("#chord-graph").select("svg").select("g").selectAll(".chord path")
				.filter(function(d) { return d.source.index == i || d.target.index == i; })
				.transition()
				.style("fill", "#ff0700")
				.style("stroke", "#ff0700")
				.style("stroke-width", "1.5px");
		};
	} else {
		return function(d, i) {
			d3.select("body").select("#chord-graph").select("svg").select("g").selectAll(".chord path")
				.filter(function(d) { return d.source.index != i && d.target.index != i; })
				.transition()
				.style("opacity", 1);
			d3.select("body").select("#chord-graph").select("svg").select("g").selectAll(".chord path")
				.filter(function(d) { return d.source.index == i || d.target.index == i; })
				.transition()
				.style("opacity", 1)
				.style("fill", "#3415b0")
				.style("stroke-width", "0");
		};

	}
}

function visualize(matrix, name_mapping) {
	var width = 900,
		height = 1000,
		innerRadius = Math.min(width, height) * .38,
		outerRadius = innerRadius * 1.05;

	var svg = d3.select("body")
				.select("#chord-graph")
				.append("svg")
				.attr("width", width)
				.attr("height", height)
				.append("g")
				.attr("transform", "translate(" + width / 2 + "," + height / 2 + ")");
	var chord = d3.layout.chord()
		.padding(.03)
		.sortSubgroups(d3.descending)
		.matrix(matrix);

	svg.append("g")
		.attr("class", "chord")
		.selectAll("path")
		.data(chord.chords)
		.enter().append("path")
		.attr("d", d3.svg.chord().radius(innerRadius))
		.style("opacity", 1)
		.attr("fill", "#3415b0");

	svg.append("g")
		.selectAll("g")
		.data(chord.groups)
		.enter()
		.append("path")
		.style("fill", "#7d71db")
		.attr("d", d3.svg.arc().innerRadius(innerRadius).outerRadius(outerRadius))
		.on("mouseover", highlight(0))
		.on("mouseout", highlight(1));

	var ticks = svg.append("g").selectAll("g")
		.data(chord.groups)
		.enter().append("g")
		.attr("transform", function(d) {
			return "rotate(" + ((d.endAngle + d.startAngle) / 2 * 180 / Math.PI - 90) + ")"
			+ "translate(" + outerRadius + ",0)";
		})
		.append("text")
		.attr("x", 8)
		.attr("dy", ".35em")
		.attr("transform", function(d) { return (d.endAngle + d.startAngle) / 2 > Math.PI ? "rotate(180)translate(-16)" : null; })
		.style("text-anchor", function(d) { return (d.endAngle + d.startAngle) / 2 > Math.PI ? "end" : null; })
		.style("font-size", "10px")
		.text(function(d) { return name_mapping[d.index]; })
		.on("mouseover", highlight(0))
		.on("mouseout", highlight(1));
}

function update_vis(matrix, name_mapping) {
	d3.select("#chord-graph").select("svg").remove();
	visualize(matrix, name_mapping);
}

d3.json("name_mapping.json", function(name_mapping) {
	g_name_mapping = to_array(name_mapping)
	var len = g_name_mapping.length;
	d3.json("enron_filtered_sorted.json", function(emails) {
		g_emails = emails;
		alert("all data loaded!");
		cal_matrix(len, g_start_date, g_end_date);

		visualize(matrix, g_name_mapping);
	});	
});
