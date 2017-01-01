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

while ($row = $result->fetch_assoc()) {
    $recipes[$row["recipe_id"]] = array(   
    	"recipe_id" => $row["recipe_id"], 	
    	"name" => $row["name"], 
    	"description" => $row["description"], 
    	"image_id" => $row["image_id"], 
    	"ingredients" => array(), 
    	"instructions" => array()
    	);

}

if(count($recipes) > 0) {

	// Retrieve ingredients
	$result = $conn->query(RETRIEVE_INGREDIENTS_SQL);
	$ingredients = array();
	while($row = $result->fetch_assoc()) {
		$ingredients[] = $row;
		$ingredient = array("ingredient_id" => $row["ingredient_id"], "ingredient" => $row["ingredient"]);
		array_push($recipes[$row["recipe_id"]]["ingredients"], $ingredient);
	}

	$result = $conn->query(RETRIEVE_INSTRUCTIONS_SQL);
	$instructions = array();
	while($row = $result->fetch_assoc()) {
		$instructions[] = $row;
		$instruction = array("instruction_id" => $row["instruction_id"], "instruction" => $row["instruction"]);
		array_push($recipes[$row["recipe_id"]]["instructions"], $instruction);
	}

}

$recipes_for_json = array("recipes" => array());
foreach($recipes as $recipe_id => $recipe) {
	array_push($recipes_for_json["recipes"], $recipe);
}

// Return the json representation of the data
echo json_encode($recipes_for_json);

// Close the connection
$conn->close();

?>