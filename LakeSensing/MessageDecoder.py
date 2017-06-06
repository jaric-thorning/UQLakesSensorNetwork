import base64

import paho.mqtt.client as mqtt
import json
import locale
import http.client
import logging

from PacketSequence import PacketSequence

# Char used to separate individual data points in payload
data_separator = ','

uq_server_host = "s4237341-csse4011.uqcloud.net"

mqtt_server_url = '172.31.41.148'
mqtt_server_port = 1883
topic = 'lora/+/up'

# Motes send data to this port
lora_application_port = 4

# Stores current sequence per device
data = dict()

# Type of sensors per device. Type is either 'air' or 'water'.
sensors = {'00-80-00-00-00-00-ca-67': 'air', '00-80-00-00-00-00-ca-19': 'water'}


# -----------------------------------------------------------------

def on_connect(client, userdata, flags, rc):
    logging.info("Connected with result code " + str(rc))
    client.subscribe(topic)


def on_message(client, userdata, msg):
    parse_message(msg.payload)


def parse_message(msg):
    j_object = json.loads(msg)
    port = j_object['port']

    if port != 4:
        # Ignore packets for other applications:
        return

    time_received = j_object['timestamp']
    sender_id = j_object['deveui']

    if sender_id not in sensors:
        # Ignore packets from unknown motes:
        logging.error("Unknown sensor with id " + sender_id)
        return

    # Process the packet payload:
    packet_data = j_object['data']
    packet_data_bytes = base64.b64decode(packet_data)

    if sender_id not in data:
        data[sender_id] = PacketSequence()
        data[sender_id].complete = True
        data[sender_id].packet_dropped = False

    # ----------------------------------------------------------------------------------------------
    # Sequence number is first byte:
    seq_no = int(packet_data_bytes[0])

    if seq_no == 1:
        # This is a control frame

        # Make sure that previous sequence was complete:
        if not data[sender_id].complete:
            print("Received new control frame, but previous sequence hasn't been terminated.")

        data[sender_id].complete = False
        data[sender_id].packet_dropped = False
        data[sender_id].packet_data = ''
    elif seq_no > 1:
        diff = seq_no - data[sender_id].last_packet_seq

        if abs(diff) > 1:
            data[sender_id].packet_dropped = True

        if diff == 0:
            logging.warning("Ignoring packet with same sequence number received (retransmission?)")
            return

        if diff > 1:
            # Packet missed:
            logging.warning("Missed " + str(diff) + " packet(s).")
        if diff < 1:
            # Sequence number is lower than last number received:
            logging.warning(
                "Packet has lower sequence number than previous one. Either missing control frame, or packets arrived out-of order.")

    # Update sequence number:
    data[sender_id].last_packet_seq = seq_no

    # ----------------------------------------------------------------------------------------------
    data_dec = ''

    # Decode the payload data:
    payload = packet_data_bytes[1:]
    data_dec = payload.decode('ASCII', 'ignore')

    # Append data:
    data[sender_id].packet_data += data_dec

    # Status update:
    logging.info("[" + time_received + "] " + sender_id + ": " + "Sequence: " + str(
        data[sender_id].last_packet_seq) + ". Data: " + data_dec)

    # See if sequence is complete:
    if data_dec.endswith('~'):
        data[sender_id].complete = True

        data[sender_id].packet_data = data[sender_id].packet_data[:-1]

        # Send the data to the cloud:
        if not data[sender_id].packet_dropped:
            parse_payload(data[sender_id], sender_id)
        else:
            logging.info("Sequence complete, but packet missing.")


def parse_payload(mote_data, mote_id):
    logging.info("Sequence complete (" + mote_id + ") . Data: " + mote_data.packet_data)

    if mote_id not in sensors:
        logging.error("No sensor type for mote " + mote_id + " defined.")
        return

    sensor_type = sensors[mote_id]
    components = mote_data.packet_data.split(data_separator)

    # First component should be timestamp:
    mote_data.seq_time = int(components[0])

    # Replace decimal separator with local one to ensure compatability when using different locales + parse floats:
    dec_point = locale.localeconv()['decimal_point']
    for i in range(1, len(components)):
        try:
            x = components[i].replace('.', dec_point)
            components[i] = float(x)
        except ValueError:
            logging.error("Failed to convert '" + components[i] + "' to float.")

    # Create correct json for sensor type:
    transmit_data = ''
    if sensor_type == 'air':
        # 6 numbers + 1 timestamp:
        if len(components) != 7:
            logging.error("Wrong number of data points for type 'air sensor'")
            return

        transmit_data_dict = {'time': mote_data.seq_time, 'mote': mote_id, 'type': 'air', 'temperature': components[1],
                              'humidity': components[2],
                              'co2': components[3], 'no2': components[4], 'o3': components[5],
                              'co': components[6]}
    elif sensor_type == 'water':
        if len(components) != 10:
            logging.error("Wrong number of data points for type 'water sensor'")
            return

        transmit_data_dict = {'time': mote_data.seq_time, 'mote': mote_id, 'type': 'water',
                              'temperature': components[1],
                              'cond': components[2],
                              'spcond': components[3], 'sal': components[4], 'ph_mv': components[5],
                              'ph': components[6], 'orp': components[7], 'depth': components[8], 'odo': components[9]}
    else:
        logging.error('Unknown sensor type ' + sensor_type + ' for mote with id ' + mote_id)
        return

    transmit_data_json = json.dumps(transmit_data_dict)
    transmit_data = str(transmit_data_json)

    logging.info('Sending "' + transmit_data + '"')

    send_data(transmit_data)


def send_data(data):
    conn = http.client.HTTPSConnection(uq_server_host)

    headers = {'Content-Type': 'application/x-www-form-urlencoded'}
    content = "data=" + data

    conn.request("POST", "/data/put.php", content, headers)
    response = conn.getresponse()

    if response.status == 200:
        logging.info("Data sent to server.")
    else:
        res_content = response.read()

        logging.info("Failed to send data: error code is " + str(response.status) + ". Response is '" + str(
            res_content) + "'");


# --------------------------------------------------
logging_format = '%(asctime)s\t%(levelname)-8s\t%(name)s.%(funcName)s\t%(message)s'

logging.basicConfig(filename='message_decoder.log', format=logging_format,
                    level=logging.DEBUG)

# Set up logging to console:
root_logger = logging.getLogger()
root_logger.setLevel(logging.DEBUG)

console = logging.StreamHandler()
console.setLevel(logging.INFO)
console.setFormatter(logging.Formatter(fmt=logging_format))
root_logger.addHandler(console)

# --------------------------------------

# send_data('{"test": 2}')

client = mqtt.Client()
client.on_connect = on_connect
client.on_message = on_message

client.connect(mqtt_server_url, mqtt_server_port, 60)

client.loop_forever()
