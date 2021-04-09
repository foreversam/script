# xray-setup.sh

A bash script for setting up Xray VLESS server on Debian

## Warning

This script has not been tested yet.

## Usage

### Configure your DNS

| Type | Name | IPv4 address |
| ---- | ---- | ------------ |
|  A   | www  |   x.x.x.x    |
|  A   |  @   |   x.x.x.x    |

### Config

Download this script and make necessary changes.

```
# curl -LO --progress-bar 'https://raw.githubusercontent.com/foreversam/script/main/xray-setup.sh/xray-setup.sh'
# chmod u+x xray-setup.sh
# vi xray-setup.sh
```

You can edit these values to customize the installation. A certificate will be issued to `"${DOMAIN}"` and `"www.${DOMAIN}"`.

```bash
# General settings
export CURL_TIMEOUT=30
export DOMAIN='example.com'

# Nginx settings
export NGINX_CONF_URL='https://raw.githubusercontent.com/foreversam/script/main/xray-setup.sh/config/nginx/nginx.conf'
export NGINX_SITE_ENABLED_URL='https://raw.githubusercontent.com/foreversam/script/main/xray-setup.sh/config/nginx/sites-enabled/example.com.conf'

# Xray settings
export GEOIP_URL='https://github.com/v2fly/geoip/releases/latest/download/geoip.dat'
export GEOSITE_URL='https://github.com/v2fly/domain-list-community/releases/latest/download/dlc.dat'
export XRAY_ARCHIVE_URL='https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip'
export XRAY_ASSET_PATH=${XRAY_LOCATION_ASSET:-/usr/local/share/xray}
export XRAY_BIN_PATH='/usr/local/bin'
export XRAY_CONFIG_PATH=${XRAY_LOCATION_CONFIG:-/usr/local/etc/xray}
export XRAY_CONFIG_URL='https://raw.githubusercontent.com/foreversam/script/main/xray-setup.sh/config/xray/server.json'
export XRAY_SERVICE_PATH='/etc/systemd/system'
export XRAY_SERVICE_URL='https://raw.githubusercontent.com/foreversam/config/main/xray/xray.service'

# acme.sh settings
export CERT_PATH="/usr/local/etc/acme.sh/${DOMAIN}_ecc"
export FULLCHAIN_FILE="${CERT_PATH}/fullchain.cer"
export KEY_FILE="${CERT_PATH}/${DOMAIN}.key"
```

### Run

You must run it as root.

```
# ./xray-setup.sh
```
