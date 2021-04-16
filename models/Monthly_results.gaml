model Monthly_results

global {

	init{
		matrix daily_results <-file("../results/noinf/daily_results.csv") as matrix;
		matrix daily_weather <- csv_file("../includes/data/daily_weather.csv") as matrix;
		string current_month;
		string current_year;
		string current_month_date;
		int cycle_count <- 1;
		float daily_cash_datum;
		float daily_supply_datum;
		float daily_demand_datum;
		float monthly_cash_data;
		float monthly_supply_data;
		float monthly_demand_data;
		string month;
		string date_today <- daily_weather[0, cycle_count];
		list list_date_today <- date_today split_with ('/');
		
		string day <- list_date_today[0];
		string month <- list_date_today[1];
		string year <- list_date_today[2];
		
		current_month <- list_date_today[1];
		current_year <- list_date_today[2];		
		
				
		loop j from:1337 to:133800 step:1338 { 
				
			float last_production0 <- daily_results[4,j];
			float last_production1 <- daily_results[5,j];
			float last_production2 <- daily_results[6,j];
			float last_production3 <- daily_results[7,j];
			float last_production4 <- daily_results[8,j];
			float last_production5 <- daily_results[9,j];
			float last_production6 <- daily_results[10,j];
			float last_production7 <- daily_results[11,j];
			
			list last_production <- [last_production0, last_production1, last_production2, last_production3,last_production4,last_production5,last_production6, last_production7] ;
		
			float max_crop_production <- max(last_production);
			int max_crop_index <- last_production index_of max_crop_production ;
			
			remove index:max_crop_index from: last_production;
			float secondmax_production <- max(last_production);
			int secondmax_index <- last_production index_of secondmax_production;
			
			remove index:secondmax_index from: last_production;
			float thirdmax_production <- max(last_production);
			int thirdmax_index <- last_production index_of thirdmax_production;
	
			save [
			max_crop_index,
			max_crop_production,
			secondmax_index,
			secondmax_production,
			thirdmax_index,
			thirdmax_production
			] to: "../results/noinf/crop_results.csv" type: "csv" rewrite:false;
			}
				
		loop i from: 0 to: length(daily_results + 1) {
			date_today <- daily_results[0, i];
			list_date_today <- date_today split_with ('/');
			month <- list_date_today[1];
			
			if month = current_month {
				daily_cash_datum <- daily_results[1, i];
				monthly_cash_data <- monthly_cash_data + daily_cash_datum;
				daily_demand_datum <- daily_results[2, i];
				monthly_demand_data <- monthly_demand_data + daily_demand_datum;
				daily_supply_datum <- daily_results[3, i];
				monthly_supply_data <- monthly_supply_data + daily_supply_datum;
			} else {
				current_month_date <- current_month + '/' + current_year;		
			save [ 
				current_month_date,
				monthly_cash_data,	
				monthly_demand_data,
				monthly_supply_data
				] to: "../results/noinf/monthly_results.csv" type: "csv" rewrite:false;

			monthly_cash_data <- daily_results[1, i];
			monthly_demand_data <- daily_results[2, i];
			monthly_supply_data <- daily_results[3, i];
			date_today <- daily_results[0, i];
			list_date_today <- date_today split_with ('/');
			current_month <- list_date_today[1];
			current_year <- list_date_today[2];					
			}
		} 
	}
}
		