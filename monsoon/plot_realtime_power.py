#!/usr/bin/env python

import Monsoon.LVPM as LVPM
import Monsoon.HVPM as HVPM
from Monsoon import sampleEngine
import argparse
import csv
import os
from matplotlib import pyplot as plt
import threading
import collections
import signal
import sys
from http.server import BaseHTTPRequestHandler
import http.server
import socketserver
from urllib.parse import urlparse, parse_qs
import numpy as np
import requests

PORT = 5002
is_sampling = False
fig, ax = plt.subplots()
plt.ylabel('amperage (mA)')
plt.xlabel('time sequences')
plt.ylim((0, 2000))

display_range = 50000
samples_queue = collections.deque(maxlen=display_range)
time_queue = collections.deque(maxlen=display_range)

time_queue.extend([0 for _ in range(display_range)])
samples_queue.extend([0 for _ in range(display_range)])
line, = ax.plot(time_queue, samples_queue, linewidth=0.5)

should_pause = False
csv_file_handle = None
csv_writer = None
trigger_count = 0
trigger = float("inf")
triggered = False
header = ["Time(ms)", "Main(mA)", "Main Voltage(V)"]
is_test_complete = False
inference_complete = False
sampling_completed_event = threading.Event()

class MonsoonHTTPServerHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        # Parse query data & params to find out what was passed
        parsed_params = urlparse(self.path)
        query_parsed = parse_qs(parsed_params.query)
        print(f"Received a GET request for {parsed_params.path}")
        # Process a start sampling request
        if parsed_params.path == "/start-sampling":
            self.handle_start_sampling()
        # Process a stop sampling request
        elif parsed_params.path == "/stop-sampling":
            self.handle_stop_sampling()
        # Process a pause display request
        elif parsed_params.path == "/pause-display":
            self.handle_pause_display()
        # Process a resume display request
        elif parsed_params.path == "/resume-display":
            self.handle_resume_display()
        else:
            # Serve files, and handle requests for files that do not exist
            super().do_GET()

    def handle_start_sampling(self):
        global is_sampling, engine, sample_number
        if not is_sampling:
            print("Start sampling requested.")
            if engine is not None:
                try:
                    pt = threading.Thread(target=sample_generator, args=(engine, sample_number))
                    pt.daemon = True
                    pt.start()
                    is_sampling = True
                    self.send_response(200)
                    self.end_headers()
                    self.wfile.write(b'Started sampling')
                except Exception as e:
                    self.send_error(500, str(e))
            else:
                self.send_error(500, "Engine not initialized.")
        else:
            self.send_response(409)  # Conflict status code
            self.end_headers()
            self.wfile.write(b'Already sampling')

    def handle_stop_sampling(self):
        global is_sampling, monsoon, csv_file_handle
        if is_sampling:
            print("Stop sampling requested.")
            is_sampling = False
            try:
                monsoon.stopSampling()
                if csv_file_handle:
                    csv_file_handle.close()
                    csv_file_handle = None
                    # calculate_energy(csv_file)
                is_sampling = False
                self.send_response(200)
                self.end_headers()
                self.wfile.write(b'Stopped sampling')
            except Exception as e:
                self.send_error(500, str(e))
        else:
            self.send_response(409)  # Conflict status code
            self.end_headers()
            self.wfile.write(b'Not currently sampling')

def sample_generator(sampler, sample_number_):
    try:
        sampler.startSampling(sample_number_, output_callback=samples_callback)
    finally:
        sampling_completed_event.set()

def samples_callback(samples_):
    global is_sampling, is_test_complete
    if not is_sampling or is_test_complete:
        return
    last_values = samples_[sampleEngine.channels.MainCurrent]
    if last_values:
        # filter negative values
        valid_values = [max(v, 0) for v in last_values]
        time_queue.extend(samples_[sampleEngine.channels.timeStamp])
        samples_queue.extend(valid_values)
        avg = sum(valid_values) / len(valid_values)
        global triggered
        if avg > trigger:
            global csv_file_handle, csv_writer
            if csv_file_handle:
                print("recording", avg, len(valid_values))

                records = list(zip(samples_[sampleEngine.channels.timeStamp],
                                   samples_[sampleEngine.channels.MainCurrent],
                                   samples_[2]))
                if not csv_writer:
                    csv_writer = csv.writer(csv_file_handle)
                    csv_writer.writerow(header)
                csv_writer.writerows(records)
                triggered = True
        else:
            if triggered and csv_file_handle:
                print("stopped trigger")
                csv_file_handle.close()
                csv_file_handle = None


class MyTCPServer(socketserver.TCPServer):
    allow_reuse_address = True


def run_server():
    global is_test_complete
    with MyTCPServer(("", PORT), MonsoonHTTPServerHandler) as httpd:
        print("serving at port", PORT)
        while not is_test_complete:
            httpd.serve_forever()


