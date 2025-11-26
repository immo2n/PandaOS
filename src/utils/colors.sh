#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m'
DIM='\033[2m'

CHECKMARK='✓'
CROSS='✗'
ARROW='→'
STAR='★'
GEAR='⚙'
FOLDER='📁'
FILE='📄'
PACKAGE='📦'
ROCKET='🚀'
PANDA='🐼'

print_header() {
    echo -e "${BOLD}${CYAN}${STAR} ${1}${NC}"
}

print_success() {
    echo -e "${GREEN}${CHECKMARK} ${1}${NC}"
}

print_error() {
    echo -e "${RED}${CROSS} ${1}${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠  ${1}${NC}"
}

print_info() {
    echo -e "${BLUE}${ARROW} ${1}${NC}"
}

print_step() {
    echo -e "${BOLD}${MAGENTA}${GEAR} ${1}${NC}"
}

print_progress() {
    echo -e "${CYAN}  ${ARROW} ${1}${NC}"
}

print_complete() {
    echo -e "${GREEN}${CHECKMARK} ${1}${NC}"
}

show_progress() {
    local current=$1
    local total=$2
    local width=50
    local percentage=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))
    
    printf "\r${CYAN}["
    printf "%${filled}s" | tr ' ' '█'
    printf "%${empty}s" | tr ' ' '░'
    printf "] ${percentage}%%${NC}"
    
    if [ $current -eq $total ]; then
        echo ""
    fi
}

spinner() {
    local pid=$1
    local message=$2
    local spin='-\|/'
    local i=0
    
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) %4 ))
        printf "\r${CYAN}${spin:$i:1} ${message}${NC}"
        sleep 0.1
    done
    printf "\r${GREEN}${CHECKMARK} ${message}${NC}\n"
}
