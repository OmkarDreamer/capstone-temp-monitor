# Smart Temperature Monitor

A hands-on Linux capstone project consisting of:

- A Linux character-device driver (`tempsensor.ko`)
- The `/dev/tempsensor` device node
- A simulated random-walk temperature source
- A C++ userspace state machine
- `ioctl()` controls for reset and drift rate
- NORMAL / WARNING / CRITICAL state classification

## Architecture

```text
C++ Application
      |
      | open() / read() / ioctl()
      v
/dev/tempsensor
      |
      v
tempsensor.ko
      |
      v
Kernel random-number generator
```

The driver returns one simulated temperature reading per open/read cycle.
The C++ application intentionally opens, reads, and closes the device for
each reading, matching the driver design and ordinary `cat /dev/tempsensor`
behavior.

## State machine

| Temperature | State |
|---|---|
| `< 60.0 C` | NORMAL |
| `60.0–80.0 C` | WARNING |
| `> 80.0 C` | CRITICAL |

A transition is printed only when the state changes.

## 1. Required environment

Use a real Ubuntu machine or a VirtualBox/VMware Ubuntu VM. Do **not** use
WSL2's default kernel for this project because the project requires loading a
custom kernel module.

Recommended Ubuntu: 22.04 or 24.04 LTS.

## 2. Install dependencies

From the project root:

```bash
chmod +x scripts/*.sh
./scripts/install_dependencies.sh
```

Or install manually:

```bash
sudo apt update
sudo apt install -y build-essential linux-headers-$(uname -r) g++ make git
```

Verify the running kernel and matching headers:

```bash
uname -r
ls -ld /lib/modules/$(uname -r)/build
ls /usr/src/linux-headers-$(uname -r)
```

## 3. Build the driver

```bash
cd driver
make
ls -lh tempsensor.ko
```

If the build succeeds, `tempsensor.ko` is created.

## 4. Load the driver

```bash
sudo insmod tempsensor.ko
lsmod | grep tempsensor
ls -l /dev/tempsensor
sudo dmesg | tail -10
```

The device `/dev/tempsensor` should exist.

## 5. Test the driver directly

```bash
sudo cat /dev/tempsensor
sudo cat /dev/tempsensor
sudo cat /dev/tempsensor
```

Each command should print one temperature such as `25.3` followed by a newline.
The exact value changes because the sensor uses a random walk.

## 6. Build the C++ application

```bash
cd ../app
g++ -Wall -Wextra -O2 -std=c++17 -o temp_monitor temp_monitor.cpp
ls -lh temp_monitor
```

## 7. Run the application

Normal operation:

```bash
sudo ./temp_monitor
```

Stop with `Ctrl+C`.

### Reset the sensor

```bash
sudo ./temp_monitor --reset
```

This returns the simulated temperature to its 25.0 C baseline.

### Increase drift for a live demo

```bash
sudo ./temp_monitor --drift 40
```

`40` means up to 4.0 C of movement per reading.

## 8. Save the real execution output

From the project root:

```bash
mkdir -p output
sudo ./app/temp_monitor --reset
sudo ./app/temp_monitor --drift 40 | tee output/temperature_output.txt
```

Let it run until you have demonstrated NORMAL, WARNING, and CRITICAL. Then
press `Ctrl+C`.

Check the saved file:

```bash
cat output/temperature_output.txt
```

Do not fabricate output values; commit the output produced by your actual VM.

## 9. One-command build/demo helper

After dependencies are installed:

```bash
./scripts/build_and_run.sh
```

This builds the driver, loads it, builds the C++ app, resets the sensor, sets
the demo drift, and saves the monitoring output to `output/temperature_output.txt`.
Press `Ctrl+C` after the required states have appeared.

## 10. Stop/unload the driver

```bash
./scripts/stop_driver.sh
```

Or manually:

```bash
sudo rmmod tempsensor
sudo dmesg | tail -10
```

## 11. GitHub submission

From the project root:

```bash
git status
git add .
git commit -m "Complete Smart Temperature Monitor demo"
git push
```

The recommended repository structure is:

```text
capstone-temp-monitor/
├── README.md
├── .gitignore
├── driver/
│   ├── Makefile
│   ├── tempsensor.c
│   └── tempsensor_ioctl.h
├── app/
│   └── temp_monitor.cpp
├── scripts/
│   ├── install_dependencies.sh
│   ├── build_and_run.sh
│   └── stop_driver.sh
├── output/
│   ├── README.md
│   └── temperature_output.txt   # generated during the real demo
└── screenshots/
    └── # add your real VM screenshots here
```

## Suggested screenshots for evaluation

1. `uname -r` and installed headers
2. Successful `make` showing `tempsensor.ko`
3. `ls -l /dev/tempsensor` after `insmod`
4. `sudo cat /dev/tempsensor`
5. C++ monitor showing state transitions

## Troubleshooting

### Missing kernel build directory

```bash
ls -l /lib/modules/$(uname -r)/build
```

If missing:

```bash
sudo apt update
sudo apt install -y linux-headers-$(uname -r)
```

Then rebuild:

```bash
cd driver
make clean
make
```

### `/dev/tempsensor` does not exist

```bash
lsmod | grep tempsensor
sudo dmesg | tail -30
```

If the module is not loaded:

```bash
cd driver
sudo insmod tempsensor.ko
```

### C++ application cannot open the device

Check:

```bash
ls -l /dev/tempsensor
lsmod | grep tempsensor
```

Run the application with `sudo` as shown above.

## Project scope

This is a teaching/demo driver and simulated sensor, not a production hardware
sensor driver.
