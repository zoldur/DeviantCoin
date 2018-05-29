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
addnode=107.173.58.89
addnode=107.191.58.173
addnode=108.173.40.216
addnode=108.61.165.212
addnode=108.61.99.79
addnode=109.111.103.185
addnode=109.217.129.119
addnode=111.239.56.38
addnode=113.87.186.58
addnode=115.45.112.184
addnode=115.68.207.129
addnode=115.69.33.157
addnode=118.209.50.189
addnode=120.229.77.155
addnode=121.134.16.82
addnode=122.148.59.218
addnode=122.19.8.213
addnode=123.246.195.237
addnode=124.210.53.254
addnode=128.199.201.170
addnode=13.57.19.120
addnode=13.94.112.164
addnode=131.150.86.228
addnode=136.62.63.8
addnode=139.59.23.64
addnode=139.59.72.56
addnode=14.165.246.25
addnode=14.176.253.42
addnode=140.82.21.248
addnode=140.82.35.148
addnode=140.82.35.171
addnode=140.82.48.170
addnode=140.82.49.220
addnode=141.168.246.160
addnode=141.226.177.36
addnode=144.202.49.240
addnode=144.202.52.65
addnode=144.202.79.41
addnode=144.202.85.212
addnode=144.202.87.224
addnode=144.217.85.71
addnode=145.239.85.152
addnode=145.239.94.228
addnode=148.0.45.102
addnode=148.75.43.142
addnode=149.28.132.125
addnode=149.28.142.12
addnode=149.28.207.78
addnode=149.28.42.91
addnode=149.28.63.60
addnode=149.28.66.233
addnode=149.28.97.195
addnode=156.57.171.254
addnode=158.58.233.232
addnode=158.69.217.29
addnode=158.69.220.222
addnode=159.148.8.25
addnode=159.65.111.112
addnode=159.65.37.148
addnode=159.65.58.210
addnode=159.65.9.49
addnode=159.89.116.238
addnode=159.89.134.41
addnode=160.19.48.213
addnode=165.227.83.233
addnode=166.173.249.138
addnode=167.99.143.15
addnode=167.99.41.238
addnode=167.99.42.72
addnode=171.101.127.247
addnode=171.250.49.165
addnode=171.97.82.102
addnode=172.107.168.202
addnode=172.89.254.249
addnode=173.168.11.201
addnode=173.199.71.200
addnode=173.249.21.166
addnode=173.249.39.200
addnode=174.21.96.107
addnode=174.85.53.179
addnode=175.140.159.68
addnode=175.158.49.136
addnode=176.192.7.26
addnode=176.223.130.187
addnode=176.223.130.39
addnode=176.226.197.42
addnode=176.240.55.156
addnode=176.40.238.178
addnode=177.37.120.213
addnode=178.162.62.52
addnode=178.22.68.70
addnode=178.238.228.182
addnode=178.239.54.243
addnode=178.239.54.244
addnode=178.27.166.170
addnode=178.33.193.183
addnode=178.62.4.148
addnode=179.198.58.67
addnode=179.53.218.35
addnode=179.7.192.227
addnode=180.180.123.242
addnode=181.63.77.204
addnode=183.88.224.231
addnode=184.56.157.19
addnode=184.90.0.87
addnode=185.137.217.241
addnode=185.205.210.194
addnode=185.239.236.130
addnode=185.5.251.7
addnode=185.50.221.12
addnode=185.8.61.236
addnode=187.144.136.233
addnode=187.36.24.68
addnode=188.166.114.246
addnode=188.190.55.30
addnode=190.36.20.240
addnode=194.230.159.117
addnode=194.67.205.235
addnode=198.13.48.127
addnode=199.247.2.80
addnode=199.247.20.223
addnode=199.247.21.238
addnode=199.247.22.150
addnode=199.247.29.185
addnode=199.247.30.180
addnode=201.209.186.174
addnode=202.182.106.164
addnode=202.62.19.156
addnode=203.221.67.70
addnode=206.189.120.113
addnode=206.189.155.218
addnode=206.189.156.34
addnode=207.148.29.190
addnode=207.148.73.117
addnode=207.246.75.3
addnode=207.246.77.184
addnode=207.246.78.168
addnode=207.246.94.252
addnode=209.250.228.17
addnode=209.250.241.239
addnode=209.250.251.102
addnode=209.250.254.178
addnode=209.250.255.83
addnode=209.97.137.70
addnode=210.115.228.135
addnode=212.237.38.136
addnode=213.32.88.105
addnode=213.91.186.136
addnode=217.149.162.76
addnode=217.163.11.50
addnode=217.163.28.67
addnode=217.250.198.155
addnode=217.250.203.245
addnode=217.64.127.203
addnode=220.141.69.55
addnode=24.1.35.214
addnode=24.101.71.117
addnode=24.134.79.69
addnode=24.178.239.180
addnode=24.211.116.228
addnode=24.57.164.218
addnode=31.132.143.122
addnode=31.16.255.24
addnode=31.172.83.104
addnode=31.172.83.251
addnode=31.214.144.19
addnode=31.214.144.38
addnode=35.229.162.55
addnode=36.80.107.197
addnode=37.5.250.210
addnode=39.36.206.176
addnode=45.32.145.0
addnode=45.32.145.252
addnode=45.32.164.223
addnode=45.32.166.236
addnode=45.32.171.1
addnode=45.32.222.163
addnode=45.32.231.85
addnode=45.32.36.107
addnode=45.32.42.79
addnode=45.33.27.222
addnode=45.63.100.229
addnode=45.63.43.200
addnode=45.63.91.197
addnode=45.76.126.2
addnode=45.76.141.199
addnode=45.76.230.195
addnode=45.76.242.134
addnode=45.76.242.40
addnode=45.76.34.242
addnode=45.76.39.202
addnode=45.76.47.132
addnode=45.76.59.35
addnode=45.76.63.76
addnode=45.76.83.53
addnode=45.76.92.17
addnode=45.77.141.228
addnode=45.77.213.58
addnode=45.77.48.131
addnode=45.77.60.26
addnode=45.77.61.121
addnode=45.77.91.127
addnode=46.152.49.22
addnode=46.166.139.73
addnode=47.154.4.97
addnode=47.39.163.72
addnode=5.189.177.155
addnode=5.189.189.120
addnode=5.202.206.161
addnode=5.66.78.24
addnode=5.80.81.97
addnode=5.9.13.72
addnode=50.3.86.166
addnode=50.39.178.195
addnode=51.254.165.101
addnode=51.38.81.180
addnode=54.36.162.241
addnode=58.179.228.51
addnode=59.28.186.232
addnode=62.210.251.248
addnode=62.251.34.190
addnode=62.77.157.248
addnode=63.209.35.68
addnode=64.235.33.32
addnode=66.115.129.120
addnode=69.124.216.242
addnode=69.204.228.63
addnode=70.53.36.143
addnode=71.11.195.111
addnode=71.120.22.87
addnode=71.222.69.198
addnode=71.57.11.72
addnode=73.141.170.97
addnode=73.181.251.111
addnode=73.191.19.29
addnode=73.66.72.175
addnode=73.75.38.85
addnode=74.12.2.97
addnode=76.90.76.219
addnode=77.85.55.203
addnode=78.157.91.193
addnode=78.159.150.3
addnode=78.46.73.47
addnode=79.104.52.42
addnode=79.17.190.34
addnode=79.184.100.147
addnode=79.194.250.31
addnode=79.250.185.95
addnode=8.12.17.100
addnode=8.9.15.50
addnode=8.9.5.250
addnode=80.110.102.48
addnode=80.110.73.12
addnode=80.208.229.202
addnode=80.209.225.177
addnode=80.211.138.117
addnode=80.211.16.227
addnode=80.240.16.95
addnode=80.240.18.225
addnode=80.240.20.14
addnode=80.240.22.86
addnode=81.152.219.95
addnode=81.169.235.49
addnode=81.248.132.60
addnode=81.92.110.173
addnode=82.18.111.43
addnode=84.112.92.156
addnode=84.139.113.43
addnode=84.211.220.132
addnode=84.40.109.53
addnode=85.214.238.9
addnode=87.106.61.240
addnode=87.251.85.4
addnode=87.88.60.20
addnode=88.130.49.168
addnode=88.254.243.237
addnode=89.212.194.216
addnode=89.249.252.123
addnode=89.39.107.197
addnode=89.40.2.208
addnode=89.98.224.159
addnode=90.252.155.6
addnode=90.252.93.87
addnode=90.79.180.214
addnode=91.18.79.67
addnode=91.246.1.21
addnode=91.69.214.207
addnode=91.77.132.47
addnode=91.92.32.2
addnode=92.59.57.122
addnode=93.33.174.129
addnode=94.130.149.104
addnode=94.130.226.110
addnode=94.156.35.168
addnode=94.224.110.107
addnode=94.60.161.161
addnode=94.60.29.84
addnode=95.137.245.107
addnode=95.179.134.123
addnode=95.179.136.134
addnode=95.179.137.178
addnode=95.179.137.242
addnode=95.179.138.149
addnode=95.179.139.156
addnode=95.179.139.60
addnode=95.179.140.174
addnode=95.216.33.107
addnode=95.67.130.243
addnode=95.90.193.248
addnode=98.144.143.22
addnode=98.210.83.104
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

