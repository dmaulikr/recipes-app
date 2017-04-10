<?php

include "config.php";
include "json_service.php";

$config = new Config();
$json_service = new JsonService();


$delete_recipes_sql = "UPDATE " . $config->get_table(Config::RECIPES_TABLE) . " SET date_modified = NOW(), date_removed = NOW() WHERE recipe_id IN (?)";


// Create connection
$conn = mysqli_connect($config->get_config(Config::SERVER_NAME), 
					$config->get_config(Config::USER_NAME), 
					$config->get_config(Config::PASSWORD));

// Check connection
if ($conn->connect_error) {
	echo $json_service->get_json_result("Connection failed: " . $conn->connect_error, false);	
    die();
}

// Begin transaction
$conn->begin_transaction(MYSQLI_TRANS_START_READ_WRITE);

// Take the data from the request
$data = file_get_contents('php://input');
$json = json_decode($data, true);

// Grab JSON data
$recipe_ids = $json["recipe_ids"];

// Convert recipe_ids array into string to use in sql 
$recipe_ids_string = implode(",", $recipe_ids);

// Delete recipes
$delete_recipes_sql = str_replace("?", $recipe_ids_string, $delete_recipes_sql);
if(!$conn->query($delete_recipes_sql)) {
	echo $json_service->get_json_result("Error deleting recipes: " . $conn->error, false);
	die();
}

// End transaction
$conn->commit();

// Close the connection
$conn->close();

// Return Success
echo $json_service->get_json_result("Successfully deleted recipe", true);

?>