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

        # Get the timestamp value (32b integer):
        # time_sent = int(packet_data_bytes[1] << 24) + int(packet_data_bytes[2] << 16) + int(
        #     packet_data_bytes[3] << 8) + int(packet_data_bytes[4])
        time_sent = 0

        # Update sequence timestamp:
        data[sender_id].last_packet_time = time_sent
    elif seq_no > 1:
        diff = seq_no - data[sender_id].last_packet_seq

        if abs(diff) > 1:
            data[sender_id].packet_dropped = True

        if diff > 1:
            # Packet missed:
            print("Missed " + diff + " packet(s).")
        if diff < 1:
            # Sequence number is lower than last number received:
            print(
                "Packet has lower sequence number than previous one. Either missing control frame, or packets arrived out-of order.")

    # Update sequence number:
    data[sender_id].last_packet_seq = seq_no

    # ----------------------------------------------------------------------------------------------
    data_dec = ''

    # Decode the payload data:
    if seq_no == 1:
        payload = packet_data_bytes[1:]
    else:
        payload = packet_data_bytes[1:]

    data_dec = payload.decode('ASCII', 'ignore')

    # Append data to sequence data payload:
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
            send_data(data[sender_id], sender_id)
        else:
            print("Sequence complete, but packet missing.")


def send_data(mote_data, mote_id):
    print("-----------------------------")
    print("Sequence complete (" + mote_id + ") . Time: " + str(
        mote_data.last_packet_time) + " Data: " + mote_data.packet_data)
    print("-----------------------------")


client = mqtt.Client()
client.on_connect = on_connect
client.on_message = on_message

client.connect(server_url, server_port, 60)

client.loop_forever()
