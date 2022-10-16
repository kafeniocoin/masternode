#!/bin/bash

PORT=11427
RPCPORT=11428
CONF_DIR=~/.kafeniocoin
COINZIP='https://github.com/kafeniocoin/KFN/releases/download/v1.0/kfn-linux.zip'

cd ~
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}$0 must be run as root.${NC}"
   exit 1
fi

function configure_systemd {
  cat << EOF > /etc/systemd/system/kfn.service
[Unit]
Description=Kafeniocoin Service
After=network.target
[Service]
User=root
Group=root
Type=forking
ExecStart=/usr/local/bin/kafeniocoind
ExecStop=-/usr/local/bin/kafeniocoin-cli stop
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
  sleep 2
  systemctl enable kfn.service
  systemctl start kfn.service
}

echo ""
echo ""
DOSETUP="y"

if [ $DOSETUP = "y" ]  
then
  apt-get update
  apt install zip unzip git curl wget -y
  cd /usr/local/bin/
  wget $COINZIP
  unzip *.zip
  rm kafeniocoin-qt kafeniocoin-tx kfn-linux.zip
  chmod +x kafeniocoin*
  
  mkdir -p $CONF_DIR
  cd $CONF_DIR
  wget https://download.kafeniocoin.com/kfn.zip
  unzip kfn.zip
  rm kfn.zip

fi

 IP=$(curl -s4 api.ipify.org)
 echo ""
 echo "Configure your masternodes now!"
 echo "Detecting IP address:$IP"
 echo ""
 echo "Enter masternode private key"
 read PRIVKEY
 
  echo "rpcuser=user"`shuf -i 100000-10000000 -n 1` >> kafeniocoin.conf_TEMP
  echo "rpcpassword=pass"`shuf -i 100000-10000000 -n 1` >> kafeniocoin.conf_TEMP
  echo "rpcallowip=127.0.0.1" >> kafeniocoin.conf_TEMP
  echo "rpcport=$RPCPORT" >> kafeniocoin.conf_TEMP
  echo "listen=1" >> kafeniocoin.conf_TEMP
  echo "server=1" >> kafeniocoin.conf_TEMP
  echo "daemon=1" >> kafeniocoin.conf_TEMP
  echo "maxconnections=250" >> kafeniocoin.conf_TEMP
  echo "masternode=1" >> kafeniocoin.conf_TEMP
  echo "" >> kafeniocoin.conf_TEMP
  echo "port=$PORT" >> kafeniocoin.conf_TEMP
  echo "externalip=$IP:$PORT" >> kafeniocoin.conf_TEMP
  echo "masternodeaddr=$IP:$PORT" >> kafeniocoin.conf_TEMP
  echo "masternodeprivkey=$PRIVKEY" >> kafeniocoin.conf_TEMP
  mv kafeniocoin.conf_TEMP kafeniocoin.conf
  cd
  echo ""
  echo -e "Your ip is ${GREEN}$IP:$PORT${NC}"

	## Config Systemctl
	configure_systemd
  
echo ""
echo "Commands:"
echo -e "Start Kafeniocoin Service: ${GREEN}systemctl start kafeniocoin${NC}"
echo -e "Check Kafeniocoin Status Service: ${GREEN}systemctl status kafeniocoin${NC}"
echo -e "Stop Kafeniocoin Service: ${GREEN}systemctl stop kafeniocoin${NC}"
echo -e "Check Masternode Status: ${GREEN}kafeniocoin-cli getmasternodestatus${NC}"

echo ""
echo -e "${GREEN}Kafeniocoin Masternode Installation Done${NC}"
exec bash
exit
