#!/bin/bash

sudo mv /usr/bin/zsh /usr/bin/zsh-orig
sudo ln -sf $(which zsh) /usr/bin/zsh
