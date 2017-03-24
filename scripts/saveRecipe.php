<?php

include "constants.php";
include "jsonService.php";

const INSERT_RECIPE_SQL = "INSERT INTO " . Constants::RECIPES_TABLE . " (name, description, image_id, fb_user_id) VALUES (?, ?, ?, ?)";
const INSERT_INGREDIENT_SQL = "INSERT INTO " . Constants::RECIPE_INGREDIENTS_TABLE . " (recipe_id, ingredient) VALUES ";
const INSERT_INSTRUCTION_SQL = "INSERT INTO " . Constants::RECIPE_INSTRUCTIONS_TABLE . " (recipe_id, instruction) VALUES ";

// Create recipeId to value sql pairs
function createRecipeValueSQLPairs($recipe_id, $values) {
	$recipe_value_sql_pairs = array();
	foreach($values as $value) {
		$recipe_value_pair = "($recipe_id, '$value')";
		array_push($recipe_value_sql_pairs, $recipe_value_pair);
	}
	return $recipe_value_sql_pairs;
}

$json_service = new JsonService();

// Create connection
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
$fb_user_id = $json["fb_user_id"];
$recipe_name = $json["name"];
$recipe_description = ($json["description"] == "") ? null : $json["description"];
$ingredients = ($json["ingredients"] == "") ? array() : $json["ingredients"];
$instructions = ($json["instructions"] == "") ? array() : $json["instructions"];
$image_id = ($json["image_id"] == "") ? null : $json["image_id"];

// Begin transaction
$conn->begin_transaction(MYSQLI_TRANS_START_READ_WRITE);

// Insert recipe name and description into recipes table
$insert_recipe_sql_ps = $conn->prepare(INSERT_RECIPE_SQL);
$insert_recipe_sql_ps->bind_param("ssis", $recipe_name, $recipe_description, $image_id, $fb_user_id);
if(!$insert_recipe_sql_ps->execute()) {
	echo $json_service->get_json_result("Error inserting recipe: " . $insert_recipe_sql_ps->error, false);
	die();
}

// Get recipe id from last query
$recipe_id = mysqli_insert_id($conn);

// Insert each ingredient into recipe ingredients table
if(count($ingredients) > 0) {

	// Add recipeId and ingredient pairs to insert sql string
	$recipe_ingredient_sql_pairs = createRecipeValueSQLPairs($recipe_id, $ingredients);
	$insert_ingredient_sql = INSERT_INGREDIENT_SQL . implode(",", $recipe_ingredient_sql_pairs);

	// Insert ingredients
	if(!$conn->query($insert_ingredient_sql)) {
	    echo $json_service->get_json_result("Error inserting ingredients: " . $conn->error, false);
	    die();
	}
}

// Insert each instruction into recipe instructions table
if(count($instructions) > 0) {

	// Add recipeId and instruction pairs to insert sql string
	$recipe_instruction_sql_pairs = createRecipeValueSQLPairs($recipe_id, $instructions);
	$insert_instruction_sql = INSERT_INSTRUCTION_SQL . implode(",", $recipe_instruction_sql_pairs);

	// Insert instructions
	if(!$conn->query($insert_instruction_sql)) {
	    echo $json_service->get_json_result("Error inserting instructions: " . $conn->error, false);
	    die();
	}
}

// End transaction
$conn->commit();

// Close the connection
$conn->close();

echo $json_service->get_json_result("Successfully saved recipe", true);

?>
