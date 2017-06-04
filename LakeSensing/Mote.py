class Mote:
    # Time of current sequence:
    last_packet_time = -1

    # Aggregated data of all packets in current sequence:
    packet_data = ''

    # Number of last packet in sequence that has been received:
    last_packet_seq = -1

    # Set to true if sequence is complete
    complete = False

    packet_dropped = False