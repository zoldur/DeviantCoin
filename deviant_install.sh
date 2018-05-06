#!/bin/bash

TMP_FOLDER=$(mktemp -d)
CONFIG_FILE='Deviant.conf'
CONFIGFOLDER='/root/.Deviant'
COIN_DAEMON='Deviantd'
COIN_CLI='Deviantd'
COIN_PATH='/usr/local/bin/'
COIN_TGZ='https://github.com/Deviantcoin/Wallet/raw/master/Deviantcoin%20(Linux)/Deviantd'
COIN_ZIP=$(echo $COIN_TGZ | awk -F'/' '{print $NF}')
COIN_NAME='Deviant'
COIN_PORT=7118
#RPC_PORT=7119

NODEIP=$(curl -s4 icanhazip.com)


RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'


function download_node() {
  echo -e "Prepare to download ${GREEN}$COIN_NAME${NC}."
  cd $TMP_FOLDER >/dev/null 2>&1
  wget -q $COIN_TGZ
  compile_error
  chmod +x $COIN_DAEMON
  cp $COIN_DAEMON $COIN_PATH
  cd ~ >/dev/null 2>&1
  rm -rf $TMP_FOLDER >/dev/null 2>&1
  clear
}


function configure_systemd() {
  cat << EOF > /etc/systemd/system/$COIN_NAME.service
[Unit]
Description=$COIN_NAME service
After=network.target

[Service]
User=root
Group=root

Type=forking
#PIDFile=$CONFIGFOLDER/$COIN_NAME.pid

ExecStart=$COIN_PATH$COIN_DAEMON -daemon -conf=$CONFIGFOLDER/$CONFIG_FILE -datadir=$CONFIGFOLDER
ExecStop=-$COIN_PATH$COIN_CLI -conf=$CONFIGFOLDER/$CONFIG_FILE -datadir=$CONFIGFOLDER stop

Restart=always
PrivateTmp=true
TimeoutStopSec=60s
TimeoutStartSec=10s
StartLimitInterval=120s
StartLimitBurst=5

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  sleep 3
  systemctl start $COIN_NAME.service
  systemctl enable $COIN_NAME.service >/dev/null 2>&1

  if [[ -z "$(ps axo cmd:100 | egrep $COIN_DAEMON)" ]]; then
    echo -e "${RED}$COIN_NAME is not running${NC}, please investigate. You should start by running the following commands as root:"
    echo -e "${GREEN}systemctl start $COIN_NAME.service"
    echo -e "systemctl status $COIN_NAME.service"
    echo -e "less /var/log/syslog${NC}"
    exit 1
  fi
}


function create_config() {
  mkdir $CONFIGFOLDER >/dev/null 2>&1
  RPCUSER=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w10 | head -n1)
  RPCPASSWORD=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w22 | head -n1)
  cat << EOF > $CONFIGFOLDER/$CONFIG_FILE
rpcuser=$RPCUSER
rpcpassword=$RPCPASSWORD
#rpcport=$RPC_PORT
rpcallowip=127.0.0.1
listen=1
server=1
daemon=1
port=$COIN_PORT
EOF
}

function create_key() {
  echo -e "Enter your ${RED}$COIN_NAME Masternode Private Key${NC}. Leave it blank to generate a new ${RED}Masternode Private Key${NC} for you:"
  read -t 5 -e COINKEY
  if [[ -z "$COINKEY" ]]; then
  $COIN_PATH$COIN_DAEMON -daemon
  sleep 30
  if [ -z "$(ps axo cmd:100 | grep $COIN_DAEMON)" ]; then
   echo -e "${RED}$COIN_NAME server couldn not start. Check /var/log/syslog for errors.{$NC}"
   exit 1
  fi
  COINKEY=$($COIN_PATH$COIN_CLI masternode genkey)
  if [ "$?" -gt "0" ];
    then
    echo -e "${RED}Wallet not fully loaded. Let us wait and try again to generate the Private Key${NC}"
    sleep 30
    COINKEY=$($COIN_PATH$COIN_CLI masternode genkey)
  fi
  $COIN_PATH$COIN_CLI stop
fi
clear
}

