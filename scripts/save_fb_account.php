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
$fb_profile_name =  $json["fb_profile_name"];

// Begin transaction
$conn->begin_transaction(MYSQLI_TRANS_START_READ_WRITE);

// If user exists, update most recent login. Otherwise just insert
$fb_user_accounts_table = $config->get_table(Config::FB_USER_ACCOUNTS_TABLE);
$does_user_exist_ps = $conn->prepare("SELECT * FROM $fb_user_accounts_table WHERE fb_user_id = ? LIMIT 1");
$does_user_exist_ps->bind_param("s", $fb_user_id);
if(!$does_user_exist_ps->execute()) {
	echo $json_service->get_json_result("Error checking for fb user: " . $does_user_exist_ps->error, false);
	die();
}

if($does_user_exist_ps->fetch()) {
	// User already exists
	$does_user_exist_ps->close();		
	$update_user_ps = $conn->prepare("UPDATE $fb_user_accounts_table SET most_recent_login = now() WHERE fb_user_id = ?");
	$update_user_ps->bind_param("s", $fb_user_id);
	if(!$update_user_ps->execute()) {
		echo $json_service->get_json_result("Error updating fb user: " . $conn->error, false);
		die();
	}	
}
else {
	// Create user
	$does_user_exist_ps->close();	
	$insert_user_ps = $conn->prepare("INSERT INTO " . $fb_user_accounts_table . " (fb_user_id, fb_profile_name) VALUES (?, ?)");   
	$insert_user_ps->bind_param("ss", $fb_user_id, $fb_profile_name);
	if(!$insert_user_ps->execute()) {
		echo $json_service->get_json_result("Error inserting fb user: " . $conn->error, false);
		die();
	}
}

// End transaction
$conn->commit();

// Close the connection
$conn->close();

// Print result
echo $json_service->get_json_result("Successfully saved account", true);

?>