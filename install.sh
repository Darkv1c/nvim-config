#!/bin/bash

# Fix terminal type
export TERM=xterm-256color
echo 'export TERM=xterm-256color' >> ~/.bashrc

# apt upgrade
sudo apt-get update
sudo apt-get upgrade

sudo apt-get install neovim
