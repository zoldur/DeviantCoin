#!/bin/bash

TMP_FOLDER=$(mktemp -d)
CONFIG_FILE="Deviant.conf"
DEVIANT_DAEMON="/usr/local/bin/Deviantd"
DEVIANT_REPO="https://github.com/Deviantcoin/Wallet/raw/master/Deviantcoin%20(Linux)/Deviantd"
DEFAULTDEVIANTPORT=7118
DEFAULTDEVIANTUSER="deviant"
NODEIP=$(curl -s4 icanhazip.com)


RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'


function compile_error() {
if [ "$?" -gt "0" ];
 then
  echo -e "${RED}Failed to compile $@. Please investigate.${NC}"
  exit 1
fi
}


function checks() {
if [[ $(lsb_release -d) != *16.04* ]]; then
  echo -e "${RED}You are not running Ubuntu 16.04. Installation is cancelled.${NC}"
  exit 1
fi

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}$0 must be run as root.${NC}"
   exit 1
fi

if [ -n "$(pidof $DEVIANT_DAEMON)" ] || [ -e "$DEVIANT_DAEMOM" ] ; then
  echo -e "${GREEN}\c"
  read -e -p "Deviant is already installed. Do you want to add another MN? [Y/N]" NEW_DEVIANT
  echo -e "{NC}"
  clear
else
  NEW_DEVIANT="new"
fi
}

function prepare_system() {

echo -e "Prepare the system to install Deviant master node."
apt-get update >/dev/null 2>&1
DEBIAN_FRONTEND=noninteractive apt-get update > /dev/null 2>&1
DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -y -qq upgrade >/dev/null 2>&1
apt install -y software-properties-common >/dev/null 2>&1
echo -e "${GREEN}Adding bitcoin PPA repository"
apt-add-repository -y ppa:bitcoin/bitcoin >/dev/null 2>&1
echo -e "Installing required packages, it may take some time to finish.${NC}"
apt-get update >/dev/null 2>&1
apt-get install -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" make software-properties-common \
build-essential libtool autoconf libssl-dev libboost-dev libboost-chrono-dev libboost-filesystem-dev libboost-program-options-dev \
libboost-system-dev libboost-test-dev libboost-thread-dev sudo automake git wget pwgen curl libdb4.8-dev bsdmainutils libdb4.8++-dev \
libminiupnpc-dev libgmp3-dev ufw fail2ban >/dev/null 2>&1
clear
if [ "$?" -gt "0" ];
  then
    echo -e "${RED}Not all required packages were installed properly. Try to install them manually by running the following commands:${NC}\n"
    echo "apt-get update"
    echo "apt -y install software-properties-common"
    echo "apt-add-repository -y ppa:bitcoin/bitcoin"
    echo "apt-get update"
    echo "apt install -y make build-essential libtool software-properties-common autoconf libssl-dev libboost-dev libboost-chrono-dev libboost-filesystem-dev \
libboost-program-options-dev libboost-system-dev libboost-test-dev libboost-thread-dev sudo automake git pwgen curl libdb4.8-dev \
bsdmainutils libdb4.8++-dev libminiupnpc-dev libgmp3-dev"
 exit 1
fi

clear
echo -e "Checking if swap space is needed."
PHYMEM=$(free -g|awk '/^Mem:/{print $2}')
SWAP=$(free -g|awk '/^Swap:/{print $2}')
if [ "$PHYMEM" -lt "2" ] && [ -n "$SWAP" ]
  then
    echo -e "${GREEN}Server is running with less than 2G of RAM without SWAP, creating 2G swap file.${NC}"
    SWAPFILE=$(mktemp)
    dd if=/dev/zero of=$SWAPFILE bs=1024 count=2M
    chmod 600 $SWAPFILE
    mkswap $SWAPFILE
    swapon -a $SWAPFILE
else
  echo -e "${GREEN}Server running with at least 2G of RAM, no swap needed.${NC}"
fi
clear
}

