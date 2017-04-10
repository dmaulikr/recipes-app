<?php

include "config.php";
include "json_service.php";

$config = new Config();
$json_service = new JsonService();


$insert_image_blob_sql = "INSERT INTO " . $config->get_table(Config::IMAGE_BLOBS_TABLE) . " (image) VALUES ";
$insert_image_sql = "INSERT INTO " . $config->get_table(Config::IMAGES_TABLE) . " (image_blob_id, image_url) VALUES (?, ?)";


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

// If there's no image, return
if(!array_key_exists("file", $_FILES) || is_null($_FILES["file"]["tmp_name"])) {
	echo $json_service->get_json_result("There was no image found", false);	
	die();
}

// Insert into image blobs table
$image = $_FILES["file"]["tmp_name"];
$insert_image_blob_sql = $insert_image_blob_sql . "('$image')";
if(!$conn->query($insert_image_blob_sql)) {
	echo $json_service->get_json_result("Error inserting image blob: " . $conn->error, false);
	die();
}

// Get image blob id from last query
$image_blob_id = mysqli_insert_id($conn);
$save_image_url = "images/image" . $image_blob_id . "_" . hash("md5", $image_blob_id) . ".jpg";

// Insert into images table
$insert_image_ps = $conn->prepare($insert_image_sql);
$insert_image_ps->bind_param("is", $image_blob_id, $save_image_url);
if(!$insert_image_ps->execute()) {
	echo $json_service->get_json_result("Error inserting image: " . $insert_image_ps->error, false);
	die();
}

// Get image id from last query
$image_id = mysqli_insert_id($conn);

// After all the other queries are successful, save the image to server
if(!move_uploaded_file($image, "../" . $save_image_url)) {
	echo $json_service->get_json_result("There was an error uploading the file to the server", false);
	die();
}

// End transaction
$conn->commit();

// Close the connection
$conn->close();

// Print success message
echo json_encode([
	"image_id" => $image_id,
	"image_url" => $save_image_url,
	"message" => "Image saved successfully",
	"status" => "success"
]);

?>