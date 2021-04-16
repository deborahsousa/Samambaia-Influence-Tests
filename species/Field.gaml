model field

import '../models/Main.gaml'
import './Farmer.gaml'
import './WaterSource.gaml'
import './Harvest.gaml'

species Field {
	Farmer farmer; //farmer of cropfield
	WaterSource water_source;
	Harvest current_harvest;
	Crop previous_crop;
	float field_area <- shape.area;
	float water_demand update: calculate_water_demand();
	float daily_cost <- 0.0 update: update_daily_cost();
	float production;
	float revenue;
	int dry_count <- 0;
	
	aspect {
		draw shape
			color: current_harvest != nil ? current_harvest.crop.display_color : #darkgrey
		;
		draw copy_between(farmer.name, 6, length(farmer.name))
			color: #white
			anchor: #center
			font: font("Helvetica", 13, #bold)
		;
	}

	action calculate_water_demand type: float {
		if (current_harvest = nil) { return 0; }
		return current_harvest.current_water_demand * field_area;
	}

	action create_new_harvest(Crop crop) {
		create Harvest returns: harvest;
		current_harvest <- harvest[0];
		current_harvest.crop <- crop;
	}
	
	action update_daily_cost type: float {
		float cost <- 0.01 * shape.area;
		if (current_harvest != nil) {
			cost <- water_demand * pumping_cost + current_harvest.crop.daily_cost * shape.area;
		}
		return cost;
	}
	
	reflex reinitiate_variables { //reinitiates variables every 1338 days
		if (cycle_count = 1337){
			production <- 0.0;
			revenue <- 0.0;
			total_revenue[0] <- 0.0;	
    		total_revenue[1] <- 0.0;
    		total_revenue[2] <- 0.0;
    		total_revenue[3] <- 0.0;
    		total_revenue[4] <- 0.0;
    		total_revenue[5] <- 0.0;
    		total_revenue[6] <- 0.0;
    		total_revenue[7] <- 0.0;
    		total_production[0] <- 0.0;	
    		total_production[1] <- 0.0;
    		total_production[2] <- 0.0;
    		total_production[3] <- 0.0;
    		total_production[4] <- 0.0;
    		total_production[5] <- 0.0;
    		total_production[6] <- 0.0;
    		total_production[7] <- 0.0;
    	}
	}
	
	reflex harvest	
		when: current_harvest != nil and current_harvest.current_days >= current_harvest.crop.harvest_duration
	{
		int crop_num <- current_harvest.crop.crop_number;
		float production <- current_harvest.crop.productivity * shape.area;
		total_production[crop_num] <- total_production[crop_num] + production;

		float dry_rate <- dry_count / current_harvest.crop.harvest_duration;
		float dry_penalty <- dry_rate * current_harvest.crop.dry_penalty;

		float revenue <- current_harvest.crop.sell_price * production * (1 - dry_penalty);
		total_revenue[crop_num] <- total_revenue[crop_num] + revenue;
		farmer.cash <- farmer.cash + revenue;

		previous_crop <- current_harvest.crop;
		remove current_harvest.crop from: farmer.current_crops;
		ask current_harvest { do die; }
		current_harvest <- nil;
		dry_count <- 0;
	}
	
	reflex irrigate {
		if (water_demand <= water_source.daily_supply) {
			water_source.daily_supply <- water_source.daily_supply - water_demand;
		} else {
			dry_count <- dry_count + 1;
		}
	}
}
