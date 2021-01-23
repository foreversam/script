#!/bin/bash
# Xray Installer - An Xray installation script
# License: MIT

set -e

# You can edit these values to customize the installation
XRAY_LOCATION_ASSET=${XRAY_LOCATION_ASSET:-/usr/local/share/xray}
XRAY_LOCATION_CONFIG=${XRAY_LOCATION_CONFIG:-/usr/local/etc/xray}
BIN_PATH='/usr/local/bin'
LOG_PATH='/var/log/xray'
SERVICE_PATH='/etc/systemd/system'
XRAY_ARCHIVE_NAME='Xray-linux-64.zip'
XRAY_URL="https://github.com/XTLS/Xray-core/releases/latest/download/${XRAY_ARCHIVE_NAME}"
GEOIP_URL='https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat'
GEOSITE_URL='https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat'

# confirm <prompt>
function confirm() {
    read -r -p "$1 [y/N] " response
    case "${response}" in
        [yY])
            true
            ;;
        *)
            false
            ;;
    esac
}

# Check if running as root
function check_root() {
    if [[ $(id -u) != 0 ]]; then
        echo 'root required'
        exit 1
    fi
}

# Download file from the given url via curl
# dl <url> <output>
function dl() {
    curl -L --progress-bar "$1" -o "$2"
}

# Print help message
function print_help_msg() {
    cat<<EOF
Xray Installer - An Xray installation script
Usage: xray-installer.sh [OPTION]
Example: xray-installer.sh --show-env

Options:
  --install-xray               download and install Xray
  --install-xray-with-systemd  same as --install-xray, but also install systemd service
  --install-geodat             download and install geoip and geosite
  --remove-all                 force remove all Xray files
  --show-env                   show script environment
EOF
}

# Download and install Xray
# install_xray [with-systemd]
function install_xray() {
    tmp_dir="$(mktemp -d)"
    echo "Created a temporary directory ${tmp_dir}"
    echo 'Downloading Xray archive'
    dl "${XRAY_URL}" "${tmp_dir}/${XRAY_ARCHIVE_NAME}"
    echo "Installing Xray-core to ${BIN_PATH}"
    if [[ ! -d "${BIN_PATH}" ]]; then
        mkdir -p "${BIN_PATH}"
    fi
    unzip -q "${tmp_dir}/${XRAY_ARCHIVE_NAME}" -d "${tmp_dir}"
    install -D -m 755 "${tmp_dir}/xray" "${BIN_PATH}"
    if [[ "$1" == 'with-systemd' ]] && [[ -d "${SERVICE_PATH}" ]]; then
        echo 'Installing Xray systemd service'
        cat > "${SERVICE_PATH}/xray.service" <<EOF
[Unit]
Description=Xray Service
Documentation=https://xtls.github.io/
After=network.target nss-lookup.target

[Service]
# User=xray
# CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
# AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
# NoNewPrivileges=true
Environment="XRAY_LOCATION_ASSET=/usr/local/share/xray" "XRAY_LOCATION_CONFIG=/usr/local/etc/xray"
ExecStartPre=/usr/local/bin/xray run -test
ExecStart=/usr/local/bin/xray run
Restart=on-failure
RestartPreventExitStatus=23
# LimitNPROC=10000
# LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target
EOF
        systemctl daemon-reload
    else
        echo 'Skipping installing Xray systemd service'
    fi
    echo 'Cleaning up'
    rm -rf "${tmp_dir}"
    echo 'Finished'
}

# Download and install geoip.dat and geosite.dat
function install_geodat() {
    tmp_dir="$(mktemp -d)"
    echo "Created a temporary directory ${tmp_dir}"
    echo 'Downloading geoip and geosite'
    dl "${GEOIP_URL}" "${tmp_dir}/geoip.dat"
    dl "${GEOSITE_URL}" "${tmp_dir}/geosite.dat"
    echo "Installing geoip and geosite to ${XRAY_LOCATION_ASSET}"
    if [[ ! -d "${XRAY_LOCATION_ASSET}" ]]; then
        mkdir -p "${XRAY_LOCATION_ASSET}"
    fi
    install -D -m 644 "${tmp_dir}/geoip.dat" "${XRAY_LOCATION_ASSET}"
    install -D -m 644 "${tmp_dir}/geosite.dat" "${XRAY_LOCATION_ASSET}"
    echo 'Cleaning up'
    rm -rf "${tmp_dir}"
    echo 'Finished'
}

# Force remove all Xray files
function remove_all() {
    echo 'Stopping xray.service'
    systemctl stop xray.service
    echo "Removing ${SERVICE_PATH}/xray.service, ${SERVICE_PATH}/xray@.service"
    rm -f "${SERVICE_PATH}/xray.service" "${SERVICE_PATH}/xray@.service"
    systemctl daemon-reload
    echo "Removing ${XRAY_LOCATION_ASSET}"
    rm -rf "${XRAY_LOCATION_ASSET}"
    echo "Removing ${XRAY_LOCATION_CONFIG}"
    rm -rf "${XRAY_LOCATION_CONFIG}"
    echo "Removing ${LOG_PATH}"
    rm -rf "${LOG_PATH}"
    echo "Removing ${BIN_PATH}/xray"
    rm -f "${BIN_PATH}/xray"
    echo 'Finished'
}

# Show environment
function show_env() {
    cat<<EOF
XRAY_LOCATION_ASSET=${XRAY_LOCATION_ASSET}
XRAY_LOCATION_CONFIG=${XRAY_LOCATION_CONFIG}
BIN_PATH=${BIN_PATH}
LOG_PATH=${LOG_PATH}
SERVICE_PATH=${SERVICE_PATH}
XRAY_ARCHIVE_NAME=${XRAY_ARCHIVE_NAME}
XRAY_URL=${XRAY_URL}
GEOIP_URL=${GEOIP_URL}
GEOSITE_URL=${GEOSITE_URL}
EOF
}

# Let's break the wall :D
function main() {
    case "$1" in
        '--install-xray')
            check_root
            install_xray
            ;;
        '--install-xray-with-systemd')
            check_root
            install_xray with-systemd
            ;;
        '--install-geodat')
            check_root
            install_geodat
            ;;
        '--remove-all')
            cat<<EOF
This will force remove the listed files/directories:

${SERVICE_PATH}/xray.service
${SERVICE_PATH}/xray@.service
${XRAY_LOCATION_ASSET}
${XRAY_LOCATION_CONFIG}
${LOG_PATH}
${BIN_PATH}/xray

Remember to stop Xray first
EOF
            if confirm 'Remove them?'; then
                check_root
                remove_all
            fi
            ;;
        '--show-env')
            show_env
            ;;
        *)
            print_help_msg
            ;;
    esac
}

main "$1"
