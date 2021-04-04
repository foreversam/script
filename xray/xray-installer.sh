#!/usr/bin/env bash
# xray-installer.sh - An Xray installation script
# License: MIT

set -e

# You can edit these values to customize the installation
export ASSET_PATH=${XRAY_LOCATION_ASSET:-/usr/local/share/xray}
export BIN_PATH='/usr/local/bin'
export CONFIG_PATH=${XRAY_LOCATION_CONFIG:-/usr/local/etc/xray}
export GEOIP_URL='https://github.com/v2fly/geoip/releases/latest/download/geoip.dat'
export GEOSITE_URL='https://github.com/v2fly/domain-list-community/releases/latest/download/dlc.dat'
export LOG_PATH='/var/log/xray'
# export PROXY='socks5h://127.0.0.1:1080'
export SERVICE_PATH='/etc/systemd/system'
export XRAY_VERSION='latest'

# Show help message
show_help_msg() {
    cat<<EOF
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
EOF
}

# Enter y to continue
confirm() {
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

# Download file from the given url via curl
dl() {
    curl -m 30 -x "${PROXY}" -L --progress-bar "$1" -o "$2"
}

# Check if running as the specified user
check_user() {
    if [[ -z "$1" ]]; then
        echo 'function check_user() requires an argument'
        exit 1
    fi
    if [[ $(id -u) != "$1" ]]; then
        echo "You need to run as $(id -un "$1")"
        exit 1
    fi
}

# Show environment
show_env() {
    cat<<EOF
ASSET_PATH=${ASSET_PATH}
BIN_PATH=${BIN_PATH}
CONFIG_PATH=${CONFIG_PATH}
GEOIP_URL=${GEOIP_URL}
GEOSITE_URL=${GEOSITE_URL}
LOG_PATH=${LOG_PATH}
PROXY=${PROXY}
SERVICE_PATH=${SERVICE_PATH}
XRAY_VERSION=${XRAY_VERSION}
EOF
}

# Get Xray archive name
get_xray_archive_name() {
    if [[ "$(uname)" == 'Linux' ]]; then
        case "$(uname -m)" in
            'amd64' | 'x86_64')
                XRAY_ARCHIVE_NAME='Xray-linux-64.zip'
                ;;
            'armv8' | 'aarch64')
                XRAY_ARCHIVE_NAME='Xray-linux-arm64-v8a.zip'
                if [[ "$(uname -o)" == 'Android' ]]; then
                    XRAY_ARCHIVE_NAME='Xray-android-arm64-v8a.zip'
                fi
                ;;
        esac
    fi
}

# Install Xray
install_xray() {
    get_xray_archive_name
    if [[ -z "${XRAY_ARCHIVE_NAME}" ]]; then
        echo "$(uname -m) is not supported by this script"
        exit 1
    fi
    if [[ "${XRAY_VERSION}" == 'latest' ]]; then
        local xray_url="https://github.com/XTLS/Xray-core/releases/latest/download/${XRAY_ARCHIVE_NAME}"
    else
        local xray_url="https://github.com/XTLS/Xray-core/releases/download/${XRAY_VERSION}/${XRAY_ARCHIVE_NAME}"
    fi
    echo "You are going to download ${xray_url}"
    if ! confirm 'Do you want to continue?'; then
        exit
    fi
    tmp_dir="$(mktemp -d)"
    echo "Created a temporary directory ${tmp_dir}"
    echo "Downloading ${XRAY_ARCHIVE_NAME}"
    if ! dl "${xray_url}" "${tmp_dir}/${XRAY_ARCHIVE_NAME}"; then
        echo "Failed to download ${xray_url}"
        echo "Removing ${tmp_dir}"
        rm -rf "${tmp_dir}"
        exit 1
    fi
    if ! unzip -q "${tmp_dir}/${XRAY_ARCHIVE_NAME}" -d "${tmp_dir}"; then
        echo "Failed to unzip ${tmp_dir}/${XRAY_ARCHIVE_NAME}"
        echo "Removing ${tmp_dir}"
        rm -rf "${tmp_dir}"
        exit 1
    fi
    echo "Installing ${BIN_PATH}/xray"
    if [[ ! -d "${BIN_PATH}" ]]; then
        mkdir -p "${BIN_PATH}"
    fi
    install -D -m 755 "${tmp_dir}/xray" "${BIN_PATH}"
    if [[ "$1" == 'with-service' ]] && [[ -d "${SERVICE_PATH}" ]] && [[ ! -f "${SERVICE_PATH}/xray.service" ]]; then
        echo "Installing ${SERVICE_PATH}/xray.service"
        cat > "${SERVICE_PATH}/xray.service" <<EOF
[Unit]
Description=Xray Service
Documentation=https://xtls.github.io/
After=network.target nss-lookup.target

[Service]
# User=xray
# Group=xray
# CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
# AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
# NoNewPrivileges=true
Environment="XRAY_LOCATION_ASSET=${ASSET_PATH}" "XRAY_LOCATION_CONFIG=${CONFIG_PATH}"
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
        echo 'Skipping installing xray.service'
    fi
    echo "Removing ${tmp_dir}"
    rm -rf "${tmp_dir}"
    if [[ -f "${SERVICE_PATH}/xray.service" ]] && confirm 'Restart xray.service?'; then
        echo 'Restarting xray.service'
        if ! systemctl restart xray; then
            echo 'Failed to restart xray.service'
            exit 1
        fi
    fi
    "${BIN_PATH}"/xray version
    echo 'Finished'
}

