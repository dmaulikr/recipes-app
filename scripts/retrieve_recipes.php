<?php

include "config.php";
include "json_service.php";

$config = new Config();
$json_service = new JsonService();

$recipes_table = $config->get_table(Config::RECIPES_TABLE);
$recipe_ingredients_table = $config->get_table(Config::RECIPE_INGREDIENTS_TABLE);
$recipe_instructions_table = $config->get_table(Config::RECIPE_INSTRUCTIONS_TABLE);
$images_table = $config->get_table(Config::IMAGES_TABLE);


$retrieve_recipes_sql = "SELECT recipes.recipe_id, recipes.name, recipes.description, images.image_url FROM " . $recipes_table . 
							" LEFT OUTER JOIN " . $images_table . " on recipes.image_id = images.image_id" .
							" WHERE recipes.fb_user_id = ? and recipes.date_removed IS NULL" . 
							" ORDER BY recipes.recipe_id ASC";

$retrieve_ingredients_sql = "SELECT * FROM " . $recipe_ingredients_table . " WHERE recipe_id IN (?) AND date_removed IS NULL" . 
							" ORDER BY ingredient_id asc";
							
$retrieve_instructions_sql = "SELECT * FROM " . $recipe_instructions_table . " WHERE recipe_id IN (?) AND date_removed IS NULL" . 
							" ORDER BY instruction_id asc";


// Create connection
$conn = mysqli_connect($config->get_config(Config::SERVER_NAME), 
					$config->get_config(Config::USER_NAME), 
					$config->get_config(Config::PASSWORD));

// Check connection
if ($conn->connect_error) {
	echo $json_service->get_json_result("Connection failed: " . $conn->connect_error, false);
    die();
} 

// Take the data from the request
$data = file_get_contents('php://input');
$json = json_decode($data, true);

// Grab JSON data
$fb_user_id = $json["fb_user_id"];

// Prepare statement to retrieve recipes
$retrieve_recipes_ps = $conn->prepare($retrieve_recipes_sql);
$retrieve_recipes_ps->bind_param("s", $fb_user_id);

// Retrieve recipes
if(!$retrieve_recipes_ps->execute()) {
	echo $json_service->get_json_result("There was an error retrieving the recipes: " . $retrieve_recipes_ps->error, false);
	die();
}

$retrieve_recipes_ps->bind_result($recipe_id, $name, $description, $image_url);

// Create array of recipes and recipe ids, which we need to get ingredients and instructions
$recipes = array();
$recipe_ids = array();

// Create map of recipe id to recipe json respresentation
while ($retrieve_recipes_ps->fetch()) {
	array_push($recipe_ids, $recipe_id);
    $recipes[$recipe_id] = array(   
    	"recipe_id" => $recipe_id,    	
    	"name" => $name, 
    	"description" => (is_null($description)) ? "" : $description, 
    	"image_url" => (is_null($image_url)) ? "" : $image_url, 
    	"ingredients" => array(), // initialize empty ingredients 
    	"instructions" => array() // initialize empty instructions
    );
}

if(count($recipes) > 0) {

	// Convert recipe_ids array into string to use in sql 
	$recipe_ids_string = implode(",", $recipe_ids);

	// Retrieve ingredients
	$retrieve_ingredients_sql = str_replace("?", $recipe_ids_string, $retrieve_ingredients_sql);
	$result = $conn->query($retrieve_ingredients_sql);
	while($row = $result->fetch_assoc()) {

		// Retrieve ingredientId and ingredient name
		$ingredient = array("ingredient_id" => intval($row["ingredient_id"]), "ingredient" => $row["ingredient"]);

		// Add to ingredients array for appropriate recipe
		array_push($recipes[$row["recipe_id"]]["ingredients"], $ingredient);
	}

	// Retrieve instructions
	$retrieve_instructions_sql = str_replace("?", $recipe_ids_string, $retrieve_instructions_sql);
	$result = $conn->query($retrieve_instructions_sql);
	while($row = $result->fetch_assoc()) {

		// Retrieve instructionId and instruction 
		$instruction = array("instruction_id" => intval($row["instruction_id"]), "instruction" => $row["instruction"]);

		// Add to instructions array for appropriate recipe
		array_push($recipes[$row["recipe_id"]]["instructions"], $instruction);
	}

}

// Create json array of recipes
$recipes_for_json = array("recipes" => array());

// Push each recipe to array
foreach($recipes as $recipe_id => $recipe) {
	array_push($recipes_for_json["recipes"], $recipe);
}

// Return the json representation of the data
echo json_encode($recipes_for_json);

// Close the connection
$conn->close();

?>