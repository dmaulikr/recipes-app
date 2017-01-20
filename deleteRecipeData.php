<?php

include "constants.php";

const DELETE_RECIPE_SQL = "UPDATE " . Constants::RECIPES_TABLE . " SET deleted = true WHERE recipe_id IN (?)";

function print_json_result($message, $success) {
	$status = ($success) ? "success" : "error"; 
	echo json_encode([
		"message" => $message,
		"status" => $status
	]);
}

// Create connection
$conn = mysqli_connect(Constants::SERVER_NAME, Constants::USER_NAME, Constants::PASSWORD);

// Check connection
if ($conn->connect_error) {
	print_json_result("Connection failed: " . $conn->connect_error, false);	
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
$delete_recipes_sql = str_replace("?", $recipe_ids_string, DELETE_RECIPE_SQL);
if(!$conn->query($delete_recipes_sql)) {
	print_json_result("Error deleting recipes: " . $conn->error, false);
}

// End transaction
$conn->commit();

// Close the connection
$conn->close();

// Return Success
print_json_result("Successfully deleted recipe", true);

?>