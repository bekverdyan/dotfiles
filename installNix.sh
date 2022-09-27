#!/bin/bash

if [ $(uname -r | sed -n 's/.*\( *Microsoft *\).*/\1/pi') ]
then
	echo "Installing Nix for WSL"
	sh <(curl -L https://nixos.org/nix/install) --no-daemon
else
	echo "Installing Nix for Regular OS"
	sh <(curl -L https://nixos.org/nix/install) --daemon
fi
