# Monsoon Usage


## Install

for macos: 

`brew install libusb`
then
`python3 -m pip install -r requirements.txt`

for linux and windows: see [official guide](https://github.com/msoon/PyMonsoon)

## Plot realtime power

`python3 plot_realtime_power.py`

## Todo

- [ ] smoothing power values

- [ ] set trigger sampling (e.g. start sampling when the average power values within a short time period is larger than a threshold, take period and threshold as arguments)

- [ ] save data to csv files (already supported, need to test and document it)

## Notes

When using Monsoon to supply/measure power for Pixel 7 phone:

- turn off the phone, 
- disconnect battery, 
- connect Monsoon clips, 
- attach Monsoon data USB to the host computer, 
- use `set_power.py` to supply power (usually 4.2V), 
- then use `plot_realtime_power.py` to monitor power values
- turn on phone, run the workloads 

After finishing the power measurements: (switch to original phone battery to supply power)

- turn off the phone,
- disconnect Monsoon alligator clips,
- connect phone battery,
- use the type-c cable to connect phone and a power source or computer (this step is to activate phone battery chip, otherwise the phone cannot power on)
- turn on the phone and use if normally

