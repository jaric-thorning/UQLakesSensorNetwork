<?php

file_put_contents("./log_loc.txt", $_POST["data"]."\n", FILE_APPEND);

$data = json_decode($_POST["data"]);

function insertData($conn, $id, $lat, $long) {
    #$sql = "INSERT INTO data VALUES ('".$id."', '".$type."', '".$measure."', '".$val."', FROM_UNIXTIME(".$time."));";
    $sql = "REPLACE INTO loc VALUES ('".$id."', '".$lat."', '".$long."');";
    $conn->query($sql);
}

if($data!=NULL) {
    //var_dump($data);
    if(array_key_exists("mote", $data) && array_key_exists("lat", $data) && array_key_exists("lng", $data)) {
        $conn = new mysqli("localhost", "root", "35af40f63d047458", "csse4011E");
        $id = $conn->real_escape_string($data->mote);
        $lat = $conn->real_escape_string($data->lat);
        $long = $conn->real_escape_string($data->lng);
        insertData($conn, $id, $lat, $long);
        $conn->close();
    } else {
        header("HTTP/1.0 491 Missing Primary Key");
    }
} else {
    header("HTTP/1.0 490 Malformed JSON");
}

?>
