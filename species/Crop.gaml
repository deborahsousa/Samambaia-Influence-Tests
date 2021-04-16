model Crop

import '../models/Main.gaml'

species Crop {
	int crop_number <- 0; // references price table
	string name;
	list<int> available_months; // calendar/availablecrop
	float productivity; //  Kg / m²
	float production_cost <- 0.0; //  $ / m²
	int harvest_duration <- stage_change_days[3];
	float daily_cost;
	float sell_price update: monthly_prices_inf[month_count, crop_number];
	float dry_penalty; // % of productivity loss under dry production (no irrigation)
	list<int> stage_change_days <- [1, 1, 1, 1];
	list<float> coefficient; // crop coefficient of evapotransipiration
	rgb display_color;

	action calculate_expected_water_demand type: float {
		float crop_water_demand <- 0.0;
		int initial_day <- year_count > 0 ? cycle_count -360 : cycle_count; // use previous year data if available, current year data otherwise
		int i <- 0;
		// gets water demand for each cycle
		loop times: 4 {
			int stage_duration <- i = 0 ? stage_change_days[i] : stage_change_days[i] - stage_change_days[i-1];
		 	int reference_day <- i = 0 ? initial_day : initial_day + stage_change_days[i];
		 	int reference_month <- floor(reference_day / 30) as int;
		 	float reference_evapotransipration <- calculate_evapotranspiration(reference_month);
		 	float stage_water_demand <- reference_evapotransipration * coefficient[i] * stage_duration;
		 	float rain_discount <- calculate_expected_rain(reference_month, stage_duration);
		 	stage_water_demand <- max(stage_water_demand - rain_discount, 0);
		 	crop_water_demand <- crop_water_demand + stage_water_demand;
			i <- i + 1;
		}
		return crop_water_demand;
	}

	action  calculate_expected_revenue type: float {
		int initial_day<- year_count > 0 ? cycle_count - 360 : cycle_count;
		int harvest_day <- initial_day + stage_change_days[3];
		int harvest_month <- floor(harvest_day / 30) as int;
		float expected_sell_price <- float(monthly_prices_inf[harvest_month, crop_number]);
		float expected_revenue <- expected_sell_price * productivity;
		return expected_revenue;
	}

	action calculate_evapotranspiration(int month) type: float {
		float month_min_temp <- monthly_weather[2, month] as float; 
		float month_max_temp <- monthly_weather[1, month] as float;
		return evp_inf*0.00017136 * (month_max_temp - month_min_temp) ^ (0.96) * (((month_max_temp + month_min_temp) / 2) + 17.38);
	}

	action calculate_expected_rain (
		int reference_month,
		int stage_duration
	) type: float {
		// discounts month average rain * stage duration * (1 - rain variation coeficient)
	 	float expected_rain <- rain_inf * float(monthly_weather[4, reference_month]) * stage_duration; //rain_inf is applied
	 	float rain_variation <- monthly_weather[5, reference_month] as float;
	 	float rain_discount <- expected_rain * (1 - rain_variation);
	 	return rain_discount;
	}

	action calculate_expected_profit type: float {
		float expected_water_demand <- calculate_expected_water_demand();
		float water_cost <- expected_water_demand * pumping_cost;
		float total_cost <- water_cost + production_cost;
		float expected_revenue <- calculate_expected_revenue();
		return (expected_revenue - total_cost) / harvest_duration;
	}
}

species Soy parent: Crop {
	int crop_number <- 0;
	string name <- 'Soja';
	list<int> available_months <- [10, 11, 12];
	float productivity <- 0.42;
	float production_cost <- 0.4384;
	float dry_penalty <- 0.26;
	list<int> stage_change_days <- [15, 95, 115, 120];
	float daily_cost <- production_cost / stage_change_days[3];
	int harvest_duration <- stage_change_days[3];
	list<float> coefficient <- [0.6, 0.75, 1.08, 0.75];
	rgb display_color <- #darkblue;
}

