<?php

include "constants.php";

// Create connection
$conn = mysqli_connect(Constants::SERVER_NAME, Constants::USER_NAME, Constants::PASSWORD);

// Check connection
if ($conn->connect_error) {
    die("Connection failed");
} 

echo "SUCCESS";

?>