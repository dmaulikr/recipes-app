<?php

include "config.php";
include "json_service.php";

$config = new Config();
$json_service = new JsonService();

$recipes_table = $config->get_table(Config::RECIPES_TABLE);
$recipe_ingredients_table = $config->get_table(Config::RECIPE_INGREDIENTS_TABLE);
$recipe_instructions_table = $config->get_table(Config::RECIPE_INSTRUCTIONS_TABLE);


$insert_recipe_sql = "INSERT INTO " . $recipes_table . " (name, description, image_id, fb_user_id) VALUES (?, ?, ?, ?)";
$insert_ingredient_sql = "INSERT INTO " . $recipe_ingredients_table . " (recipe_id, ingredient) VALUES ";
$insert_instruction_sql = "INSERT INTO " . $recipe_instructions_table . " (recipe_id, instruction) VALUES ";

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
$recipe_name = $json["name"];
$recipe_description = ($json["description"] == "") ? null : $json["description"];
$ingredients = ($json["ingredients"] == "") ? array() : $json["ingredients"];
$instructions = ($json["instructions"] == "") ? array() : $json["instructions"];
$image_id = ($json["image_id"] == "") ? null : $json["image_id"];

// Begin transaction
$conn->begin_transaction(MYSQLI_TRANS_START_READ_WRITE);

// Insert recipe name and description into recipes table
$insert_recipe_sql_ps = $conn->prepare($insert_recipe_sql);
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
	$insert_ingredient_sql = $insert_ingredient_sql . implode(",", $recipe_ingredient_sql_pairs);

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
	$insert_instruction_sql = $insert_instruction_sql . implode(",", $recipe_instruction_sql_pairs);

	// Insert instructions
	if(!$conn->query($insert_instruction_sql)) {
	    echo $json_service->get_json_result("Error inserting instructions: " . $conn->error, false);
	    die();
	}
}

// Now create ingredient and instruction maps to pass back to user
// TODO: Will want to figure out a better way to do this
$ingredient_to_id_map = array();
$retrieve_ingredients_sql = "SELECT * FROM " . $recipe_ingredients_table . " WHERE recipe_id = " . $recipe_id;
$result = $conn->query($retrieve_ingredients_sql);
while($row = $result->fetch_assoc()) {
	$ingredient_id = $row["ingredient_id"];
	$ingredient_name = $row["ingredient"];		
	$ingredient_to_id_map[$ingredient_name] = intval($ingredient_id);
}
	
$instruction_to_id_map = array();						
$retrieve_instructions_sql = "SELECT * FROM " . $recipe_instructions_table . " WHERE recipe_id = " . $recipe_id;
$result = $conn->query($retrieve_instructions_sql);
while($row = $result->fetch_assoc()) {
	$instruction_id = $row["instruction_id"];
	$instruction_name = $row["instruction"];		
	$instruction_to_id_map[$instruction_name] = intval($instruction_id);
}

// End transaction
$conn->commit();

// Close the connection
$conn->close();

// Print success message
echo json_encode([
	"recipe_id" => $recipe_id,
	"ingredient_to_id_map" => $ingredient_to_id_map,
	"instruction_to_id_map" => $instruction_to_id_map,
	"message" => "Recipe saved successfully",
	"status" => "success"
]);

?>
