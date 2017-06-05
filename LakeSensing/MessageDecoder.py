import base64

import paho.mqtt.client as mqtt
import json
import locale
import http.client

from PacketSequence import PacketSequence

# Char used to separate individual data points in payload
data_separator = ' '

server_url = '172.31.41.148'
server_port = 1883
topic = 'lora/+/up'

# Motes send data to this port
application_port = 4

data = dict()

# Type of sensors per device. Type is either 'air' or 'water'.
sensors = {'00-80-00-00-00-00-ca-67': 'air'}


def on_connect(client, userdata, flags, rc):
    print("Connected with result code " + str(rc))
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

        if diff > 1:
            # Packet missed:
            print("Missed " + str(diff) + " packet(s).")
        if diff < 1:
            # Sequence number is lower than last number received:
            print(
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
    print("[" + time_received + "] " + sender_id + ": " + "Sequence: " + str(
        data[sender_id].last_packet_seq) + ". Data: " + data_dec)

    # See if sequence is complete:
    if data_dec.endswith('~'):
        data[sender_id].complete = True

        data[sender_id].packet_data = data[sender_id].packet_data[:-1]

        # Send the data to the cloud:
        if not data[sender_id].packet_dropped:
            parse_payload(data[sender_id], sender_id)
        else:
            print("Sequence complete, but packet missing.")


def parse_payload(mote_data, mote_id):
    print("-----------------------------")
    print("Sequence complete (" + mote_id + ") . Data: " + mote_data.packet_data)
    print("-----------------------------")

    if mote_id not in sensors:
        print("No sensor type for mote " + mote_id + " defined.")
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
            print("Failed to convert '" + components[i] + "' to float.")

    # Create correct json for sensor type:
    transmit_data = ''
    if sensor_type == 'air':
        # 6 numbers + 1 timestamp:
        if len(components) != 7:
            print("Wrong number of data points for type 'air sensor'")
            return

        transmit_data_dict = {'time': mote_data.seq_time, 'mote': mote_id, 'type': 'air', 'temperature': components[1],
                              'humidity': components[2],
                              'co2': components[3], 'no2': components[4], 'o3': components[5],
                              'co': components[6]}
    elif sensor_type == 'water':
        if len(components) != 11:
            print("Wrong number of data points for type 'water sensor'")
            return

        transmit_data_dict = {'time': mote_data.seq_time, 'mote': mote_id, 'type': 'water',
                              'temperature': components[1],
                              'humidity': components[2],
                              'co2': components[3], 'no2': components[4], 'o3': components[5],
                              'co': components[6]}
    else:
        print('Invalid sensor type for mote ' + mote_id)
        return

    transmit_data_json = json.dumps(transmit_data_dict)
    transmit_data = str(transmit_data_json)

    send_data(transmit_data)


def send_data(data):
    conn = http.client.HTTPSConnection("s4237341-csse4011.uqcloud.net")
    conn.request("PUT", "/data/put.php", data)
    response = conn.getresponse()

    if response.status == 200:
        print("Data sent to server.")
    else:
        print("Failed to send data: error code is " + str(response.status))


# --------------------------------------------------

# m = PacketSequence()
# m.packet_data = '946598400 -00.00 -00 0.00 0.00 0.00 0.0'
# send_data(m, '00-80-00-00-00-00-ca-67')

#send_data('{"test": 1}')

client = mqtt.Client()
client.on_connect = on_connect
client.on_message = on_message

client.connect(server_url, server_port, 60)

client.loop_forever()