function compile_deviant() {
  echo -e "Clone git repo and compile it. This may take some time. Press a key to continue."
  cd $TMP_FOLDER
  wget -q $DEVIANT_REPO
  chmod +x Deviantd
  cp -a Deviantd /usr/local/bin
  cd ~
  rm -rf $TMP_FOLDER
  clear
}

function enable_firewall() {
  echo -e "Installing fail2ban and setting up firewall to allow ingress on port ${GREEN}$DEVIANTPORT${NC}"
  ufw allow $DEVIANTPORT/tcp comment "Deviant MN port" >/dev/null
  ufw allow $[DEVIANTPORT+1]/tcp comment "Deviant RPC port" >/dev/null
  ufw allow ssh comment "SSH" >/dev/null 2>&1
  ufw limit ssh/tcp >/dev/null 2>&1
  ufw default allow outgoing >/dev/null 2>&1
  echo "y" | ufw enable >/dev/null 2>&1
  systemctl enable fail2ban >/dev/null 2>&1
  systemctl start fail2ban >/dev/null 2>&1
}

function systemd_deviant() {
  cat << EOF > /etc/systemd/system/$DEVIANTUSER.service
[Unit]
Description=Deviant service
After=network.target

[Service]
ExecStart=$DEVIANT_DAEMON -conf=$DEVIANTFOLDER/$CONFIG_FILE -datadir=$DEVIANTFOLDER
ExecStop=$DEVIANT_DAEMON -conf=$DEVIANTFOLDER/$CONFIG_FILE -datadir=$DEVIANTFOLDER stop
Restart=on-abord
User=$DEVIANTUSER
Group=$DEVIANTUSER

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  sleep 3
  systemctl start $DEVIANTUSER.service
  systemctl enable $DEVIANTUSER.service

  if [[ -z "$(ps axo user:15,cmd:100 | egrep ^$DEVIANTUSER | grep $DEVIANT_DAEMON)" ]]; then
    echo -e "${RED}Deviantd is not running${NC}, please investigate. You should start by running the following commands as root:"
    echo -e "${GREEN}systemctl start $DEVIANTUSER.service"
    echo -e "systemctl status $DEVIANTUSER.service"
    echo -e "less /var/log/syslog${NC}"
    exit 1
  fi
}

function ask_port() {
read -p "DEVIANT Port: " -i $DEFAULTDEVIANTPORT -e DEVIANTPORT
: ${DEVIANTPORT:=$DEFAULTDEVIANTPORT}
}

function ask_user() {
  read -p "Deviant user: " -i $DEFAULTDEVIANTUSER -e DEVIANTUSER
  : ${DEVIANTUSER:=$DEFAULTDEVIANTUSER}

  if [ -z "$(getent passwd $DEVIANTUSER)" ]; then
    USERPASS=$(pwgen -s 12 1)
    useradd -m $DEVIANTUSER
    echo "$DEVIANTUSER:$USERPASS" | chpasswd

    DEVIANTHOME=$(sudo -H -u $DEVIANTUSER bash -c 'echo $HOME')
    DEFAULTDEVIANTFOLDER="$DEVIANTHOME/.Deviant"
    read -p "Configuration folder: " -i $DEFAULTDEVIANTFOLDER -e DEVIANTFOLDER
    : ${DEVIANTFOLDER:=$DEFAULTDEVIANTFOLDER}
    mkdir -p $DEVIANTFOLDER
    chown -R $DEVIANTUSER: $DEVIANTFOLDER >/dev/null
  else
    clear
    echo -e "${RED}User exits. Please enter another username: ${NC}"
    ask_user
  fi
}

function check_port() {
  declare -a PORTS
  PORTS=($(netstat -tnlp | awk '/LISTEN/ {print $4}' | awk -F":" '{print $NF}' | sort | uniq | tr '\r\n'  ' '))
  ask_port

  while [[ ${PORTS[@]} =~ $DEVIANTPORT ]] || [[ ${PORTS[@]} =~ $[DEVIANTPORT+1] ]]; do
    clear
    echo -e "${RED}Port in use, please choose another port:${NF}"
    ask_port
  done
}

