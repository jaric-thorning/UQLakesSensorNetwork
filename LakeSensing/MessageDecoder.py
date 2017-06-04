import base64

import paho.mqtt.client as mqtt
import json

server_url = '172.31.41.148'
server_port = 1883
topic = 'lora/#'


def on_connect(client, userdata, flags, rc):
    print("Connected with result code " + str(rc))

    client.subscribe(topic)


def on_message(client, userdata, msg):
    j_object = json.loads(msg.payload)

    data = j_object['data']
    data_dec = base64.b64decode(data).decode('ASCII', 'ignore')

    time = j_object['time']

    sender = '(Unknown)'
    if 'deveui' in j_object:
        sender = j_object['deveui']

    print(msg.topic + " [" + time + "] " + sender + ": " + data + " [" + data_dec + "]")


client = mqtt.Client()
client.on_connect = on_connect
client.on_message = on_message

client.connect(server_url, server_port, 60)

client.loop_forever()