def start_server():
    server_thread = threading.Thread(target=run_server)
    server_thread.daemon = True
    server_thread.start()

def animate(_):
    if should_pause:
        return line,
    line.set_xdata(time_queue)
    line.set_ydata(samples_queue)  # update the data
    ax.relim()
    for label in ax.xaxis.get_ticklabels()[::100]:
        label.set_visible(False)
    ax.autoscale_view(True, True, True)
    return line,

def on_click(_event):
    global should_pause
    if _event.dblclick:
        should_pause ^= True

def calculate_energy(csv_file):
    global is_test_complete
    is_test_complete = True
    times = []
    powers = []
    with open(csv_file, 'r') as f:
        reader = csv.reader(f)
        next(reader)  # Skip header
        for row in reader:
            time_stamp = float(row[0])
            current = float(row[1])
            voltage = float(row[2])
            if voltage > 0:
                times.append(time_stamp)
                powers.append(current * voltage)  # Calculate power using current and voltage

    duration = (times[-1] - times[0])
    energy = np.trapz(np.asarray(powers, dtype=float), x=np.asarray(times, dtype=float))
    os.remove(csv_file)
    return (energy / 3600) / 500, energy / duration  # / 500 due to taking average of 500 inferences

def trigger_inference_on_device(model_name, device_type):
    url = 'http://10.0.0.198:8080/runInference?model={}&device={}'.format(model_name, device_type)
    response = requests.get(url)
    print(response.text)

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("-n", "--number_of_samples", type=int, default=-1,
                        help="number of power samples per second, default to -1 meaning sample infinitely")
    parser.add_argument("-m", "--monsoon_model", choices=("lvpm", "hvpm", "l", "h", "black", "white", "b", "w"),
                        default="hvpm",
                        help="Monsoon type, either white(w,l,lvpm) or black(b,h,hvpm)")
    parser.add_argument("-s", "--save_file", type=str, default=None,
                        help="file to save power samples")
    parser.add_argument("-t", "--trigger", type=float, default=float("inf"),
                        help="threshold to trigger sampling, unit is mA")
    parser.add_argument("--model", type=str, default="efficientnet-b0",
                        help="model name to use for inference")
    parser.add_argument("--device", type=str, default="CPU",
                        help="device type for inference (CPU/GPU/ANE)")
    parser.add_argument("--times", type=int, default=1,
                        help="number of times to run the test")

    args = parser.parse_args()

    sample_number = args.number_of_samples if args.number_of_samples > 0 else sampleEngine.triggers.SAMPLECOUNT_INFINITE
    monsoon_model = args.monsoon_model
    if monsoon_model.startswith('l') or monsoon_model.startswith('w'):
        monsoon = LVPM.Monsoon()  # white
    else:
        monsoon = HVPM.Monsoon()
    monsoon.setup_usb()
    print("Monsoon Power Monitor Serial number: {}".format(monsoon.getSerialNumber()))
    engine = sampleEngine.SampleEngine(monsoon)
    trigger = args.trigger
    model_name = args.model
    device_type = args.device

    def signal_handler(_signal, _frame):
        print('You pressed Ctrl+C, clearing monsoon sampling and exit!')
        monsoon.stopSampling()
        sys.exit(0)

    def handle_close(_event):
        print('You cosed figure, clearing monsoon sampling and exit!')
        monsoon.stopSampling()
        sys.exit(0)

    fig.canvas.mpl_connect('close_event', handle_close)
    fig.canvas.mpl_connect('button_press_event', on_click)

    signal.signal(signal.SIGINT, signal_handler)

    energies = []
    powers = []
    for i in range(args.times):
        is_test_complete = False
        current_csv_file = None
        csv_file_handle = None
        if args.save_file:
            base_file_name, file_extension = os.path.splitext(args.save_file)
            current_csv_file = f"{base_file_name}_run{i+1}{file_extension}"
            csv_file_handle = open(current_csv_file, 'w')
            engine.enableCSVOutput(current_csv_file)
        start_server()
        trigger_inference_on_device(model_name, device_type)
        sampling_completed_event.wait()
        try:
            energy_mAh, power_mW = calculate_energy(current_csv_file)
            energies.append(energy_mAh)
            powers.append(power_mW)
            print(f"Run {i+1}/{args.times}: {energy_mAh} mAh, {power_mW} mW")
        except Exception as e:
            print(f"An error occurred during run {i+1}: {e}")
        finally:
            # Clean up for the next run
            if monsoon is not None:
                monsoon.stopSampling()
            if csv_file_handle is not None:
                csv_file_handle.close()
    if energies:
        average_energy = sum(energies) / len(energies)
        average_power = sum(powers) / len(powers)
        print(f"Average energy over {args.times} runs: {average_energy} mAh")
        print(f"Average power over {args.times} runs: {average_power} mW")
    else:
        print("No energy data was collected.")
    print("All tests complete, cleaning up.")

