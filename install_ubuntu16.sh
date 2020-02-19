#!/bin/sh
BOLD='\033[0;1m'
RED='\033[0;31m'
NC='\033[0m' # No Color

print_log()
{
    msg=$1
    printf "${RED}[*]${NC} ${BOLD}${msg}${NC}\n"
}

print_log "Installing cross compiler Package"
sudo apt-get update -y
sudo apt-get install -y binutils bison flex libtool make patchutils libgmp-dev libmpfr-dev gcc-multilib
sudo apt-get install -y libiconv-hook-dev libc6-dev

print_log "Checking gcc multilib options"
gcc -dumpspecs | grep -A1 multilib_options

print_log "Installing Package"
sudo apt-get install nasm
sudo apt-get install qemu
print_log "Done!"