function create_config() {
  RPCUSER=$(pwgen -s 8 1)
  RPCPASSWORD=$(pwgen -s 15 1)
  cat << EOF > $DEVIANTFOLDER/$CONFIG_FILE
rpcuser=$RPCUSER
rpcpassword=$RPCPASSWORD
rpcallowip=127.0.0.1
rpcport=$[DEVIANTPORT+1]
listen=1
server=1
daemon=1
port=$DEVIANTPORT
EOF
}

function create_key() {
  echo -e "Enter your ${RED}Masternode Private Key${NC}. Leave it blank to generate a new ${RED}Masternode Private Key${NC} for you:"
  read -e DEVIANTKEY
  if [[ -z "$DEVIANTKEY" ]]; then
  su $DEVIANTUSER -c "$DEVIANT_DAEMON -conf=$DEVIANTFOLDER/$CONFIG_FILE -datadir=$DEVIANTFOLDER"
  sleep 5
  if [ -z "$(ps axo user:15,cmd:100 | egrep ^$DEVIANTUSER | grep $DEVIANT_DAEMON)" ]; then
   echo -e "${RED}Deviantd server couldn't start. Check /var/log/syslog for errors.{$NC}"
   exit 1
  fi
  DEVIANTKEY=$(su $DEVIANTUSER -c "$DEVIANT_DAEMON -conf=$DEVIANTFOLDER/$CONFIG_FILE -datadir=$DEVIANTFOLDER masternode genkey")
  su $DEVIANTUSER -c "$DEVIANT_DAEMON -conf=$DEVIANTFOLDER/$CONFIG_FILE -datadir=$DEVIANTFOLDER stop"
fi
}

function update_config() {
  sed -i 's/daemon=1/daemon=0/' $DEVIANTFOLDER/$CONFIG_FILE
  cat << EOF >> $DEVIANTFOLDER/$CONFIG_FILE
maxconnections=256
masternode=1
masternodeaddr=$NODEIP:$DEVIANTPORT
masternodeprivkey=$DEVIANTKEY
addnode=165.227.83.233:7118
addnode=104.131.124.189:7118
addnode=139.59.72.56:7118
addnode=128.199.201.170:7118
addnode=165.227.156.13:7118
addnode=165.227.231.58:7118
addnode=159.89.152.81:7118
addnode=5.189.166.116:7118
addnode=173.249.27.157:7118
addnode=173.249.27.158:7118
addnode=173.249.27.159:7118
EOF
  chown -R $DEVIANTUSER: $DEVIANTFOLDER >/dev/null
}

function important_information() {
 echo
 echo -e "================================================================================================================================"
 echo -e "Deviant Masternode is up and running as user ${GREEN}$DEVIANTUSER${NC} and it is listening on port ${GREEN}$DEVIANTPORT${NC}."
 echo -e "${GREEN}$DEVIANTUSER${NC} password is ${RED}$USERPASS${NC}"
 echo -e "Configuration file is: ${RED}$DEVIANTFOLDER/$CONFIG_FILE${NC}"
 echo -e "Start: ${RED}systemctl start $DEVIANTUSER.service${NC}"
 echo -e "Stop: ${RED}systemctl stop $DEVIANTUSER.service${NC}"
 echo -e "VPS_IP:PORT ${RED}$NODEIP:$DEVIANTPORT${NC}"
 echo -e "MASTERNODE PRIVATEKEY is: ${RED}$DEVIANTKEY${NC}"
 echo -e "Please check Deviant is running with the following command: ${GREEN}systemctl status $DEVIANTUSER.service${NC}"
 echo -e "================================================================================================================================"
}

function setup_node() {
  ask_user
  check_port
  create_config
  create_key
  update_config
  enable_firewall
  systemd_deviant
  important_information
}


##### Main #####
clear

checks
if [[ ("$NEW_DEVIANT" == "y" || "$NEW_DEVIANT" == "Y") ]]; then
  setup_node
  exit 0
elif [[ "$NEW_DEVIANT" == "new" ]]; then
  prepare_system
  compile_deviant
  setup_node
else
  echo -e "${GREEN}Deviantd already running.${NC}"
  exit 0
fi

