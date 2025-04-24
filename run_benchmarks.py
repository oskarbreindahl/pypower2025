#!/usr/bin/env python3
import time
import paramiko
from otii_tcp_client import otii_client

class AppException(Exception):
    '''Application Exception'''

def run_benchmarks(otii, version, hostname, username, password):
    # Define command to run script
    command = "./run_benchmarks.sh " + version

    # Get a reference to a Arc or Ace device
    devices = otii.get_devices()
    if len(devices) == 0:
        raise AppException('No Arc or Ace connected!')
    device = devices[0]

    # Configure the device
    device.set_main_voltage(5.1)
    device.set_exp_voltage(4.9)
    device.set_max_current(2.5)

    # Enable the main current channel
    device.enable_channel('mp', True)
    device.enable_channel('mc', True)

    try:
        # Create an SSH client
        ssh_client = paramiko.SSHClient()
        ssh_client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        
        # Connect to the SSH server
        print(f"Connecting to {username}@{hostname}...")
        ssh_client.connect(hostname, username=username, password=password)
        print("Connection established.")

        # Execute the command
        proj.start_recording()
        print(f"Running command: {command}")
        stdin, stdout, stderr = ssh_client.exec_command(command)

        # Wait for the command to complete and fetch outputs
        exit_status = stdout.channel.recv_exit_status()
        print(f"Command completed with exit status: {exit_status}")
        proj.stop_recording()

        # Print the standard output and error
        print("Standard Output:")
        for line in stdout.read().decode().splitlines():
            print(line)

        print("Standard Error:")
        for line in stderr.read().decode().splitlines():
            print(line)
            
    except Exception as e:
        print(f"An error occurred: {e}")
    
    finally:
        # Close the connection
        ssh_client.close()
        print("Connection closed.")

    # Get statistics for the recording
    recording = project.get_last_recording()
    info = recording.get_channel_info(device.id, 'mp')
    statistics_mp = recording.get_channel_statistics(device.id, 'mp', info['from'], info['to'])
    

    # Print the statistics
    print(f'From:        {info["from"]} s')
    print(f'To:          {info["to"]} s')
    print(f'Offset:      {info["offset"]} s')
    print(f'Sample rate: {info["sample_rate"]}')
    print(f'Min:         {statistics_mp["min"]:.5} W')
    print(f'Max:         {statistics_mp["max"]:.5} W')
    print(f'Average:     {statistics_mp["average"]:.5} W')


def main():
    '''Connect to the Otii 3 application and run the measurement'''
    client = otii_client.OtiiClient()
    with client.connect() as otii:
        run_benchmarks(otii, "3.9", "oskar", "10.7.7.176", "year1191")

if __name__ == '__main__':
    main()
