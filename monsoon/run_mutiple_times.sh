NUM_RUNS=100
MODEL="efficientnet-b2"
DEVICE="ANE"
TRIGGER=105
SAVE_PATH="/output1"
SCRIPT_PATH="/plot_realtime_power.py"

sum_energy=0
sum_power=0

for ((i=1; i<=NUM_RUNS; i++))
do
    # Run the Python script and capture the output
    output=$(python "$SCRIPT_PATH" --trigger "$TRIGGER" --save_file "${SAVE_PATH}.csv" --model "$MODEL" --device "$DEVICE" --times 1)

    # Extract energy and power values from the output
    energy=$(echo "$output" | ggrep -oP 'Average energy over 1 runs: \K[0-9.]+')
    power=$(echo "$output" | ggrep -oP 'Average power over 1 runs: \K[0-9.]+')

    if [[ -n $energy && -n $power ]]; then
        echo "Energy: $energy mAh"
        echo "Power: $power mW"
    else
        echo "Failed to parse energy or power values."
    fi

    # Add to the sum variables
    sum_energy=$(echo "$sum_energy + $energy" | bc)
    sum_power=$(echo "$sum_power + $power" | bc)

done

avg_energy=$(echo "scale=3; $sum_energy / $NUM_RUNS" | bc)
avg_power=$(echo "scale=3; $sum_power / $NUM_RUNS" | bc)

# Output the average results
echo "Average energy over $NUM_RUNS runs: $avg_energy mAh"
echo "Average power over $NUM_RUNS runs: $avg_power mW"