<?php

include "config.php";
include "json_service.php";

$config = new Config();
$json_service = new JsonService();


$insert_new_fb_account_sql = "INSERT INTO " . $config->get_table(Config::FB_USER_ACCOUNTS_TABLE) . " (fb_user_id, fb_profile_name) VALUES(?, ?)" . 
								" ON DUPLICATE KEY UPDATE fb_user_id = ?";


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
$fb_user_id = $json["fb_user_id"];
$fb_profile_name = $json["fb_profile_name"];

// Begin transaction
$conn->begin_transaction(MYSQLI_TRANS_START_READ_WRITE);

$insert_new_fb_account_ps = $conn->prepare($insert_new_fb_account_sql);
$insert_new_fb_account_ps->bind_param("sss", $fb_user_id, $fb_profile_name, $fb_user_id);

if(!$insert_new_fb_account_ps->execute()) {
	echo $json_service->get_json_result("Error executing insert new fb account sql: " . $insert_new_fb_account_ps->error, false);
	die();
}

// End transaction
$conn->commit();

// Close the connection
$conn->close();

// Print result
echo $json_service->get_json_result("Successfully saved account", true);

?>