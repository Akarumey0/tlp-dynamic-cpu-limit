# tlp-dynamic-cpu-limit
Automatic Intel CPU frequency limits for TLP power-saver, balanced and performance profiles on Linux.

TLP Dynamic CPU Limit

Automatically limit Intel CPU frequency according to the active TLP power profile on Linux.

This project connects TLP power profiles with "cpupower", allowing the maximum CPU frequency to change automatically when the user switches between Power Saver, Balanced and Performance modes.

Tested Configuration

This configuration was developed and tested on:

- Laptop: Dell G7 7790
- CPU: Intel Core i7-9750H
- OS: Manjaro Linux
- TLP: 1.10.2
- CPU scaling driver: "intel_pstate"
- CPU cores/threads: 12 logical CPUs

It may also work on other Linux systems using TLP, systemd, "cpupower" and a compatible CPU frequency scaling driver.

How It Works

The system monitors the active power profile provided by "tlp-pd".

When the profile changes, the listener automatically applies a corresponding CPU maximum frequency using "cpupower".

TLP Power Profile
        │
        ▼
     tlp-pd
        │
        ▼
cpu-power-profile.service
        │
        ▼
 profile-listener.sh
        │
        ├── Power Saver  → 1.0 GHz
        ├── Balanced    → 2.6 GHz
        └── Performance → 4.5 GHz

CPU Frequency Limits

Power Profile| Maximum CPU Frequency
Power Saver| 1.0 GHz
Balanced| 2.6 GHz
Performance| 4.5 GHz

The minimum frequency remains controlled by the CPU frequency scaling driver.

For example, Power Saver results in:

800 MHz – 1.00 GHz

Balanced:

800 MHz – 2.60 GHz

Performance:

800 MHz – 4.50 GHz

Why Use This?

TLP already provides power profiles, but the CPU frequency limit can be controlled separately.

This project combines the two so that changing the power profile also changes the CPU maximum frequency automatically.

For example:

Power Saver

Lower CPU frequency
       ↓
Lower CPU performance
       ↓
Potentially lower power consumption
       ↓
Longer battery runtime

Performance

Higher CPU frequency
       ↓
Higher CPU performance

The user does not need to manually run "cpupower frequency-set" every time the power profile changes.

Requirements

The following components are required:

- Linux
- systemd
- TLP
- "tlp-pd"
- "cpupower"
- "gdbus"
- a compatible CPU frequency scaling driver

On the tested system, the required commands are located at:

/usr/bin/tlp
/usr/bin/tlp-stat
/usr/bin/cpupower
/usr/bin/gdbus
/usr/bin/systemctl

Important

This configuration modifies system-level power management.

Before applying it, make sure you understand the files being installed and keep a way to restore the original configuration.

The configuration was developed specifically around the tested environment. Different Linux distributions, TLP versions, CPUs or scaling drivers may require modifications.

Files

tlp-dynamic-cpu-limit/
├── README.md
├── install.sh
├── uninstall.sh
├── systemd/
│   ├── cpu-power-profile.service
│   └── tlp-pd-override.conf
└── scripts/
    ├── profile-listener.sh
    ├── minimum-power
    ├── medium-power
    └── ultra-power

"profile-listener.sh"

Detects the current TLP profile when started and monitors profile changes through the "UPower.PowerProfiles" D-Bus interface.

"minimum-power"

Sets the CPU maximum frequency to 1 GHz.

"medium-power"

Sets the CPU maximum frequency to 2.6 GHz.

"ultra-power"

Sets the CPU maximum frequency to 4.5 GHz.

"cpu-power-profile.service"

Runs the profile listener as a systemd service.

"tlp-pd-override.conf"

Connects the CPU profile service to "tlp-pd".

Verification

After installation, check the active TLP profile:

tlp-stat -s

Check the CPU frequency policy:

cpupower frequency-info | grep "current policy"

For Power Saver you should see approximately:

current policy: frequency should be within 800 MHz and 1000 MHz.

For Balanced:

current policy: frequency should be within 800 MHz and 2.60 GHz.

For Performance:

current policy: frequency should be within 800 MHz and 4.50 GHz.

Testing Profile Switching

Switch to Power Saver:

sudo tlp power-saver

Then:

sleep 2
cpupower frequency-info | grep "current policy"

Expected maximum:

1000 MHz

Switch to Balanced:

sudo tlp balanced

Then:

sleep 2
cpupower frequency-info | grep "current policy"

Expected maximum:

2.60 GHz

Switch to Performance:

sudo tlp performance

Then:

sleep 2
cpupower frequency-info | grep "current policy"

Expected maximum:

4.50 GHz

The same switching mechanism can be triggered from the graphical desktop power-profile interface.

systemd Startup

The CPU profile service is connected to "tlp-pd".

This is important because "tlp-pd" provides the power-profile D-Bus interface that the listener monitors.

The service is not intended to be independently enabled as a normal startup dependency. Instead, the "tlp-pd" integration starts it when required.

Troubleshooting

Check the TLP profile:

tlp-stat -s

Check "tlp-pd":

systemctl status tlp-pd.service --no-pager

Check the CPU profile service:

systemctl status cpu-power-profile.service --no-pager

Check the current CPU policy:

cpupower frequency-info | grep "current policy"

Check the service definition:

systemctl cat cpu-power-profile.service

Check the "tlp-pd" override:

systemctl cat tlp-pd.service

Known systemd Dependency Consideration

During development, an initial configuration attempted to enable the CPU profile service through both "multi-user.target" and "graphical.target".

This resulted in a systemd ordering cycle involving "tlp-pd.service", "multi-user.target" and "cpu-power-profile.service".

The final configuration avoids this approach and instead connects the CPU profile service to "tlp-pd" using a systemd drop-in.

This is an important detail if you modify the configuration.

Uninstall

Use the provided uninstall script:

sudo ./uninstall.sh

After removing the configuration, reload systemd:

sudo systemctl daemon-reload

Then verify that the custom service and "tlp-pd" drop-in have been removed.

Disclaimer

This project changes CPU frequency limits and system power-management behavior.

Use it at your own risk.

CPU frequency behavior depends on the Linux kernel, CPU scaling driver, firmware, TLP configuration and hardware.

The values in this repository were tested on a Dell G7 7790 with an Intel Core i7-9750H.

License

This project is provided as-is for educational and practical use.