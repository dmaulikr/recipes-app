<?php

include "constants.php";

const INSERT_IMAGE_BLOB_SQL = "INSERT INTO " . Constants::IMAGE_BLOBS_TABLE . " (image) VALUES ";
const INSERT_IMAGE_SQL = "INSERT INTO " . Constants::IMAGES_TABLE . " (image_blob_id, image_url) VALUES (?, ?)";

function print_json_result($message, $success, $image_id = -1) {
	$status = ($success) ? "success" : "error"; 
	echo json_encode([
		"image_id" => $image_id,
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

// If there's no image, return
if(!array_key_exists("file", $_FILES) || is_null($_FILES["file"]["tmp_name"])) {
	print_json_result("There was no image found", false);	
	die();
}

// Insert into image blobs table
$image = $_FILES["file"]["tmp_name"];
$insert_image_blob_sql = INSERT_IMAGE_BLOB_SQL . "('$image')";
if(!$conn->query($insert_image_blob_sql)) {
	print_json_result("Error inserting image blob: " . $conn->error, false);
	die();
}

// Get image blob id from last query
$image_blob_id = mysqli_insert_id($conn);
$image_url = "images/image" . $image_blob_id . "_" . hash("md5", $image_blob_id) . ".jpg";

// Insert into images table
$insert_image_ps = $conn->prepare(INSERT_IMAGE_SQL);
$insert_image_ps->bind_param("is", $image_blob_id, $image_url);
if(!$insert_image_ps->execute()) {
	print_json_result("Error inserting image: " . $insert_image_ps->error, false);
	die();
}

// Get image id from last query
$image_id = mysqli_insert_id($conn);

// After all the other queries are successful, save the image to server
if(!move_uploaded_file($image, $image_url)) {
	print_json_result("There was an error uploading the file to the server", false);
	die();
}

// End transaction
$conn->commit();

// Close the connection
$conn->close();

// Print success message
print_json_result("Image saved successfully", true, $image_id);

?>