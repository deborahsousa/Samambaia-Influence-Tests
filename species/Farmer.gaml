model farmer

import './Crop.gaml'
import './Field.gaml'
import '../models/Main.gaml'

species Farmer {
	float cash;
	list<Crop> current_crops;
	list<Crop> previous_crops;
	list<Field> fields;
	int number_of_fields;
	int initial_sow_day <- rnd(30);
	float price_tolerance;
	int max_simultaneous_crops;
	list private_data;
	float my_area;
	
    reflex reinitiate_current_crops when: (cycle_count = 1337) {//returns to empty every 1338 runs
		current_crops <- [];
	}
	
	aspect {
		draw envelope(fields);
	}
	
	reflex update_crop when: (cycle_count >= initial_sow_day and empty(current_crops)) {	
		list<Crop> available_crops;
		list<Crop> not_previously_planted <- crops;
		loop previous over: previous_crops {
			remove previous from: not_previously_planted;
		}
		loop crop over: not_previously_planted {
			if (crop.available_months contains month_of_year) {
				add crop to: available_crops;
			}
		}
		
		loop while: should_plant_more() {
			Crop selected_crop <- get_highest_profit_crop(available_crops);
			if (selected_crop = nil) {
				break;
			}
			add selected_crop to: current_crops;
			remove selected_crop from: available_crops;				
		}
		
		previous_crops <- current_crops;
		
		if (!empty(current_crops)) {
			int crop_count <- length(current_crops);
			int i <- 0;
			int j <- 0;
			int fields_per_crop <- length(fields) / crop_count as int;
			if crop_count > 1 {
				loop times: crop_count - 1 {
					list<Field> crop_fields <- copy_between(fields, j, j + fields_per_crop);
					ask crop_fields {
						do create_new_harvest(myself.current_crops[i]);
					}
					j <- j + fields_per_crop;
					i <- i + 1;
				}				
			}
			list<Field> last_crop_fields <- copy_between(fields, j, length(fields));
			ask last_crop_fields {
				do create_new_harvest(myself.current_crops[i]);
			}			
		}		
	}
	
	
	reflex daily_payment {
		float daily_cost;
		loop field over: fields {
			if (field.current_harvest != nil) {
				if (cycle_count = 1337) { // reinitiates variable 'cash' every 1338 cycles
					cash <- 0;
    			} else {
					cash <- cash - field.daily_cost;
    			}
			}
		}
	}	
	
	action should_plant_more type: bool {
		return !is_within_tolerance(current_crops) and length(current_crops) < max_simultaneous_crops;
	}
	
	action is_within_tolerance(list<Crop> selected_crops) type: bool {
		if empty(selected_crops) { return false; }
		float fluctuation <- product_of(selected_crops, monthly_prices[44, each.crop_number] as float);
		return fluctuation < price_tolerance;
	}
	
	action get_highest_profit_crop(list<Crop> available_crops) type: Crop {
		float current_expected_profit <- 0.0;
		Crop result <- nil;
		loop crop over: available_crops {
			float crop_expected_profit <- crop.calculate_expected_profit();
			if (crop_expected_profit > current_expected_profit) {
				current_expected_profit <- crop_expected_profit;
				result <- crop;
			}
		}
		return result;
	}
}