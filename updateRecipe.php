<?php

include "constants.php";

const UPDATE_RECIPE_SQL = "UPDATE " . Constants::RECIPES_TABLE . " SET name = ?, description = ? WHERE recipe_id = ?";
const UPDATE_RECIPE_SQL_WITH_IMAGE = "UPDATE " . Constants::RECIPES_TABLE . " SET name = ?, description = ?, image_id = ? WHERE recipe_id = ?";
const UPDATE_INGREDIENTS_SQL = "UPDATE " . Constants::RECIPE_INGREDIENTS_TABLE . " SET ingredient = ? WHERE ingredient_id = ?";
const UPDATE_INSTRUCTIONS_SQL = "UPDATE " . Constants::RECIPE_INSTRUCTIONS_TABLE . " SET instruction = ? WHERE instruction_id = ?";

const INSERT_INGREDIENTS_SQL = "INSERT INTO " . Constants::RECIPE_INGREDIENTS_TABLE . " (recipe_id, ingredient) VALUES ";
const INSERT_INSTRUCTIONS_SQL = "INSERT INTO " . Constants::RECIPE_INSTRUCTIONS_TABLE . " (recipe_id, instruction) VALUES ";

// Create connection to sql
$conn = mysqli_connect(Constants::SERVER_NAME, Constants::USER_NAME, Constants::PASSWORD);

// Check connection
if ($conn->connect_error) {
	die("Connection failed: " . $conn->connect_error);
} 

// Take the data from the request
$data = file_get_contents('php://input');
$json = json_decode($data, true);

// Grab JSON data
$recipe_name = $json["name"];
$recipe_id = $json["recipe_id"];
$recipe_description = ($json["description"] == "") ? null : $json["description"];
$ingredients = ($json["ingredients"] == "") ? array() : $json["ingredients"];
$instructions = ($json["instructions"] == "") ? array() : $json["instructions"];
$ingredient_to_id_map = ($json["ingredientToIdMap"] == "") ? array() : $json["ingredientToIdMap"];
$instruction_to_id_map = ($json["instructionToIdMap"] == "") ? array() : $json["instructionToIdMap"];
$image_id = ($json["imageId"] == "") ? null : $json["imageId"];

// Begin transaction
$conn->begin_transaction(MYSQLI_TRANS_START_READ_WRITE);

// Initialize prepared statement for updating recipes table
$update_recipe_sql_ps = "";
if(is_null($image_id)) {
	// If theres no image, just update recipe name and description
	$update_recipe_sql_ps = $conn->prepare(UPDATE_RECIPE_SQL);
	$update_recipe_sql_ps->bind_param("ssi", $recipe_name, $recipe_description, $recipe_id);
}
else {
	// If there is an image, update image id as well
	$update_recipe_sql_ps = $conn->prepare(UPDATE_RECIPE_SQL_WITH_IMAGE);
	$update_recipe_sql_ps->bind_param("ssii", $recipe_name, $recipe_description, $image_id, $recipe_id);
}

// Update recipes table
if($update_recipe_sql_ps->execute()) {
	echo Constants::SUCCESS_STRING;
}
else {
	die("Error updating recipe: " . $update_recipe_sql_ps->error);
}

// Update ingredients
if(count($ingredients) > 0) {

	// Create array to store all recipe id and ingredient pairs
	$recipe_ingredient_sql_pairs = array();

	// Find any new ingredients by checking that they don't have an associated ID
	foreach($ingredients as $ingredient) {
		if(!array_key_exists($ingredient, $ingredient_to_id_map)) {		
			// Add to sql pairs array
			$recipe_ingredient_pair = "($recipe_id, '$ingredient')";
			array_push($recipe_ingredient_sql_pairs, $recipe_ingredient_pair);
		}
	}
	
	// Add sql pairs to insert sql string
	$insert_ingredients_sql = INSERT_INGREDIENTS_SQL . implode(",", $recipe_ingredient_sql_pairs);

	// Insert any new ingredients
	if(count($recipe_ingredient_sql_pairs) > 0) {
		if($conn->query($insert_ingredients_sql)) {
			echo Constants::SUCCESS_STRING;
		}
		else {
			die("Error inserting new ingredients");
		}
	}

	// Update existing ingredients by checking if they have an associated ingredient id
	if(count($ingredient_to_id_map) > 0) {
		foreach($ingredient_to_id_map as $ingredient => $ingredient_id) {

			// Create prepared statement 
			$update_ingredient_ps = $conn->prepare(UPDATE_INGREDIENTS_SQL);
			$update_ingredient_ps->bind_param("si", $ingredient, $ingredient_id);

			// Update ingredient
			if($update_ingredient_ps->execute()) {
				echo Constants::SUCCESS_STRING;
			}
			else {
				die("Error updating ingredient: " . $update_ingredient_ps->error);
			}
		}
	}  

}

// Update instructions
if(count($instructions) > 0) {

	// Create array to store all recipe id and ingredient pairs
	$recipe_instruction_sql_pairs = array();

	// Find any new instruction by checking that they don't have an associated ID
	foreach($instructions as $instruction) {
		if(!array_key_exists($instruction, $instruction_to_id_map)) {		
			// Add to sql pairs
			$recipe_instruction_pair = "($recipe_id, '$instruction')";
			array_push($recipe_instruction_sql_pairs, $recipe_instruction_pair);
		}
	}

	// Add sql pairs to insert instructions string
	$insert_instructions_sql = INSERT_INSTRUCTIONS_SQL . implode(",", $recipe_instruction_sql_pairs);

	// Insert any new instructions
	if(count($recipe_instruction_sql_pairs) > 0) {
		if($conn->query($insert_instructions_sql)) {
			echo Constants::SUCCESS_STRING;
		}
		else {
			die("Error inserting new instructions");
		}
	}

	// Update existing instructions by checking if they have an associated instruction id
	if(count($instruction_to_id_map) > 0) {
		foreach($instruction_to_id_map as $instruction => $instruction_id) {

			// Create prepared statement
			$update_instruction_ps = $conn->prepare(UPDATE_INSTRUCTIONS_SQL);
			$update_instruction_ps->bind_param("si", $instruction, $instruction_id);

			// Update instruction
			if($update_instruction_ps->execute()) {
				echo Constants::SUCCESS_STRING;
			}
			else {
				die("Error updating instruction: " . $update_instruction_ps->error);
			}
		}
	}  
}



// End transaction
$conn->commit();

// Close the connection
$conn->close();

?>