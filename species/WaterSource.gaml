model WaterSource

import '../models/Main.gaml'

species WaterSource {
	float daily_supply; //dayly limit to withdraw (Q95 of the day)
	float daily_demand update: calculate_daily_demand();
	float total_demand update: total_demand + daily_demand;
	float monthly_supply;
	matrix daily_weather <- csv_file("../includes/data/daily_weather.csv") as matrix;
	int cycle_count <- 0 update: update_cycle_count();//cycle count of each simulation (for multiple simulations)
	int current_day <- 1 update: update_current_day;
          
    action update_cycle_count type: int {//updates cycle count every 1338 runs
    	if (mod(cycle,1338) != 0) {
    		return cycle_count + 1;
    	} else {
    		return 0;
    	}
    }
	
	action update_current_day type:int {
		string date_today <- daily_weather[0, cycle_count];
		list list_date_today <- date_today split_with ('/');
		write type_of(list_date_today[0]);
		return list_date_today[0] as int;
	}
	
	matrix flow_data;
	list<Field> irrigated_fields;
	action calculate_daily_demand type: float {
		if (irrigated_fields = nil) { return 0; }
		return sum(collect(irrigated_fields, each.water_demand));
	}
	reflex calculate_daily_supply {
		float monthly_flow <- flow_data[1, month_of_year] as float;
		daily_supply <- monthly_flow * shape.area * 0.0864 * supply_inf;
	}
}

species CorregoRato parent: WaterSource {
	geometry shape <- shape_file('../includes/shapes/cor_rato.shp') as geometry;
	matrix flow_data <- csv_file('../includes/data/flow_rato.csv') as matrix;
	aspect {
		draw shape color: #lightgreen border: #black;
	
	}
}

species SamambaiaNorte parent: WaterSource {
	geometry shape <- shape_file('../includes/shapes/sam_norte.shp') as geometry;
	matrix flow_data <- csv_file('../includes/data/flow_norte.csv') as matrix;
	aspect {
		draw shape color: #lightyellow border: #black;
	
	}
}

species SamambaiaSul parent: WaterSource {
	geometry shape <- shape_file('../includes/shapes/sam_sul.shp') as geometry;
	matrix flow_data <- csv_file('../includes/data/flow_sul.csv') as matrix;
		aspect {
		draw shape color: #lightblue border: #black;
	}
}

