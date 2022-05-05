#!/bin/bash
settings() {
	timeout 5s nordvpn s technology NordLynx
#	timeout 5s nordvpn s protocol udp
        timeout 5s nordvpn s ipv6 on
	timeout 5s nordvpn s killswitch on
	timeout 5s nordvpn s cybersec on
#	timeout 5s nordvpn s obfuscate off
	timeout 5s nordvpn s notify off
	timeout 5s nordvpn s autoconnect on
	timeout 5s nordvpn s dns 1.1.1.1 8.8.8.8
	timeout 5s nordvpn whitelist add subnet 192.168.0.0/24 #my local subnet
        timeout 5s nordvpn whitelist add ports 137 139 #NetBIOS
        timeout 5s nordvpn whitelist add ports 443 445 #HTTP over SSL, MSFT DS
        timeout 5s nordvpn whitelist add port 143 #IMAP4
        timeout 5s nordvpn whitelist add port 2302 #Halo
        timeout 5s nordvpn whitelist add ports 6881 6889 #BitTorrent
}

reconnect() {
	timeout 5s nordvpn d	
	timeout 5s nordvpn c us
}

restartvpnservices() {
	systemctl restart nordvpn.service | systemctl restart nordvpnd.service
}

check() {
	timeout 5s bash -c 'nordvpn status | grep -q "Status: Connected"'
}

checkdis1() {
	timeout 5s bash -c 'nordvpn d | grep -q "You are disconnected from NordVPN."'
}

checkdis2() {
	timeout 5s bash -c 'nordvpn d | grep -q "You are not connected to NordVPN."'
}

# Connection check.
settings
reconnect
echo "$(date) [Checking VPN connectivity]"
if ! check; then
	echo "$(date) [Check failed, trying again in 3s]"
	sleep 3	
	reconnect
	if ! check; then
		echo "$(date) [Reconnect failed, trying again in 3s]"
		sleep 3
		reconnect
		if ! check; then
			echo "$(date) [Second reconnect failed, restarting NordVPN (30s)"
			restartvpnservices
			sleep 30
			settings
			reconnect
			echo "$(date) [Checking VPN connectivity]"
			if ! check; then
				echo "$(date) [Check failed, trying again in 3s]"
				sleep 3
				reconnect
				if ! check; then
					echo "$(date) [Check failed again, starting VPN]"
					reconnect
					if ! check; then
						echo "$(date) [Reconnect failed, trying again in 3s]"
						sleep 3
						reconnect
						if ! check; then
							echo "$(date) [Second reconnect failed, restart the system to regain connection with the VPN service]"
							sleep 99999999999999999999999999999999 #practically waits for infinite time
						fi
					fi
				fi
			fi
		fi
	fi
fi

# Disconnect check to ensure it doesn't claim to be connected while it actually isn't. Blame NordVPN for this one, not the script.
if ! checkdis1; then
	echo "$(date) [Disconnect check failed, restarting NordVPN (30s)]"
	restartvpnservices
	sleep 30
	settings
	if ! checkdis2; then
		echo "$(date) [Disconnect check failed, restart the system to regain connection with the VPN service]"
		sleep 99999999999999999999999999999999 #practically waits for infinite time
	fi
fi

# Final connection attempt activated when everything goes well.
reconnect
echo "$(date) [VPN connected!]"
sleep 5
# exit cleanly
exit 0

