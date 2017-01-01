<?php

include "constants.php";

const INSERT_RECIPE_SQL = "INSERT INTO " . Constants::RECIPES_TABLE . " (Name, Description) VALUES (?, ?)";
const INSERT_INGREDIENT_SQL = "INSERT INTO " . Constants::RECIPE_INGREDIENTS_TABLE . " (recipe_id, ingredient) VALUES ";
const INSERT_INSTRUCTION_SQL = "INSERT INTO " . Constants::RECIPE_INSTRUCTIONS_TABLE . " (recipe_id, instruction) VALUES ";

function createSQLValuesArray($recipe_id, $values) {
	$sql_values = array();
	foreach($values as $value) {
		$value_str = "($recipe_id, '$value')";
		array_push($sql_values, $value_str);
	}
	return $sql_values;
}

// Create connection
$conn = mysqli_connect(Constants::SERVER_NAME, Constants::USER_NAME, Constants::PASSWORD);

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

// Begin transaction
$conn->begin_transaction(MYSQLI_TRANS_START_READ_WRITE);

// Insert into recipes table
$insert_recipe_sql_ps = $conn->prepare(INSERT_RECIPE_SQL);
$insert_recipe_sql_ps->bind_param("ss", $recipe_name, $recipe_description);
if($insert_recipe_sql_ps->execute()) {
	echo Constants::SUCCESS_STRING;
}
else {
	die("Error inserting recipe: " . $insert_recipe_sql_ps->error);
}

// Get recipe id from last query
$recipe_id = mysqli_insert_id($conn);

// Insert into recipe ingredients table
if(count($ingredients) > 0) {
	$ingredient_sql_values = createSQLValuesArray($recipe_id, $ingredients);
	$insert_ingredient_sql = INSERT_INGREDIENT_SQL . implode(",", $ingredient_sql_values);

	if($conn->query($insert_ingredient_sql)) {
	    echo Constants::SUCCESS_STRING;
	} else {
	    die("Error inserting ingredients");
	}
}

// Insert into recipe instructions table
if(count($instructions) > 0) {
	$instruction_sql_values = createSQLValuesArray($recipe_id, $instructions);
	$insert_instruction_sql = INSERT_INSTRUCTION_SQL . implode(",", $instruction_sql_values);

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