<?php

$conn = new mysqli("localhost", "root", "35af40f63d047458", "csse4011E");

echo "[\n";

$sql = "select id, lat, longitude, node_type, max(unix_timestamp(time)), measure_value from loc left join data on loc.id=data.node_id where measure_type='temperature' OR measure_type IS NULL group by id;";

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
    echo "    \"lat\": \"".$row[1]."\",\n";
    echo "    \"lng\": ".$row[2];
    if($row[3]!=null) {
        echo ",\n";
        echo "    \"type\": \"".$row[3]."\",\n";
        echo "    \"last_time\": ".$row[4].",\n";
        echo "    \"temperature\": ".$row[5];
    }
    echo "\n}";
}
$results->close();
$conn->close();
echo "\n]";

?>
