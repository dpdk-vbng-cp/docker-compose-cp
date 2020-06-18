#!/usr/bin/python3
import sys
import ipaddress
import json

IP_POOLS = 'ip_pools'
POOL_NAME = 'pool_name'
START_IP = 'start_ip'
END_IP = 'end_ip'

def generate_table_entry(pool_name, ip_address_entry):
    return 'INSERT INTO radippool (pool_name, framedipaddress) VALUES (\'%s\', \'%s\');\n' % (pool_name, ip_address_entry)

def generate_pool_entries(pool_name, start_ip, end_ip):
    start = ipaddress.ip_address(start_ip)
    end = ipaddress.ip_address(end_ip)
    entries = []
    while start <= end:
        entries.append(generate_table_entry(pool_name, start))
        start += 1
    return entries

def main():
    if len(sys.argv) < 3:
        print('Please provide INPUT_FILE OUTPUT_FILE')
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2]

    f = open(input_file)
    data = json.load(f)
    f.close()

    all_entries = []

    for value in data[IP_POOLS]:
        pool_name = value[POOL_NAME]
        start_ip = value[START_IP]
        end_ip = value[END_IP]

        all_entries.extend(generate_pool_entries(pool_name, start_ip, end_ip))


    f = open(output_file, 'w')
    f.writelines(all_entries)
    f.close()

if __name__ == '__main__':
    main()
