<?php


class JsonService {

	/*
		Prints a simple json encoded message to display to a user

		Params: Message string and Success boolean
	*/
	function get_json_result($message, $success) {
		$status = ($success) ? "success" : "error"; 
		echo json_encode([
			"message" => $message,
			"status" => $status
		]);
	}
}

?>