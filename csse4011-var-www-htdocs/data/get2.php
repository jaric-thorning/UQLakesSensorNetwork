<?php

$conn = new mysqli("localhost", "root", "35af40f63d047458", "csse4011E");

$id_restrict = $conn->real_escape_string($_GET["mote"]);
$time_before_restrict = $conn->real_escape_string($_GET["time_before"]);
$time_after_restrict = $conn->real_escape_string($_GET["time_after"]);
$type_restrict = $conn->real_escape_string($_GET["type"]);
$measure_restrict = $conn->real_escape_string($_GET["measure"]);

$sql = "SELECT UNIX_TIMESTAMP(time), measure_value FROM data";

$addedWhere = false;
if($id_restrict!=null) {
    if($addedWhere) {
        $sql .= " AND ";
    } else {
        $sql .= " WHERE ";
        $addedWhere = true;
    }
    $sql .= "node_id='".$id_restrict."'";
}
if($time_before_restrict!=null) {
    if($addedWhere) {
        $sql .= " AND ";
    } else {
        $sql .= " WHERE ";
        $addedWhere = true;
    }
    $sql .= "time <= FROM_UNIXTIME(".$time_before_restrict.")";
}
if($time_after_restrict!=null) {
    if($addedWhere) {
        $sql .= " AND ";
    } else {
        $sql .= " WHERE ";
        $addedWhere = true;
    }
    $sql .= "time >= FROM_UNIXTIME(".$time_after_restrict.")";
}
if($type_restrict!=null) {
    if($addedWhere) {
        $sql .= " AND ";
    } else {
        $sql .= " WHERE ";
        $addedWhere = true;
    }
    $sql .= "node_type='".$type_restrict."'";
}
if($measure_restrict!=null) {
    if($addedWhere) {
        $sql .= " AND ";
    } else {
        $sql .= " WHERE ";
    }
    $sql .= "measure_type='".$measure_restrict."'";
}

$sql .= " GROUP BY node_id, node_type, time ORDER BY time ASC;";

$results = $conn->query($sql);

$doneFirst = false;

echo "[\n";
while($row = $results->fetch_row()) {
    if($doneFirst) {
        echo ",\n";
    } else {
        $doneFirst = true;
    }
    echo "{";
    if(!is_numeric($row[0])) {
        $row[0] = 0;
    }
    echo "\"x\": ".$row[0]."000,";
    if(!is_numeric($row[1])) {
        $row[1] = 0;
    }
    echo "\"y\": ".$row[1];
    echo "}";
}
$results->close();
$conn->close();
echo "\n]";

?>
