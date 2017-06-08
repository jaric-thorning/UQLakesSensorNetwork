<?php

file_put_contents("./log.txt", $_POST["data"]."\n", FILE_APPEND);

$data = json_decode($_POST["data"]);

function insertData($conn, $id, $type, $time, $measure, $val) {
    $val = $conn->real_escape_string($val);
    $sql = "INSERT INTO data VALUES ('".$id."', '".$type."', '".$measure."', '".$val."', FROM_UNIXTIME(".$time."));";
    $conn->query($sql);
}

function insertLocation($conn, $id, $type, $time) {
    echo "GOT HERE";
    $sql = "SELECT lat, longitude FROM loc WHERE id='".$id."';";
    $results = $conn->query($sql);
    $lat = null;
    $long = null;
    while($row = $results->fetch_row()) {
        $lat = $row[0];
        $long = $row[1];
    }
    echo "LSO GOT HERE";
    if($lat!=null && $long!=null) {
        insertData($conn, $id, $type, $time, "latitude", $lat);
        insertData($conn, $id, $type, $time, "longitude", $long);
    }
}

if($data!=NULL) {
    //var_dump($data);
    if(array_key_exists("mote", $data) && array_key_exists("time", $data) && array_key_exists("type", $data) && $data->time>0) {
        $conn = new mysqli("localhost", "root", "35af40f63d047458", "csse4011E");
        $type = $conn->real_escape_string($data->type);
        $time = $conn->real_escape_string($data->time);
        $id = $conn->real_escape_string($data->mote);
        if(strcmp($type, "air")==0) {
            //air
            if(array_key_exists("temperature", $data)) {
                insertData($conn, $id, $type, $time, "temperature", $data->temperature);
            }
            if(array_key_exists("humidity", $data)) {
                insertData($conn, $id, $type, $time, "humidity", $data->humidity);
            }
            if(array_key_exists("co2", $data)) {
                insertData($conn, $id, $type, $time, "co2", $data->co2);
            }
            if(array_key_exists("no2", $data)) {
                insertData($conn, $id, $type, $time, "no2", $data->no2);
            }
            if(array_key_exists("o3", $data)) {
                insertData($conn, $id, $type, $time, "o3", $data->o3);
            }
            if(array_key_exists("co", $data)) {
                insertData($conn, $id, $type, $time, "co", $data->co);
            }
            insertLocation($conn, $id, $type, $time);
        } else {
            if(strcmp($type, "water")==0) {
                if(array_key_exists("temperature", $data)) {
                    insertData($conn, $id, $type, $time, "temperature", $data->temperature);
                }
                if(array_key_exists("cond", $data)) {
                    insertData($conn, $id, $type, $time, "cond", $data->cond);
                }
                if(array_key_exists("spcond", $data)) {
                    insertData($conn, $id, $type, $time, "spcond", $data->spcond);
                }
                if(array_key_exists("sal", $data)) {
                    insertData($conn, $id, $type, $time, "sal", $data->sal);
                }
                if(array_key_exists("ph_mv", $data)) {
                    insertData($conn, $id, $type, $time, "ph_mv", $data->ph_mv);
                }
                if(array_key_exists("ph", $data)) {
                    insertData($conn, $id, $type, $time, "ph", $data->ph);
                }
                if(array_key_exists("orp", $data)) {
                    insertData($conn, $id, $type, $time, "orp", $data->orp);
                }
                if(array_key_exists("depth", $data)) {
                    insertData($conn, $id, $type, $time, "depth", $data->depth);
                }
                if(array_key_exists("odo", $data)) {
                    insertData($conn, $id, $type, $time, "odo", $data->odo);
                }
                insertLocation($conn, $id, $type, $time);
            }
            else {
                header("HTTP/1.0 492 Bad data type");
            }
            $conn->close();
        }
    } else {
        header("HTTP/1.0 491 Missing Primary Key");
    }
} else {
    header("HTTP/1.0 490 Malformed JSON");
}

?>
