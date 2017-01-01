<?php

include "constants.php";

const UPDATE_RECIPE_SQL = "UPDATE " . Constants::RECIPES_TABLE . " SET name = ?, description = ? WHERE recipe_id = ?";
const UPDATE_INGREDIENTS_SQL = "UPDATE " . Constants::RECIPE_INGREDIENTS_TABLE . " SET ";
const UPDATE_INSTRUCTIONS_SQL = "UPDATE " . Constants::RECIPE_INSTRUCTIONS_TABLE . " SET ";

const INSERT_INGREDIENTS_SQL = "INSERT INTO " . Constants::RECIPE_INGREDIENTS_TABLE . " (recipe_id, ingredient) VALUES ";
const INSERT_INSTRUCTIONS_SQL = "INSERT INTO " . Constants::RECIPE_INSTRUCTIONS_TABLE . " (recipe_id, instruction) VALUES ";

function createSQLValuesArray($recipe_id, $values) {
	$sql_values = array();
	foreach($values as $value) {
		$value_str = "($recipe_id, '$value')";
		array_push($sql_values, $value_str);
	}
	return $sql_values;
}

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
$ingredientToIdMap = ($json["ingredientToIdMap"] == "") ? array() : $json["ingredientToIdMap"];
$instructionToIdMap = ($json["instructionToIdMap"] == "") ? array() : $json["instructionToIdMap"];

// Begin transaction
$conn->begin_transaction(MYSQLI_TRANS_START_READ_WRITE);

// Update recipes table
$update_recipe_sql_ps = $conn->prepare(UPDATE_RECIPE_SQL);
$update_recipe_sql_ps->bind_param("ssi", $recipe_name, $recipe_description, $recipe_id);
if($update_recipe_sql_ps->execute()) {
	echo Constants::SUCCESS_STRING;
}
else {
	die("Error updating recipe: " . $update_recipe_sql_ps->error);
}

// Update ingredients
if(count($ingredients) > 0) {

	$update_ingredients_sql_values = array();
	$insert_ingredient_sql_values = array();

	foreach($ingredients as $ingredient) {
		if(array_key_exists($ingredient, $ingredientToIdMap)) {
			// Add to update string
			$value_str = "(ingredient = $ingredient WHERE recipe_id = $recipe_id)";
			array_push($update_ingredients_sql_values, $value_str);
		}
		else {
			// Add to insert string
			$value_str = "($recipe_id, $ingredient)";
			array_push($insert_ingredient_sql_values, $value_str);
		}
	}
	
	$update_ingredients_sql = UPDATE_INGREDIENTS_SQL . implode(",", $update_ingredients_sql_values);
	if($conn->query($update_ingredients_sql)) {
		echo Constants::SUCCESS_STRING;
	}
	else {
		die("Error updating ingredients");
	}

	$insert_ingredients_sql = INSERT_INGREDIENTS_SQL . implode(",", $insert_ingredient_sql_values);
	if($conn->query($insert_ingredients_sql)) {
		echo Constants::SUCCESS_STRING;
	}
	else {
		die("Error inserting new ingredients");
	}
}

// Update instructions


// End transaction
$conn->commit();

// Close the connection
$conn->close();

?>