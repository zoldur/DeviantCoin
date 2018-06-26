# Deviant Coin
Shell script to install an [Deviant Coin Masternode](http://http://deviantcoin.io/) on a Linux server running Ubuntu 16.04. Use it on your own risk.  
***

## Installation:  

wget -N https://raw.githubusercontent.com/zoldur/DeviantCoin/master/deviant_install.sh  
bash deviant_install.sh
***

## Desktop wallet setup  

After the MN is up and running, you need to configure the desktop wallet accordingly. Here are the steps:  
1. Open the Deviant Coin Desktop Wallet.  
2. Go to RECEIVE and create a New Address: **MN1**  
3. Send **5000** DEV to **MN1**.  
4. Wait for 15 confirmations.  
5. Go to **Help -> "Debug window - Console"**  
6. Type the following command: **masternode outputs**  
7. Go to **Masternodes** tab  
8. Click **Create** and fill the details:  
* Alias: **MN1**  
* Address: **VPS_IP:PORT**  
* Privkey: **Masternode Private Key**  
* TxHash: **First value from Step 6**  
* Output index:  **Second value from Step 6**  
* Reward address: leave blank  
* Reward %: leave blank  
9. Click **OK** to add the masternode  
10. Click **Start All**  
***

## Usage:  
```
deviant-cli masternode status  
deviant-cli getinfo  
```  
Also, if you want to check/start/stop **Deviant** , run one of the following commands as **root**:
```
systemctl status Deviant #To check the service is running.  
systemctl start Deviant #To start Deviant service.  
systemctl stop Deviant #To stop Deviant service.  
systemctl is-enabled DEviant #To check whetether Deviant service is enabled on boot or not.  
```  
***

## Donations
  
Any donation is highly appreciated  

**BTC**: 1BzeQ12m4zYaQKqysGNVbQv1taN7qgS8gY  
**ETH**: 0x39d10fe57611c564abc255ffd7e984dc97e9bd6d  
**LTC**: LXrWbfeejNQRmRvtzB6Te8yns93Tu3evGf  

