<?php

class Config {

	// Config property keys
  	const ENV = "env";  	
  	const SERVER_NAME = "db_server";
  	const USER_NAME = "username";
  	const PASSWORD = "password";

	// Table name keys	
	const FB_USER_ACCOUNTS_TABLE = "fb_user_account_table";
	const RECIPES_TABLE =  "recipes_table";
	const RECIPE_INGREDIENTS_TABLE = "recipe_ingredients_table";
	const RECIPE_INSTRUCTIONS_TABLE = "recipe_instructions_table";
	const IMAGES_TABLE = "images_table";
	const IMAGE_BLOBS_TABLE = "image_blobs_table";

	private $configs = array();
  	private $recipes_database = "iosrecip_ENV";
	private $tables = array(
		self::FB_USER_ACCOUNTS_TABLE => "fb_user_accounts",
		self::RECIPES_TABLE => "recipes",
		self::RECIPE_INGREDIENTS_TABLE => "recipe_ingredients",
		self::RECIPE_INSTRUCTIONS_TABLE => "recipe_instructions",
		self::IMAGES_TABLE => "images",
		self::IMAGE_BLOBS_TABLE => "image_blobs"
	);

	function __construct() {		
		$file = fopen("../config.yaml", "r");
		if ($file) {
		    while (($line = fgets($file)) !== false) {		        
		        $property = explode(":", $line);
		        $key = trim($property[0]);
		        $value = trim($property[1]);
		        $this->configs[$key] = $value;
		    }

		    $this->recipes_database = str_replace("ENV", strtoupper($this->configs[self::ENV]), $this->recipes_database);
		    fclose($file);
		} 
   } 

   function print_configs() {
		foreach($this->configs as $key => $value) {
			echo $key . " => " . $value . "<br>";	
		}
   }

   function print_tables() {
   		echo $this->recipes_database . "<br>";
		foreach($this->tables as $key => $value) {
			echo $key . " => " . $value . "<br>";	
		}
   }

   function get_config($property_name) {
   		if(!array_key_exists($property_name, $this->configs)) {
   			return "";
   		}   		
   		return $this->configs[$property_name];   		
   }

   function get_table($table_name) {
   		if(!array_key_exists($table_name, $this->tables)) {
   			return "";
   		}   		
   		return $this->recipes_database . "." . $this->tables[$table_name]; 
   }

}

?>