#!/bin/bash

if [ "$TAILSCALE_ENABLE" == "true" ]; then
	tailscaled --tun=userspace-networking &
	sleep 10  # Give a short pause to let tailscaled start
	tailscale up
fi