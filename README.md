# Mobile-Models-Automation-Tests

# Automated Benchmark Deployment of DNN Models on Mobile Devices (iOS)

## Overview
This repository is dedicated to the automated deployment and benchmarking of Deep Neural Network (DNN) models on mobile devices, specifically targeting iOS platforms. The primary focus is on assessing the energy efficiency and performance of these models when deployed in a real-world mobile environment.

## Running the Benchmark
The benchmark can be executed by running the `run_multiple_times.sh` script located in the `monsoon` directory. This script automates the process of deploying and running the DNN models on an iOS device (specifically tested on iPhone 12) for a specified number of iterations to gather accurate energy consumption data.

### Trigger Condition
The trigger for starting the model execution is set at 105mA. This value is based on the average mA of an iPhone 12 with no background activities, plus an additional 10% margin to ensure reliable triggering under varying conditions.

### Execution Details
- **Number of Runs**: The script is configured to run the model 100 times.
- **Data Collection**: During each run, the energy consumption is monitored and recorded.
- **Result Calculation**: After completing all runs, the script calculates the average energy consumption across all iterations to provide a reliable benchmark.

## Monsoon Integration
This project integrates with the Monsoon Power Monitor for precise energy measurement. For detailed information about the Monsoon setup and usage in this project, refer to our [Monsoon documentation](https://github.com/csarron/monsoon/tree/main).

## Getting Started
1. Ensure that your iOS device is set up correctly with no background activities.
2. Connect the device to the Monsoon Power Monitor.
3. Navigate to the `monsoon` directory and run the `run_multiple_times.sh` script.
4. The script will automatically start the benchmark process based on the defined trigger condition.
5. Upon completion, the script will output the average energy consumption data.

## Contributing
Contributions to this project are welcome. Please ensure that any pull requests or issues are relevant to the automation and benchmarking of DNN models on iOS devices.
