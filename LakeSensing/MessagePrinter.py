import base64

import paho.mqtt.client as mqtt
import json

from PacketSequence import PacketSequence

server_url = '172.31.41.148'
server_port = 1883
topic = 'lora/+/up'

# Motes send data to this port
application_port = 4


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

    payload = packet_data_bytes[:]
    data_dec = payload.decode('ASCII', 'ignore')

    print("[" + time_received + "] " + sender_id + ": " + packet_data + " [" + data_dec + "]")



client = mqtt.Client()
client.on_connect = on_connect
client.on_message = on_message

client.connect(server_url, server_port, 60)

client.loop_forever()