# Install GeoIP and GeoSite
install_geodat() {
    echo "You are going to download ${GEOIP_URL}, ${GEOSITE_URL}"
    if ! confirm 'Do you want to continue?'; then
        exit
    fi
    tmp_dir="$(mktemp -d)"
    echo "Created a temporary directory ${tmp_dir}"
    echo 'Downloading GeoIP and GeoSite'
    if ! dl "${GEOIP_URL}" "${tmp_dir}/geoip.dat"; then
        echo "Failed to download ${GEOIP_URL}"
        echo "Removing ${tmp_dir}"
        rm -rf "${tmp_dir}"
        exit 1
    fi
    if ! dl "${GEOSITE_URL}" "${tmp_dir}/geosite.dat"; then
        echo "Failed to download ${GEOSITE_URL}"
        echo "Removing ${tmp_dir}"
        rm -rf "${tmp_dir}"
        exit 1
    fi
    echo "Installing ${ASSET_PATH}/geoip.dat, ${ASSET_PATH}/geosite.dat"
    if [[ ! -d "${ASSET_PATH}" ]]; then
        mkdir -p "${ASSET_PATH}"
    fi
    install -D -m 644 "${tmp_dir}/geoip.dat" "${ASSET_PATH}"
    install -D -m 644 "${tmp_dir}/geosite.dat" "${ASSET_PATH}"
    echo "Removing ${tmp_dir}"
    rm -rf "${tmp_dir}"
    if [[ -f "${SERVICE_PATH}/xray.service" ]] && confirm 'Restart xray.service?'; then
        echo 'Restarting xray.service'
        if ! systemctl restart xray; then
            echo 'Failed to restart xray.service'
            exit 1
        fi
    fi
    echo 'Finished'
}

# Remove
remove() {
    case "$1" in
        'xray')
            local to_be_removed=("${BIN_PATH}/xray" "${SERVICE_PATH}/xray.service")
            ;;
        'geodat')
            local to_be_removed=("${ASSET_PATH}")
            ;;
        'purge')
            local to_be_removed=("${BIN_PATH}/xray" "${SERVICE_PATH}/xray.service" "${ASSET_PATH}" "${CONFIG_PATH}" "${LOG_PATH}")
            ;;
        *)
            echo 'function remove() requires an valid argument(xray, geodat, purge)'
            exit 1
            ;;
    esac
    echo 'The listed files/folders will be removed:'
    for i in "${!to_be_removed[@]}"; do
        echo "  ${to_be_removed[$i]}"
    done
    if ! confirm 'Do you want to continue?'; then
        exit
    fi
    if [[ "$1" != 'geodat' ]] && [[ -f "${SERVICE_PATH}/xray.service" ]]; then
        echo 'Stopping xray.service'
        if ! systemctl stop xray; then
            echo 'Failed to stop xray.service'
            exit 1
        fi
    fi
    echo 'Removing'
    rm -rf "${to_be_removed[@]}"
    if [[ "$1" != 'geodat' ]] && [[ -d "${SERVICE_PATH}" ]]; then
        systemctl daemon-reload
    fi
    echo "Finished"
}

main() {
    case "$1" in
        'install')
            check_user 0
            case "$2" in
                'xray')
                    if [[ "$3" == '--with-service' ]]; then
                        install_xray with-service
                    else
                        install_xray
                    fi
                    ;;
                'geodat')
                    install_geodat
                    ;;
                *)
                    echo 'Example: xray-installer.sh install xray --with-service'
                    echo "Try 'xray-installer.sh help' for help"
                    exit 1
                    ;;
            esac
            ;;
        'remove')
            check_user 0
            case "$2" in
                'xray')
                    remove xray
                    ;;
                'geodat')
                    remove geodat
                    ;;
                *)
                    echo 'Example: xray-installer.sh remove xray'
                    echo "Try 'xray-installer.sh help' for help"
                    exit 1
                    ;;
            esac
            ;;
        'purge')
            check_user 0
            remove purge
            ;;
        'env')
            show_env
            ;;
        'help')
            show_help_msg
            ;;
        *)
            echo "Invalid command: '$1'"
            echo "Try 'xray-installer.sh help' for help"
            exit 1
            ;;
    esac
}

main "$@"
