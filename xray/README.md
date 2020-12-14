# [Xray Installer](https://raw.githubusercontent.com/foreversam/script/main/xray/xray-installer.sh)

Xray Installer - An [Xray](https://github.com/XTLS/Xray-core) installation script

## Usage

Make sure you have installed *curl* and *unzip*.

```bash
# For Debian
sudo apt install curl unzip
```

Download this script via *curl*.

```bash
sudo curl -LO --progress-bar 'https://raw.githubusercontent.com/foreversam/script/main/xray/xray-installer.sh'
sudo chmod +x ./xray-installer.sh
```

This will print the help message.

```
./xray-installer.sh
Xray Installer - An Xray installation script
Usage: xray-installer.sh [OPTION]
Example: xray-installer.sh --show-env

Options:
  --install-xray               download and install Xray
  --install-xray-with-systemd  same as --install-xray, but also install systemd service
  --install-geodat             download and install geoip and geosite
  --remove-all                 force remove all Xray files
  --show-env                   show script environment
```

You can edit these values to customize the installation.

```bash
XRAY_LOCATION_ASSET=${XRAY_LOCATION_ASSET:-/usr/local/share/xray}
XRAY_LOCATION_CONFIG=${XRAY_LOCATION_CONFIG:-/usr/local/etc/xray}
BIN_PATH='/usr/local/bin'
LOG_PATH='/var/log/xray'
SERVICE_PATH='/etc/systemd/system'
XRAY_ARCHIVE_NAME='Xray-linux-64.zip'
XRAY_URL="https://github.com/XTLS/Xray-core/releases/latest/download/${XRAY_ARCHIVE_NAME}"
GEOIP_URL='https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat'
GEOSITE_URL='https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat'
```
