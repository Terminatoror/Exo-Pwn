# Exo-Pwn

Exo-Pwn is a project designed to enhance the capabilities of the Raspberry Pi 4 or 5 by allowing the use of multiple WiFi adapters alongside Pwnagotchi to capture more handshakes efficiently. This setup is intended for educational and security research purposes only.

## Disclaimer

**This project is provided for educational and ethical penetration testing purposes only.** Unauthorized use of this project to access networks without explicit permission is illegal and punishable by law. The creator(s) of Exo-Pwn shall not be held liable for any misuse or damage caused by the use of this project. **Use at your own risk.**

## Features

- Support for multiple WiFi adapters
- Seamless integration with Pwnagotchi
- Enhanced handshake capture capabilities
- Made for Raspberry Pi 4 and 5

## Prerequisites

Before you begin, ensure you have the following:

- Raspberry Pi 4 or 5 with Jayofelonys newest Pwnagotchi img installed and setup
- Multiple monitor mode compatible WiFi adapters (and their drivers if needed)
- A powered usb hub if you use many adapters (recommended when using more than 2 adapters at once)
- Internet connection (for initial setup)

## Installation

1. **[optional] Root login to Raspberry Pi:**

   ```bash
   sudo passwd root #root root
   sudo nano /etc/ssh/sshd_config
   ```

   - Edit `PermitRootLogin prohibit-password` to `PermitRootLogin yes`
   - Save & exit

   ```bash
   sudo systemctl restart sshd
   ```

   - Try logging in: `root` `root`

2. **Install hashcat-utils:**

   ```bash
   git clone https://github.com/hashcat/hashcat-utils.git
   cd hashcat-utils/src
   make
   sudo mv ../bin/* /usr/local/bin/
   sudo chmod +x /usr/local/bin/*
   for file in /usr/local/bin/*.bin; do sudo mv "$file" "${file%.bin}"; done
   ```

3. **Install hcxtools:**

   ```bash
   git clone https://github.com/ZerBea/hcxtools.git
   cd hcxtools
   sudo make install
   ls -la /usr/bin | grep hcx
   ```

4. **Install additional dependencies:**

   ```bash
   sudo apt install jq wireshark
   ```

5. **Clone and install updated hcxtools:**

   ```bash
   mv hcxtools/ hcxtools1
   git clone https://github.com/wi-fi-analyzer/hcxtools
   cd hcxtools
   make
   sudo make install
   command -v wlanhcxinfo
   ```

6. **Set up handshakes directory:**

   ```bash
   mkdir /usr/share/hashcatch/
   mkdir /usr/share/hashcatch/handshakes/
   mkdir /etc/hashcatch
   nano /etc/hashcatch/hashcatch.conf
   ```

7. **Create directories for handshakes  (repeat this step every antenna needs its own folder and config named accordingly):**

   ```bash
   cd /
   mkdir handshakes2
   nano handshakes2/2.conf
   ```

8. **Run second**\_pwn.sh setup (repeat this step for every antenna, e.g., **second\_pwn2.sh --setup):**

   ```bash
   sudo second_pwn.sh --setup
   sudo second_pwn.sh #can be closed instantly, it's just to test if it's set up correctly
   ```

9. **Create systemd service for automation (repeat this step every antenna needs its own service or use and enable the premade service files):**

   ```bash
   sudo nano /etc/systemd/system/second_pwn.service
   ```

   **Content:**

   ```
   [Unit]
   Description=Secondary Pwn Script
   After=network.target

   [Service]
   Type=simple
   ExecStart=/bin/bash /second_pwn.sh
   Restart=always
   RestartSec=5
   User=root
   Group=root

   [Install]
   WantedBy=multi-user.target
   ```

10. **Enable and start the service:**

    ```bash
    sudo systemctl daemon-reload
    sudo systemctl enable second_pwn.service
    sudo systemctl start second_pwn.service
    sudo systemctl status second_pwn.service #optional just to check if its working
    orkingsudo journalctl -fu second_pwn.service  #optional just to check if its working
    ```

11. **Enable plugins in Pwnagotchi:**

    - Place the required plugin(s) in the Pwnagotchi custom plugins folder:

      ```bash
      /usr/local/src/pwnagotchi/custom_plugins/
      ```

    - Enable the plugins by adding them to the Pwnagotchi config.toml or enabling them in the web-ui.

    - Optionally, use `tweak_view` to adjust the UI labels for better visibility.

## Usage

- Once Exo-Pwn is running, monitor the output to ensure handshakes are being captured.
- The plugins display the pcap count of each "Head" aswell as the total count. if an antenna isnt connected or the service isnt working correctly for some unknown reason the plugin(s) will display "Head: X".
- Adjust adapter configurations as needed for optimal performance (optional but depending on the adapters used you could turn down the TX strength a bit to prevent bad pcaps due to interference).

## Troubleshooting

- **WiFi adapter not recognized?** Ensure drivers are installed and the device is supported. (see if they appear in iwconfig)
- **Power issues?** Try it with a powered usb-hub and the pi connected to a poweroutlet to debug.
- **Pwnagotchi not detecting plugins?** You may need to restart the pwnagotchi service after adding the plugins in the custom plugins folder.

## Contributing

Feel free to open issues and pull requests to improve Exo-Pwn. Contributions are always welcome!

# Project Notice

This repository and its associated script are **heavily based on** [hashcatch](https://github.com/staz0t/hashcatch).  
Until the integration with **AngryOxide** has been thoroughly tested and validated, the current implementation relies significantly on hashcatch's original functionality.  

We appreciate the work done by the original developers of hashcatch and will continue refining the integration to enhance performance and reliability.  

**Remember:** Always use Exo-Pwn responsibly and within legal boundaries.