function update_config() {
  sed -i 's/daemon=1/daemon=0/' $CONFIGFOLDER/$CONFIG_FILE
  cat << EOF >> $CONFIGFOLDER/$CONFIG_FILE
logintimestamps=1
maxconnections=256
#bind=$NODEIP
masternode=1
externalip=$NODEIP:$COIN_PORT
masternodeprivkey=$COINKEY
addnode=108.61.89.44:7118
addnode=159.65.111.112:7118
addnode=45.76.93.109:7118
addnode=199.247.29.51:7118
addnode=85.214.227.34:7118
addnode=45.76.203.120:7118
addnode=159.65.37.148:7118
addnode=5.189.166.116:7118
addnode=185.231.69.154:7118
addnode=45.32.145.252:7118
addnode=45.32.185.108:7118
addnode=78.46.73.47:7118
addnode=176.9.56.6:7118
addnode=45.77.195.108:7118
addnode=172.245.205.17:7118
addnode=176.9.136.123:7118
addnode=195.201.96.177:7118
addnode=195.201.96.179:7118
addnode=94.130.226.110:7118
addnode=207.246.108.15:7118
addnode=94.130.149.104:7118
addnode=145.239.7.213:7118
addnode=207.148.68.100:7118
addnode=144.202.0.245:7118
addnode=52.170.249.247:7118
addnode=35.188.212.69:7118
addnode=45.32.75.191:7118
addnode=45.77.212.171:7118
addnode=104.238.172.23:7118
addnode=167.99.42.81:7118
addnode=199.48.160.49:7118
addnode=45.77.228.247:7118
addnode=207.246.100.25:7118
addnode=54.36.162.241:7118
addnode=159.89.127.211:7118
addnode=199.247.30.210:7118
addnode=45.77.234.110:7118
addnode=140.82.8.174:7118
addnode=45.63.100.229:7118
addnode=209.250.245.12:7118
addnode=45.77.91.127:7118
addnode=199.247.30.165:7118
addnode=207.201.218.19:7118
addnode=144.202.97.48:7118
addnode=144.202.107.22:7118
addnode=13.90.147.154:7118
addnode=13.92.135.170:7118
addnode=45.63.114.59:7118
addnode=45.33.27.222:7118
addnode=207.148.14.228:7118
addnode=108.61.195.139:7118
addnode=199.247.29.141:7118
addnode=45.32.151.35:7118
addnode=212.237.25.117:7118
addnode=159.65.58.210:7118
addnode=45.77.239.239:7118
addnode=45.77.237.157:7118
addnode=207.148.73.121:7118
addnode=140.82.35.148:7118
addnode=45.76.181.103:7118
addnode=107.191.62.248:7118
addnode=199.247.30.172:7118
addnode=140.82.40.35:7118
addnode=188.166.186.23:7118
addnode=45.76.39.202:7118
addnode=46.166.139.73:7118
addnode=139.99.173.91:7118
addnode=158.69.217.29:7118
addnode=209.250.238.14:7118
addnode=45.76.124.59:7118
addnode=185.185.27.101:7118
addnode=178.62.75.128:7118
addnode=45.76.242.134:7118
addnode=144.202.87.224:7118
addnode=46.101.53.19:7118
addnode=45.77.208.65:7118
addnode=144.202.94.19:7118
addnode=45.77.213.58:7118
addnode=45.77.230.52:7118
addnode=209.250.231.19:7118
addnode=45.76.137.99:7118
addnode=45.32.181.223:7118
addnode=104.238.187.20:7118
addnode=45.63.100.246:7118
addnode=108.61.173.84:7118
addnode=45.76.143.120:7118
addnode=217.163.11.50:7118
addnode=45.76.130.30:7118
addnode=212.56.137.221:7118
addnode=212.56.137.222:7118
addnode=23.95.225.107:7118
addnode=45.32.233.78:7118
addnode=45.32.181.243:7118
addnode=45.63.95.133:7118
addnode=45.77.50.34:7118
addnode=23.95.115.154:7118
addnode=80.211.206.16:7118
addnode=34.212.32.70:7118
addnode=52.32.172.97:7118
addnode=209.250.251.10:7118
addnode=45.32.72.96:7118
addnode=45.77.232.181:7118
addnode=80.79.194.67:7118
addnode=104.238.141.19:7118
addnode=45.76.37.23:7118
addnode=34.217.10.51:7118
addnode=45.63.49.83:7118
addnode=5.189.166.116:7118
addnode=5.189.166.116:7118
addnode=207.148.67.142:7118
addnode=45.77.193.226:7118
addnode=45.77.21.173:7118
addnode=35.192.232.128:7118
addnode=45.77.228.181:7118
addnode=45.77.191.6:7118
addnode=142.44.246.124:7118
addnode=45.76.229.111:7118
addnode=144.202.52.65:7118
addnode=144.202.80.81:7118
addnode=145.239.85.152:7118
addnode=45.32.69.220:7118
addnode=45.76.99.63:7118
addnode=54.202.85.121:7118
addnode=199.247.26.200:7118
addnode=159.65.76.35:7118
addnode=5.101.122.250:7118
addnode=198.13.44.178:7118
addnode=207.246.122.12:7118
addnode=138.197.193.17:7118
addnode=139.59.23.64:7118
addnode=108.61.89.44:7118
addnode=159.65.111.112:7118
addnode=45.76.93.109:7118
addnode=199.247.29.51:7118
addnode=85.214.227.34:7118
addnode=45.76.203.120:7118
addnode=159.65.37.148:7118
addnode=5.189.166.116:7118
addnode=185.231.69.154:7118
addnode=45.32.145.252:7118
addnode=45.32.185.108:7118
addnode=78.46.73.47:7118
addnode=176.9.56.6:7118
addnode=45.77.195.108:7118
addnode=172.245.205.17:7118
addnode=176.9.136.123:7118
addnode=195.201.96.177:7118
addnode=195.201.96.179:7118
addnode=94.130.226.110:7118
addnode=207.246.108.15:7118
addnode=94.130.149.104:7118
addnode=145.239.7.213:7118
addnode=207.148.68.100:7118
addnode=144.202.0.245:7118
addnode=52.170.249.247:7118
addnode=35.188.212.69:7118
addnode=45.32.75.191:7118
addnode=45.77.212.171:7118
addnode=104.238.172.23:7118
addnode=167.99.42.81:7118
addnode=199.48.160.49:7118
addnode=45.77.228.247:7118
addnode=207.246.100.25:7118
addnode=54.36.162.241:7118
addnode=159.89.127.211:7118
addnode=199.247.30.210:7118
addnode=45.77.234.110:7118
addnode=140.82.8.174:7118
addnode=45.63.100.229:7118
addnode=209.250.245.12:7118
addnode=45.77.91.127:7118
addnode=199.247.30.165:7118
addnode=207.201.218.19:7118
addnode=144.202.97.48:7118
addnode=144.202.107.22:7118
addnode=13.90.147.154:7118
addnode=13.92.135.170:7118
addnode=45.63.114.59:7118
addnode=45.33.27.222:7118
addnode=207.148.14.228:7118
addnode=108.61.195.139:7118
addnode=199.247.29.141:7118
addnode=45.32.151.35:7118
addnode=212.237.25.117:7118
addnode=159.65.58.210:7118
addnode=45.77.239.239:7118
addnode=45.77.237.157:7118
addnode=207.148.73.121:7118
addnode=140.82.35.148:7118
addnode=45.76.181.103:7118
addnode=107.191.62.248:7118
addnode=199.247.30.172:7118
addnode=140.82.40.35:7118
addnode=188.166.186.23:7118
addnode=45.76.39.202:7118
addnode=46.166.139.73:7118
addnode=139.99.173.91:7118
addnode=94.228.211.145:7118
addnode=206.189.23.99:7118
addnode=45.32.164.223:7118
addnode=45.63.48.77:7118
addnode=209.250.252.19:7118
addnode=45.32.146.132:7118
addnode=85.214.238.9:7118
addnode=185.185.24.120:7118
addnode=144.208.127.15:7118
addnode=45.32.61.229:7118
addnode=23.94.160.11:7118
addnode=45.76.63.66:7118
addnode=45.76.56.117:7118
addnode=45.63.36.211:7118
addnode=209.250.245.22:7118
addnode=45.32.202.125:7118
addnode=139.59.60.208:7118
addnode=63.211.111.95:7118
addnode=159.65.166.29:7118
addnode=140.82.27.72:7118
addnode=212.237.38.136:7118
addnode=167.114.128.24:7118
addnode=185.249.197.15:7118
addnode=104.45.128.171:7118
addnode=8.9.5.250:7118
addnode=81.169.178.197:7118
addnode=62.77.152.111:7118
addnode=45.32.132.243:7118
addnode=159.65.162.188:7118
addnode=31.172.83.85:7118
addnode=185.82.20.51:7118
addnode=31.172.83.104:7118
addnode=88.99.15.3:7118
addnode=144.202.28.103:7118
addnode=31.172.83.86:7118
addnode=108.61.89.104:7118
addnode=108.160.131.15:7118
addnode=209.250.231.12:7118
addnode=209.250.254.17:7118
addnode=45.77.200.172:7118
addnode=208.167.245.21:7118
addnode=178.62.202.214:7118
addnode=108.61.165.212:7118
addnode=45.77.30.46:7118
addnode=104.236.57.5:7118
addnode=138.197.149.19:7118
addnode=192.241.205.23:7118
addnode=104.235.211.52:7118
addnode=45.32.200.116:7118
addnode=45.32.133.128:7118
addnode=207.246.75.3:7118
addnode=45.77.137.212:7118
addnode=209.250.251.39:7118
addnode=159.89.134.41:7118
addnode=46.101.187.89:7118
addnode=45.76.155.223:7118
addnode=159.203.16.111:7118
addnode=207.148.73.117:7118
addnode=35.196.255.147:7118
addnode=95.122.112.12:7118
addnode=104.131.35.248:7118
addnode=13.55.197.235:7118
addnode=45.76.147.176:7118
addnode=108.61.247.207:7118
addnode=18.219.171.159:7118
addnode=209.250.255.83:7118
addnode=145.131.28.192:7118
addnode=92.242.243.157:7118
addnode=89.40.15.244:7118
addnode=178.238.228.18:7118
addnode=159.89.136.164:7118
addnode=144.202.76.36:7118
addnode=13.57.19.120:7118
addnode=113.161.82.243:7118
addnode=68.232.175.231:7118
addnode=45.76.94.150:7118
addnode=144.202.103.14:7118
addnode=8.9.31.94:7118
addnode=8.9.15.50:7118
addnode=51.38.49.160:7118
addnode=206.189.156.34:7118
addnode=198.13.40.36:7118
addnode=144.202.59.91:7118
addnode=209.250.232.61:7118
addnode=45.77.55.212:7118
addnode=199.247.21.238:7118
addnode=45.32.158.102:7118
addnode=45.77.65.69:7118
addnode=45.77.60.26:7118
addnode=199.247.13.12:7118
addnode=199.247.21.11:7118
addnode=45.32.146.165:7118
addnode=199.247.22.83:7118
addnode=45.76.92.17:7118
addnode=199.247.23.117:7118
addnode=199.247.18.45:7118
addnode=217.163.30.68:7118
addnode=199.247.22.150:7118
addnode=45.76.45.188:7118
addnode=45.76.87.205:7118
addnode=83.217.206.155:7118
addnode=207.148.126.241:7118
addnode=198.245.53.223:7118
addnode=217.163.28.248:7118
addnode=149.28.168.93:7118
addnode=140.82.9.216:7118
addnode=45.32.235.3:7118
addnode=144.202.106.91:7118
addnode=207.246.102.29:7118
addnode=45.77.234.199:7118
addnode=31.172.83.143:7118
addnode=77.51.183.48:7118
addnode=31.172.83.83:7118
addnode=185.82.21.64:7118
addnode=46.101.158.24:7118
addnode=144.202.22.255:7118
addnode=104.34.66.33:7118
addnode=45.77.231.32:7118
addnode=144.202.3.82:7118
addnode=45.77.52.251:7118
addnode=45.77.117.105:7118
addnode=45.76.214.160:7118
EOF
}


