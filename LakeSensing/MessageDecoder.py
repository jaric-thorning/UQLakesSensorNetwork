import base64

import paho.mqtt.client as mqtt
import json

from PacketSequence import PacketSequence

server_url = '172.31.41.148'
server_port = 1883
topic = 'lora/+/up'

# Motes send data to this port
application_port = 4

data = dict()


def on_connect(client, userdata, flags, rc):
    print("Connected with result code " + str(rc))
    client.subscribe(topic)


def on_message(client, userdata, msg):
    print(msg.payload)


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

        # Get the timestamp value (32b integer):
        time_sent = int(packet_data_bytes[1] << 24) + int(packet_data_bytes[2] << 16) + int(
            packet_data_bytes[3] << 8) + int(packet_data_bytes[4])

        # Update sequence timestamp:
        data[sender_id].last_packet_time = time_sent
    elif seq_no > 1 and (seq_no - data[sender_id].last_packet_seq > 1):
        # Missed a packet:
        print("Packet dropped.");
        data[sender_id].packet_dropped = True

    # Update sequence number:
    data[sender_id].last_packet_seq = seq_no

    # ----------------------------------------------------------------------------------------------
    if seq_no > 1:
        payload = packet_data_bytes[2:]
        data_dec = payload.decode('ASCII', 'ignore')

        # Append data to sequence data payload:
        data[sender_id].packet_data += data_dec

        # See if sequence is complete:
        if data_dec[-1] == '\n':
            data[sender_id].complete = True

            # Send the data to the cloud:
            if not data[sender_id].packet_dropped:
                send_data(data[sender_id], sender_id)
            else:
                print("Sequence complete, but packet missing.")

    print("[" + time_received + "] " + sender_id + ": " + "Sequence: " + str(
        data[sender_id].last_packet_seq) + ". Data: " + data_dec)


def send_data(mote_data, mote_id):
    print("Sequence complete (" + mote_id + ") . Time: " + str(
        mote_data.last_packet_time) + " Data: " + mote_data.packet_data)


client = mqtt.Client()
client.on_connect = on_connect
client.on_message = on_message

client.connect(server_url, server_port, 60)

client.loop_forever()
