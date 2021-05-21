model Basin

import '../species/Crop.gaml'
import '../species/Field.gaml'
import '../species/WaterSource.gaml'
import '../species/Harvest.gaml'

global {
	
	geometry shape <- shape_file("../includes/shapes/bacia_samambaia.shp") as geometry; //delimitating simulation area
	float step <- 1 #day;
    
    int cycle_count <- 0 update: update_cycle_count();//cycle count of each simulation (for multiple simulations)
    float supply_inf <- 1.0;//<- rnd(0.85,1.15) update:update_parameter();
    float number; //random number generated for each execution
    float price_inf <- 1.0;//update:update_parameter(); //influence parameter of crops monthly prices 
    float demand_inf <- 1.0;//update:update_parameter(); //influence parameter of demand
    float rain_inf <- 1.0;//update:update_parameter(); //influence parameter of rain 
    float evp_inf <- 1.0;// update:update_parameter(); //influence parameter of evapotranspiration
            
    action update_cycle_count type: int {//updates cycle count every 1338 runs
    	if (mod(cycle,1338) != 0) {
    		return cycle_count + 1;
    	}else{
    		return 0;
    	}
    }  
        
    action update_parameter type:float { // updates random number generated for each execution of n repetitions
    	if (cycle_count = 0){
    		number <- rnd(0.85,1.0);
    		return number;
    	}else{
    		return number;
    	}
    }
       
	float pumping_cost <- 0.0002;
	
	list<Crop> crops;
	list<WaterSource> water_sources;
	list global_monthly_data;

	float daily_water_demand update: calculate_daily_water_demand();
	float total_water_demand update: total_water_demand + daily_water_demand;
	
	int year_count update: floor(cycle_count / 360) as int;
	int month_count <- 0 update: floor(cycle_count / 30) as int;
	int month_of_year <- 1 update: mod(month_count + 1, 12); // 1 to 12

	list<float> total_production <- list_with(9, 0.0);
	list<float> total_revenue <- list_with(9, 0.0);
	
	action calculate_daily_water_demand type: float {
		return sum(collect(water_sources, each.daily_demand));
	}
	
	float price_tolerance_base <- 0.05;
	float price_tolerance_per_field <- 0.005;
	
	matrix monthly_prices <- csv_file("../includes/data/monthly_prices.csv") as matrix;
	matrix monthly_prices_only <- csv_file("../includes/data/monthly_prices_only.csv") as matrix; //only monthly prices
	matrix monthly_prices_inf update: price_inf*monthly_prices_only as matrix; //monthly prices with price_inf parameter applied
		
	matrix daily_weather <- csv_file("../includes/data/daily_weather.csv") as matrix;
	matrix monthly_weather <- csv_file("../includes/data/monthly_weather.csv") as matrix;
	            
	float max_temp update: daily_weather[2, cycle_count] as float;
	float min_temp update: daily_weather[3, cycle_count] as float;

	float daily_rain_inf update: calculate_daily_rain(); //daily_rain with rain_inf applied
	
	float real_daily_rain update: daily_weather[1, cycle_count];
	
	action calculate_daily_rain type: float { 
		float daily_rain <- daily_weather[1, cycle_count] as float;
		float daily_rain_inf <- daily_rain*rain_inf as float; //rain_inf is applied
		return daily_rain_inf;
	}

	float evapotranspiration update: calculate_evapotranspiration();

	action calculate_evapotranspiration type: float {
		return evp_inf*0.00017136 * (max_temp - min_temp) ^ (0.96) * (((max_temp + min_temp) / 2) + 17.38); //evp_inf is applied
	}

	init {
		create Soy;
		create Cotton;
		create Corn;
		create Bean;
		create Potato;
		create Garlic;
		create Onion;
		create Tomato;
		add Soy[0] to: crops;
		add Corn[0] to: crops;
		add Cotton[0] to: crops;
		add Bean[0] to: crops;
		add Potato[0] to: crops;
		add Garlic[0] to: crops;
		add Onion[0] to: crops;
		add Tomato[0] to: crops;

		create CorregoRato;
		create SamambaiaNorte;
		create SamambaiaSul;
		add CorregoRato[0] to: water_sources;
		add SamambaiaNorte[0] to: water_sources;
		add SamambaiaSul[0] to: water_sources;
		
		create Field from: shape_file("../includes/shapes/pivos_bacia_2016.shp");
		
		// relate fields to water sources
		loop field over: Field {
			loop water_source over: water_sources {
				if (water_source overlaps field) {
					field.water_source <- water_source;
					add field to: water_source.irrigated_fields;
				}
			}
		}
		
		create Farmer number: 3 { // farmers in corrego do rato
			number_of_fields <- 10;
			price_tolerance <- price_tolerance_base + number_of_fields * price_tolerance_per_field;
			location <- any_location_in(10 around Field(246)); // field number is defined as the FID in shapefile attribute table
			max_simultaneous_crops <- 2;
			
		}
		create Farmer number: 5 { // farmers in samambaia norte
			number_of_fields <- 30;
			price_tolerance <- price_tolerance_base + number_of_fields * price_tolerance_per_field;
			location <- any_location_in(10 around Field(9)); 
			max_simultaneous_crops <- 3;
			
		}
		create Farmer number: 2 { // farmers in samambaia sul
			number_of_fields <- 50;
			price_tolerance <- price_tolerance_base + number_of_fields * price_tolerance_per_field;
			location <- any_location_in(10 around Field(118));
			max_simultaneous_crops <- 5;
		}
				
		// relates farmers to fields
		loop farmer over: Farmer {
			list<Field> empty_fields <- Field where (each.farmer = nil);
			farmer.fields <- empty_fields closest_to (farmer, farmer.number_of_fields);
			farmer.my_area <- sum(collect(farmer.fields, each.field_area));
			loop field over: farmer.fields {
				field.farmer <- farmer;
			}
		}
	}

	reflex daily_data{	//saves daily_data in a csv file
			
		save[	
			(daily_weather[0, cycle_count]),
			sum(Farmer collect (each.cash)) / 1000000000,
			sum(collect(water_sources, each.daily_demand))/ 1000000,
			sum(collect(water_sources, each.daily_supply))/ 1000000,
			total_production[0]/1000000000,
			total_production[1]/1000000000,
			total_production[2]/1000000000,
			total_production[3]/1000000000,
			total_production[4]/1000000000,
			total_production[5]/1000000000,
			total_production[6]/1000000000,
			total_production[7]/1000000000 	
			] to: "../results/noinf/daily_results.csv" type: "csv" rewrite:false;
		}	
	
		
		/*reflex end_simulation when: cycle = 2*1338 { //pauses simulation for GUI Experiments
	
		do pause;
		
		}*/
}