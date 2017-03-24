<?php

include "constants.php";
include "jsonService.php";

const UPDATE_RECIPE_SQL = "UPDATE " . Constants::RECIPES_TABLE . " SET name = ?, description = ? WHERE recipe_id = ?";
const UPDATE_RECIPE_SQL_WITH_IMAGE = "UPDATE " . Constants::RECIPES_TABLE . " SET name = ?, description = ?, image_id = ? WHERE recipe_id = ?";
const UPDATE_INGREDIENTS_SQL = "UPDATE " . Constants::RECIPE_INGREDIENTS_TABLE . " SET ingredient = ? WHERE ingredient_id = ?";
const UPDATE_INSTRUCTIONS_SQL = "UPDATE " . Constants::RECIPE_INSTRUCTIONS_TABLE . " SET instruction = ? WHERE instruction_id = ?";

const INSERT_INGREDIENTS_SQL = "INSERT INTO " . Constants::RECIPE_INGREDIENTS_TABLE . " (recipe_id, ingredient) VALUES ";
const INSERT_INSTRUCTIONS_SQL = "INSERT INTO " . Constants::RECIPE_INSTRUCTIONS_TABLE . " (recipe_id, instruction) VALUES ";

const DELETE_INGREDIENTS_SQL = "UPDATE " . Constants::RECIPE_INGREDIENTS_TABLE . " SET deleted = true WHERE ingredient_id IN (?)";
const DELETE_INSTRUCTION_SQL = "UPDATE " . Constants::RECIPE_INSTRUCTIONS_TABLE . " SET deleted = true WHERE instruction_id IN (?)";

const GET_RECIPE_IMAGE_SQL = "SELECT image_id from " . Constants::RECIPES_TABLE . " where recipe_id = ?";

$json_service = new JsonService();

function get_current_recipe_image($conn, $recipe_id) {
	// Check if recipe used to have an image
	$current_image_ps = $conn->prepare(GET_RECIPE_IMAGE_SQL);
	$current_image_ps->bind_param("i", $recipe_id);

	if(!$current_image_ps->execute()) {
		echo $json_service->get_json_result("error checking for recipe image: " . $current_image_ps->error, false);
		die();
	}

	$current_image_id;
	$current_image_ps->bind_result($recipe_image_id);
	while($current_image_ps->fetch()) {
		// will only be one result
		$current_image_id = $recipe_image_id;	
	}
	return $current_image_id;
}

function delete_recipe_image($conn, $recipe_id, $image_id) {
	$delete_image_sql = "UPDATE " . Constants::IMAGES_TABLE . " SET deleted = true where image_id = " . $image_id;
	echo $delete_image_sql;
	if(!$conn->query($delete_image_sql)) {
		echo $json_service->get_json_result("Couldn't delete from images table: " . $conn->error, false);
		die();
	}

	$delete_recipe_image_sql = "UPDATE " . Constants::RECIPES_TABLE . " SET image_id = NULL where recipe_id = " . $recipe_id;
	if(!$conn->query($delete_recipe_image_sql)) {
		echo $json_service->get_json_result("Couldn't delete image from recipes table: " . $conn->error, false);
		die();
	}

	echo "deleted old image";
}


// Create connection to sql
$conn = mysqli_connect(Constants::SERVER_NAME, Constants::USER_NAME, Constants::PASSWORD); 

