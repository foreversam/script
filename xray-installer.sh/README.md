# xray-installer.sh

An [Xray](https://github.com/XTLS/Xray-core) installation script

## Usage

Make sure you have installed **curl** and **unzip**.

```
$ sudo apt install curl unzip
```

Download this script via curl.

```
$ sudo curl -LO --progress-bar 'https://raw.githubusercontent.com/foreversam/script/main/xray-installer.sh/xray-installer.sh'
$ sudo chmod +x ./xray-installer.sh
```

This will print the help message.

```
$ ./xray-installer.sh help
Usage: xray-installer.sh <command> [option]
Example: xray-installer.sh install xray --with-service

Command:
  install  install xray or geodat
  remove   remove xray or geodat
  purge    remove all related files/folders
  env      show environment
  help     print this help message

Option:
  --with-service  also install an example systemd service
```

You can edit these values to customize the installation.

```bash
export ASSET_PATH=${XRAY_LOCATION_ASSET:-/usr/local/share/xray}
export BIN_PATH='/usr/local/bin'
export CONFIG_PATH=${XRAY_LOCATION_CONFIG:-/usr/local/etc/xray}
export CURL_TIMEOUT=30
export GEOIP_URL='https://github.com/v2fly/geoip/releases/latest/download/geoip.dat'
export GEOSITE_URL='https://github.com/v2fly/domain-list-community/releases/latest/download/dlc.dat'
export LOG_PATH='/var/log/xray'
# export PROXY='socks5h://127.0.0.1:1080'
export SERVICE_PATH='/etc/systemd/system'
export XRAY_VERSION='latest'
```
