# xray-installer.sh

xray-installer.sh - install xray

## Usage

Make sure you have installed these packages.

```
curl unzip
```

Download this script via curl.

```
# curl -LO# 'https://raw.githubusercontent.com/foreversam/script/main/xray-installer.sh/xray-installer.sh'
# chmod u+x ./xray-installer.sh
```

This will print the help message.

```
# ./xray-installer.sh -h
./xray-installer.sh - install xray

Usage: ./xray-installer.sh [options]

Options:
  -c, --config <file>                   specify the config file
  --install <asset>                     install the specified asset
  --remove <asset>                      remove the specified asset
  -x, --proxy [protocol://]host[:port]  use the specified proxy
  --show-config                         show current config
  -h, --help                            show this help message

Assets:
  config   an example config.json
  geoip    geoip.dat for routing
  geosite  geosite.dat for routing
  service  an example xray.service
  xray     xray-core
```

Install Xray-core.

```
# ./xray-installer.sh --install xray
```