// Check connection
if ($conn->connect_error) {
	echo $json_service->get_json_result("Connection failed: " . $conn->connect_error, false);
	die();
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
$ingredient_to_id_map = ($json["ingredient_to_id_map"] == "") ? array() : $json["ingredient_to_id_map"];
$instruction_to_id_map = ($json["instruction_to_id_map"] == "") ? array() : $json["instruction_to_id_map"];

$ingredients_to_delete = ($json["ingredients_to_delete"] == "") ? array() : $json["ingredients_to_delete"];
$instructions_to_delete = ($json["instructions_to_delete"] == "") ? array() : $json["instructions_to_delete"];

$new_image_id = ($json["new_image_id"] == "") ? null : $json["new_image_id"];
$delete_image = ($json["delete_image"] == "") ? false : $json["delete_image"];

// Begin transaction
$conn->begin_transaction(MYSQLI_TRANS_START_READ_WRITE);

// Initialize prepared statement for updating recipes table
$update_recipe_sql_ps = $conn->prepare(UPDATE_RECIPE_SQL);
$update_recipe_sql_ps->bind_param("ssi", $recipe_name, $recipe_description, $recipe_id);

// Update recipes table
if(!$update_recipe_sql_ps->execute()) {
	echo $json_service->get_json_result("Error updating recipe: " . $update_recipe_sql_ps->error, false);
	die();
}

// If a new image id is provided, delete any existing one and save the new one
if($new_image_id) {
	$current_image_id = get_current_recipe_image($conn, $recipe_id);
	if(!is_null($current_image_id)) {
		delete_recipe_image($conn, $recipe_id, $current_image_id);
	}

	$updated_recipe_image_sql = "UPDATE " . Constants::RECIPES_TABLE . " SET image_id = " . $new_image_id . " where recipe_id = " . $recipe_id;
	$conn->query($updated_recipe_image_sql);
	if($conn->error) {
		echo $json_service->get_json_result("Couldn't updated image in recipes table: " . $conn->error, false);
		die();		
	}
}
else if ($delete_image) {	
	// If user only wants to delete image
	$current_image_id = get_current_recipe_image($conn, $recipe_id);
	delete_recipe_image($conn, $recipe_id, $current_image_id);
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
		if(!$conn->query($insert_ingredients_sql)) {
			echo $json_service->get_json_result("Error inserting new ingredients", false);
			die();
		}
	}

	// Update existing ingredients by checking if they have an associated ingredient id
	if(count($ingredient_to_id_map) > 0) {
		foreach($ingredient_to_id_map as $ingredient => $ingredient_id) {

			// Create prepared statement 
			$update_ingredient_ps = $conn->prepare(UPDATE_INGREDIENTS_SQL);
			$update_ingredient_ps->bind_param("si", $ingredient, $ingredient_id);

			// Update ingredient
			if(!$update_ingredient_ps->execute()) {
				echo $json_service->get_json_result("Error updating ingredient: " . $update_ingredient_ps->error, false);
				die();
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
		if(!$conn->query($insert_instructions_sql)) {
			echo $json_service->get_json_result("Error inserting new instructions", false);
			die();
		}
	}

	// Update existing instructions by checking if they have an associated instruction id
	if(count($instruction_to_id_map) > 0) {
		foreach($instruction_to_id_map as $instruction => $instruction_id) {

			// Create prepared statement
			$update_instruction_ps = $conn->prepare(UPDATE_INSTRUCTIONS_SQL);
			$update_instruction_ps->bind_param("si", $instruction, $instruction_id);

			// Update instruction
			if(!$update_instruction_ps->execute()) {
				echo $json_service->get_json_result("Error updating instruction: " . $update_instruction_ps->error, false);
				die();
			}
		}
	}  
}

// Delete any ingredients
if(count($ingredients_to_delete) > 0) {
	$ingredient_ids_string = implode(",", $ingredients_to_delete);
	$delete_ingredients_sql = str_replace("?", $ingredient_ids_string, DELETE_INGREDIENTS_SQL);

	if(!$conn->query($delete_ingredients_sql)) {
		echo $json_service->get_json_result("Error deleting recipe ingredients: " . $conn->error, false);
		die();
	}
}

// Delete any instructions
if(count($instructions_to_delete) > 0) {
	$instruction_ids_string = implode(",", $instructions_to_delete);
	$delete_instructions_sql = str_replace("?", $instruction_ids_string, DELETE_INSTRUCTION_SQL);

	if(!$conn->query($delete_instructions_sql)) {
		echo $json_service->get_json_result("Error deleting recipe instructions: " . $conn->error, false);
		die();
	}
}	

// End transaction
$conn->commit();

// Close the connection
$conn->close();

echo $json_service->get_json_result("Successfully updated recipe", true);

?>