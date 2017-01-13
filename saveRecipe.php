<?php

include "constants.php";

const INSERT_RECIPE_SQL = "INSERT INTO " . Constants::RECIPES_TABLE . " (name, description, image_id) VALUES (?, ?, ?)";
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
$recipe_name = $json["name"];
$recipe_description = ($json["description"] == "") ? null : $json["description"];
$ingredients = ($json["ingredients"] == "") ? array() : $json["ingredients"];
$instructions = ($json["instructions"] == "") ? array() : $json["instructions"];
$image_id = ($json["imageId"] == "") ? null : $json["imageId"];

// Begin transaction
$conn->begin_transaction(MYSQLI_TRANS_START_READ_WRITE);

// Insert recipe name and description into recipes table
$insert_recipe_sql_ps = $conn->prepare(INSERT_RECIPE_SQL);
$insert_recipe_sql_ps->bind_param("ssi", $recipe_name, $recipe_description, $image_id);
if($insert_recipe_sql_ps->execute()) {
	echo Constants::SUCCESS_STRING;
}
else {
	die("Error inserting recipe: " . $insert_recipe_sql_ps->error);
}

// Get recipe id from last query
$recipe_id = mysqli_insert_id($conn);

// Insert each ingredient into recipe ingredients table
if(count($ingredients) > 0) {

	// Add recipeId and ingredient pairs to insert sql string
	$recipe_ingredient_sql_pairs = createRecipeValueSQLPairs($recipe_id, $ingredients);
	$insert_ingredient_sql = INSERT_INGREDIENT_SQL . implode(",", $recipe_ingredient_sql_pairs);

	// Insert ingredients
	if($conn->query($insert_ingredient_sql)) {
	    echo Constants::SUCCESS_STRING;
	} else {
	    die("Error inserting ingredients");
	}
}

// Insert each instruction into recipe instructions table
if(count($instructions) > 0) {

	// Add recipeId and instruction pairs to insert sql string
	$recipe_instruction_sql_pairs = createRecipeValueSQLPairs($recipe_id, $instructions);
	$insert_instruction_sql = INSERT_INSTRUCTION_SQL . implode(",", $recipe_instruction_sql_pairs);

	// Insert instructions
	if($conn->query($insert_instruction_sql)) {
	    echo Constants::SUCCESS_STRING;
	} else {
	    die("Error inserting instructions");
	}
}

// End transaction
$conn->commit();

// Close the connection
$conn->close();

?>
