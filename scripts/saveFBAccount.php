<?php

include "constants.php";

const INSERT_NEW_FB_ACCOUNT_SQL = "INSERT INTO " . Constants::FB_USER_ACCOUNTS_TABLE . " (fb_user_id, fb_profile_name) VALUES(?, ?)" . 
								" ON DUPLICATE KEY UPDATE fb_user_id = ?";

function print_json_result($message, $success) {
	$status = ($success) ? "success" : "error"; 
	echo json_encode([
		"message" => $message,
		"status" => $status
	]);
}

// Create connection to sql
$conn = mysqli_connect(Constants::SERVER_NAME, Constants::USER_NAME, Constants::PASSWORD);

// Check connection
if ($conn->connect_error) {
	print_json_result("Connection failed: " . $conn->connect_error, false);
	die();
} 

// Take the data from the request
$data = file_get_contents('php://input');
$json = json_decode($data, true);
$fb_user_id = $json["fb_user_id"];
$fb_profile_name = $json["fb_profile_name"];

// Begin transaction
$conn->begin_transaction(MYSQLI_TRANS_START_READ_WRITE);

$insert_new_fb_account_ps = $conn->prepare(INSERT_NEW_FB_ACCOUNT_SQL);
$insert_new_fb_account_ps->bind_param("sss", $fb_user_id, $fb_profile_name, $fb_user_id);

if(!$insert_new_fb_account_ps->execute()) {
	print_json_result("Error executing insert new fb account sql: " . $insert_new_fb_account_ps->error, false);
	die();
}

// End transaction
$conn->commit();

// Close the connection
$conn->close();

// Print result
print_json_result("Successfully saved account", true);

?>