<?php

$conn = new mysqli("localhost", "root", "35af40f63d047458", "csse4011E");

$id_restrict = $conn->real_escape_string($_GET["mote"]);
$time_before_restrict = $conn->real_escape_string($_GET["time_before"]);
$time_after_restrict = $conn->real_escape_string($_GET["time_after"]);
$type_restrict = $conn->real_escape_string($_GET["type"]);

echo "[\n";

$sql = "SELECT node_id, node_type, UNIX_TIMESTAMP(time) FROM data";

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

$sql .= " GROUP BY node_id, node_type, time ORDER BY time ASC;";

$results = $conn->query($sql);

$doneFirst = false;

while($row = $results->fetch_row()) {
    if($doneFirst) {
        echo ",\n";
    } else {
        $doneFirst = true;
    }
    echo "{\n";
    echo "    \"mote\": \"".$row[0]."\",\n";
    echo "    \"type\": \"".$row[1]."\",\n";
    echo "    \"time\": ".$row[2];
    $sql2 = "SELECT measure_type, measure_value FROM data WHERE node_id='".$row[0]."' AND node_type='".$row[1]."' AND time=FROM_UNIXTIME(".$row[2].");";
    $res2 = $conn->query($sql2);
    $doneFirst2 = false;
    while($row2 = $res2->fetch_row()) {
        echo ",\n    \"".$row2[0]."\": ".$row2[1];
    }
    $res2->close();
    echo "\n}";
}
$results->close();
$conn->close();
echo "\n]";

?>
