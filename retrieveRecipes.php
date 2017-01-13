<?php

include "constants.php";

const RETRIEVE_RECIPE_SQL = "SELECT * FROM " . Constants::RECIPES_TABLE . " ORDER BY recipe_id asc";
const RETRIEVE_INGREDIENTS_SQL = "SELECT * FROM " . Constants::RECIPE_INGREDIENTS_TABLE . " ORDER BY ingredient_id asc";
const RETRIEVE_INSTRUCTIONS_SQL = "SELECT * FROM " . Constants::RECIPE_INSTRUCTIONS_TABLE . " ORDER BY instruction_id asc";

// Create connection
$conn = mysqli_connect(Constants::SERVER_NAME, Constants::USER_NAME, Constants::PASSWORD);

// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
} 

// Retrieve recipes
$result = $conn->query(RETRIEVE_RECIPE_SQL);
$recipes = array();

// Create map of recipe id to recipe json respresentation
while ($row = $result->fetch_assoc()) {
    $recipes[$row["recipe_id"]] = array(   
    	"recipe_id" => $row["recipe_id"], 	
    	"name" => $row["name"], 
    	"description" => (is_null($row["description"])) ? "" : $row["description"], 
    	"image_id" => $row["image_id"], 
    	"ingredients" => array(), // initialize empty ingredients 
    	"instructions" => array() // initialize empty instructions
    );



}

if(count($recipes) > 0) {

	// Retrieve ingredients
	$result = $conn->query(RETRIEVE_INGREDIENTS_SQL);
	while($row = $result->fetch_assoc()) {

		// Retrieve ingredientId and ingredient name
		$ingredient = array("ingredient_id" => $row["ingredient_id"], "ingredient" => $row["ingredient"]);

		// Add to ingredients array for appropriate recipe
		array_push($recipes[$row["recipe_id"]]["ingredients"], $ingredient);
	}

	// Retrieve instructions
	$result = $conn->query(RETRIEVE_INSTRUCTIONS_SQL);
	while($row = $result->fetch_assoc()) {

		// Retrieve instructionId and instruction 
		$instruction = array("instruction_id" => $row["instruction_id"], "instruction" => $row["instruction"]);

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