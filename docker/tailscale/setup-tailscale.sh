#!/bin/bash

if [ "$TAILSCALE_ENABLE" == "true" ]; then
	curl -sSL https://tailscale.com/install.sh | sh
	if [ $? -ne 0 ]; then
		echo "Tailscale installation failed!"
		exit 1
	fi

	# Start the Tailscale daemon
	tailscaled --tun=userspace-networking &

	sleep 10  # Give a short pause to let tailscaled start

	# Check if SSH is enabled
	SSH_OPTION=""
	if [ "$TAILSCALE_ENABLE_SSH" == "true" ]; then
		SSH_OPTION="--ssh"
	fi

	# Set up Tailscale with the provided auth key
	tailscale up $SSH_OPTION --hostname="LiveStreamDVR" --authkey=$TAILSCALE_AUTH_KEY

	# Set up the other Tailscale commands
	tailscale serve https:443 / http://127.0.0.1:$TCD_SERVER_PORT
	tailscale funnel 443 on
fi