function enable_firewall() {
  echo -e "Installing and setting up firewall to allow ingress on port ${GREEN}$COIN_PORT${NC}"
  ufw allow $COIN_PORT/tcp comment "$COIN_NAME MN port" >/dev/null
  ufw allow ssh comment "SSH" >/dev/null 2>&1
  ufw limit ssh/tcp >/dev/null 2>&1
  ufw default allow outgoing >/dev/null 2>&1
  echo "y" | ufw enable >/dev/null 2>&1
}


function get_ip() {
  declare -a NODE_IPS
  for ips in $(netstat -i | awk '!/Kernel|Iface|lo/ {print $1," "}')
  do
    NODE_IPS+=($(curl --interface $ips --connect-timeout 2 -s4 icanhazip.com))
  done

  if [ ${#NODE_IPS[@]} -gt 1 ]
    then
      echo -e "${GREEN}More than one IP. Please type 0 to use the first IP, 1 for the second and so on...${NC}"
      INDEX=0
      for ip in "${NODE_IPS[@]}"
      do
        echo ${INDEX} $ip
        let INDEX=${INDEX}+1
      done
      read -e choose_ip
      NODEIP=${NODE_IPS[$choose_ip]}
  else
    NODEIP=${NODE_IPS[0]}
  fi
}


function compile_error() {
if [ "$?" -gt "0" ];
 then
  echo -e "${RED}Failed to compile $COIN_NAME. Please investigate.${NC}"
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

if [ -n "$(pidof $COIN_DAEMON)" ] || [ -e "$COIN_DAEMOM" ] ; then
  echo -e "${RED}$COIN_NAME is already installed.${NC}"
  exit 1
fi
}

function prepare_system() {
echo -e "Prepare the system to install ${GREEN}$COIN_NAME${NC} master node."
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
libboost-system-dev libboost-test-dev libboost-thread-dev sudo automake git wget curl libdb4.8-dev bsdmainutils libdb4.8++-dev \
libminiupnpc-dev libgmp3-dev ufw pkg-config libevent-dev  libdb5.3++ unzip libzmq5 >/dev/null 2>&1
if [ "$?" -gt "0" ];
  then
    echo -e "${RED}Not all required packages were installed properly. Try to install them manually by running the following commands:${NC}\n"
    echo "apt-get update"
    echo "apt -y install software-properties-common"
    echo "apt-add-repository -y ppa:bitcoin/bitcoin"
    echo "apt-get update"
    echo "apt install -y make build-essential libtool software-properties-common autoconf libssl-dev libboost-dev libboost-chrono-dev libboost-filesystem-dev \
libboost-program-options-dev libboost-system-dev libboost-test-dev libboost-thread-dev sudo automake git curl libdb4.8-dev \
bsdmainutils libdb4.8++-dev libminiupnpc-dev libgmp3-dev ufw pkg-config libevent-dev libdb5.3++ unzip libzmq5"
 exit 1
fi
clear
}

function important_information() {
 echo -e "================================================================================================================================"
 echo -e "$COIN_NAME Masternode is up and running listening on port ${RED}$COIN_PORT${NC}."
 echo -e "Configuration file is: ${RED}$CONFIGFOLDER/$CONFIG_FILE${NC}"
 echo -e "Start: ${RED}systemctl start $COIN_NAME.service${NC}"
 echo -e "Stop: ${RED}systemctl stop $COIN_NAME.service${NC}"
 echo -e "VPS_IP:PORT ${RED}$NODEIP:$COIN_PORT${NC}"
 echo -e "MASTERNODE PRIVATEKEY is: ${RED}$COINKEY${NC}"
 echo -e "Please check ${RED}$COIN_NAME${NC} daemon is running with the following command: ${RED}systemctl status $COIN_NAME.service${NC}"
 echo -e "Use ${RED}$COIN_CLI masternode status${NC} to check your MN."
 if [[ -n $SENTINEL_REPO  ]]; then
  echo -e "${RED}Sentinel${NC} is installed in ${RED}$CONFIGFOLDER/sentinel${NC}"
  echo -e "Sentinel logs is: ${RED}$CONFIGFOLDER/sentinel.log${NC}"
 fi
 echo -e "================================================================================================================================"
}

function setup_node() {
  get_ip
  create_config
  create_key
  update_config
  enable_firewall
  important_information
  configure_systemd
}


##### Main #####
clear

checks
prepare_system
download_node
setup_node

