<?php

include "constants.php";

const RETRIEVE_RECIPE_SQL = "SELECT recipes.recipe_id, recipes.name, recipes.description, images.image_url FROM " . Constants::RECIPES_TABLE . 
							" LEFT OUTER JOIN " . Constants::IMAGES_TABLE . " on recipes.image_id = images.image_id" .
							" WHERE recipes.fb_user_id = ?" . 
							" ORDER BY recipes.recipe_id ASC";
const RETRIEVE_INGREDIENTS_SQL = "SELECT * FROM " . Constants::RECIPE_INGREDIENTS_TABLE . " WHERE recipe_id IN (?) ORDER BY ingredient_id asc";
const RETRIEVE_INSTRUCTIONS_SQL = "SELECT * FROM " . Constants::RECIPE_INSTRUCTIONS_TABLE . " WHERE recipe_id IN (?) ORDER BY instruction_id asc";

// Create connection
$conn = mysqli_connect(Constants::SERVER_NAME, Constants::USER_NAME, Constants::PASSWORD);

// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
} 

// Take the data from the request
$data = file_get_contents('php://input');
$json = json_decode($data, true);

// Grab JSON data
$fb_user_id = $json["fb_user_id"];

// Prepare statement to retrieve recipes
$retrieve_recipes_ps = $conn->prepare(RETRIEVE_RECIPE_SQL);
$retrieve_recipes_ps->bind_param("s", $fb_user_id);

// Retrieve recipes
if(!$retrieve_recipes_ps->execute()) {
	die("There was an error retrieving the recipes: " . $retrieve_recipes_ps->error);
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
	$retrieve_ingredients_sql = str_replace("?", $recipe_ids_string, RETRIEVE_INGREDIENTS_SQL);
	$result = $conn->query($retrieve_ingredients_sql);
	while($row = $result->fetch_assoc()) {

		// Retrieve ingredientId and ingredient name
		$ingredient = array("ingredient_id" => intval($row["ingredient_id"]), "ingredient" => $row["ingredient"]);

		// Add to ingredients array for appropriate recipe
		array_push($recipes[$row["recipe_id"]]["ingredients"], $ingredient);
	}

	// Retrieve instructions
	$retrieve_instructions_sql = str_replace("?", $recipe_ids_string, RETRIEVE_INSTRUCTIONS_SQL);
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