species Corn parent: Crop {
	int crop_number <- 1;
	string name <- 'Milho';
	list<int> available_months <- [2, 3, 9, 10, 11];
	float productivity <- 1.26;
	float production_cost <- 0.5119;
	float dry_penalty <- 0.26;
	list<int> stage_change_days <- [20, 54, 94, 120];
	float daily_cost <- production_cost / stage_change_days[3];
	int harvest_duration <- stage_change_days[3];
	list<float> coefficient <- [0.6, 0.78, 1.13, 0.88];
	rgb display_color <- #darkcyan;
}

species Cotton parent: Crop {
	int crop_number <- 2;
	string name <- 'Algodão';
	list<int> available_months <- [1, 2, 10, 11, 12];
	float productivity <- 0.45;
	float production_cost <- 1.0564;
	float dry_penalty <- 0.62;
	list<int> stage_change_days <- [15, 85, 140, 150];
	float daily_cost <- production_cost / stage_change_days[3];
	int harvest_duration <- stage_change_days[3];
	list<float> coefficient <- [0.6, 0.75, 1.15, 0.85];
	rgb display_color <- #darkgreen;
}

species Bean parent: Crop {
	int crop_number <- 3;
	string name <- 'Feijão';
	list<int> available_months <- [3, 4, 5, 6, 10, 11, 12];
	float productivity <- 0.3;
	float production_cost <- 0.4090;
	float dry_penalty <- 0.20;
	list<int> stage_change_days <- [15, 60, 80, 90];
	float daily_cost <- production_cost / stage_change_days[3];
	int harvest_duration <- stage_change_days[3];
	list<float> coefficient <- [0.6, 0.75, 1.13, 0.7];
	rgb display_color <- #darkkhaki;
}

species Potato parent: Crop {
	int crop_number <- 4;
	string name <- 'Batata';
	list<int> available_months <- [3, 4];
	float productivity <- 6.0;
	float production_cost <- 1.1309;
	float dry_penalty <- 0.50;
	list<int> stage_change_days <- [15, 95, 115, 120];
	float daily_cost <- production_cost / stage_change_days[3];
	int harvest_duration <- stage_change_days[3];
	list<float> coefficient <- [0.6, 0.75, 1.13, 0.8];
	rgb display_color <- #darkmagenta;
}

species Garlic parent: Crop {
	int crop_number <- 5;
	string name <- 'Alho';
	list<int> available_months <- [2, 3];
	float productivity <- 1.6;
	float production_cost <- 5.7652;
	float dry_penalty <- 0.75;
	list<int> stage_change_days <- [24, 97, 150, 160];
	float daily_cost <- production_cost / stage_change_days[3];
	int harvest_duration <- stage_change_days[3];
	list<float> coefficient <- [0.6, 0.85, 1.05, 0.75];
	rgb display_color <- #darkorange;
}

species Onion parent: Crop {
	int crop_number <- 6;
	string name <- 'Cebola';
	list<int> available_months <- [1, 2];
	float productivity <- 6.0;
	float production_cost <- 1.4655;
	float dry_penalty <- 0.17;
	list<int> stage_change_days <- [20, 50, 90, 130];
	int harvest_duration <- stage_change_days[3];
	list<float> coefficient <- [0.6, 0.75, 1.03, 0.88];
	rgb display_color <- #darkorchid;
}

species Tomato parent: Crop {
	int crop_number <- 7;
	string name <- 'Tomate';
	list<int> available_months <- [2, 3, 4, 5, 6];
	float productivity <- 9.5;
	float production_cost <- 2.2045;
	float dry_penalty <- 0.88;
	list<int> stage_change_days <- [28, 65, 112, 130];
	float daily_cost <- production_cost / stage_change_days[3];
	int harvest_duration <- stage_change_days[3];
	list<float> coefficient <- [0.6, 0.63, 0.85, 0.63];
	rgb display_color <- #darkred;
}
