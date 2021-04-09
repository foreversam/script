#!/usr/bin/env bash
# A bash script for setting up Xray VLESS server on Debian
# License: MIT

set -eu

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

# confirm prompt
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

# download url output
download() {
    curl -m "${CURL_TIMEOUT}" -L --progress-bar "$1" -o "$2"
}

# check_user 0
check_user() {
    if [[ $(id -u) != "$1" ]]; then
        echo "You need to run it as $(id -un "$1")"
        exit 1
    fi
}

show_config() {
    cat<<EOF
CURL_TIMEOUT=${CURL_TIMEOUT}
DOMAIN=${DOMAIN}

NGINX_CONF_URL=${NGINX_CONF_URL}
NGINX_SITE_ENABLED_URL=${NGINX_SITE_ENABLED_URL}

GEOIP_URL=${GEOIP_URL}
GEOSITE_URL=${GEOSITE_URL}
XRAY_ARCHIVE_URL=${XRAY_ARCHIVE_URL}
XRAY_ASSET_PATH=${XRAY_ASSET_PATH}
XRAY_BIN_PATH=${XRAY_BIN_PATH}
XRAY_CONFIG_PATH=${XRAY_CONFIG_PATH}
XRAY_CONFIG_URL=${XRAY_CONFIG_URL}
XRAY_SERVICE_PATH=${XRAY_SERVICE_PATH}
XRAY_SERVICE_URL=${XRAY_SERVICE_URL}

CERT_PATH=${CERT_PATH}
FULLCHAIN_FILE=${FULLCHAIN_FILE}
KEY_FILE=${KEY_FILE}
EOF
}

install_nginx() {
    echo 'Installing nginx'
    apt install nginx
    systemctl stop nginx
    mkdir -p /etc/nginx/sites-available
    mkdir -p /etc/nginx/sites-enabled
    rm -f /etc/nginx/sites-enabled/*
    mkdir -p "/var/www/${DOMAIN}/public"
    mkdir -p /var/www/acme-challenge
    chown www-data /var/www/acme-challenge
    cat > "/var/www/${DOMAIN}/public/index.html" << EOF
<!DOCTYPE html>
<html><head><title>${DOMAIN}</title></head><body>Hello, world!</body></html>
EOF
    cat > "/var/www/${DOMAIN}/public/robots.txt" << EOF
User-agent: *
Disallow: /
EOF

    echo 'Downloading example config'
    local tmp_dir
    tmp_dir="$(mktemp -d)"
    local NGINX_CONF_FILE="${tmp_dir}/nginx.conf"
    local NGINX_SITE_ENABLED_FILE="${tmp_dir}/${DOMAIN}.conf"
    download "${NGINX_CONF_URL}" "${NGINX_CONF_FILE}"
    download "${NGINX_SITE_ENABLED_URL}" "${NGINX_SITE_ENABLED_FILE}"
    sed -i "s/example.com/${DOMAIN}/" "${NGINX_SITE_ENABLED_FILE}"

    echo 'Installing nginx config'
    install -D -m 644 "${NGINX_CONF_FILE}" /etc/nginx/nginx.conf
    install -D -m 644 "${NGINX_SITE_ENABLED_FILE}" "/etc/nginx/sites-available/${DOMAIN}.conf"
    ln -s "/etc/nginx/sites-available/${DOMAIN}.conf" /etc/nginx/sites-enabled/

    echo 'Removing temp dir'
    rm -rf "${tmp_dir}"

    while true; do
        nginx -t
        if confirm 'Edit nginx config?'; then
            vi /etc/nginx/nginx.conf "/etc/nginx/sites-enabled/${DOMAIN}.conf"
        else
            break
        fi
    done
}

install_xray() {
    echo 'Installing unzip'
    apt install unzip

    local tmp_dir
    tmp_dir="$(mktemp -d)"

    echo 'Downloading Xray-core'
    mkdir "${tmp_dir}/xray"
    download "${XRAY_ARCHIVE_URL}" "${tmp_dir}/xray/xray.zip"
    unzip -q "${tmp_dir}/xray/xray.zip" -d "${tmp_dir}/xray"

    echo 'Downloading geo data'
    mkdir "${tmp_dir}/geodata"
    download "${GEOIP_URL}" "${tmp_dir}/geodata/geoip.dat"
    download "${GEOSITE_URL}" "${tmp_dir}/geodata/geosite.dat"

    echo 'Downloading example config'
    download "${XRAY_CONFIG_URL}" "${tmp_dir}/config.json"

    echo 'Downloading xray.service'
    download "${XRAY_SERVICE_URL}" "${tmp_dir}/xray.service"

    echo 'Adding system user xray'
    adduser xray --system --group --no-create-home

    echo 'Installing'
    install -D -m 755 "${tmp_dir}/xray/xray" "${XRAY_BIN_PATH}/xray"
    install -D -m 644 "${tmp_dir}/geodata/geoip.dat" "${XRAY_ASSET_PATH}/geoip.dat"
    install -D -m 644 "${tmp_dir}/geodata/geosite.dat" "${XRAY_ASSET_PATH}/geosite.dat"
    install -D -m 644 "${tmp_dir}/config.json" "${XRAY_CONFIG_PATH}/config.json"
    install -D -m 644 "${tmp_dir}/xray.service" "${XRAY_SERVICE_PATH}/xray.service"
    systemctl daemon-reload

    echo 'Removing temp dir'
    rm -rf "${tmp_dir}"

    echo 'Updating Xray config'
    local uuid
    uuid="$(xray uuid)"
    local xray_config="${XRAY_CONFIG_PATH}/config.json"
    sed -i "s/0ece3304-25bd-4c97-9f03-7b6f950bf2cc/${uuid}/" "${xray_config}"
    sed -i "s|pathToCertificateFile|${FULLCHAIN_FILE}|" "${xray_config}"
    sed -i "s|pathToKeyFile|${KEY_FILE}|" "${xray_config}"

    while true; do
        xray run -test -c "${xray_config}"
        if confirm 'Edit Xray config?'; then
            vi "${xray_config}"
        else
            break
        fi
    done

    if ! grep -q 'XRAY_LOCATION_' ~/.bashrc && confirm "Add Xray env to '~/.bashrc'?"; then
        echo "export XRAY_LOCATION_ASSET=${XRAY_ASSET_PATH}" >> ~/.bashrc
        echo "export XRAY_LOCATION_CONFIG=${XRAY_CONFIG_PATH}" >> ~/.bashrc
    fi
}

install_acmesh() {
    echo 'Installing acme.sh'
    curl https://get.acme.sh | sh
    ~/.acme.sh/acme.sh --upgrade --auto-upgrade
}

issue_cert() {
    echo "Issuing a cert for ${DOMAIN}, www.${DOMAIN}"
    ~/.acme.sh/acme.sh --issue -d "${DOMAIN}" -d "www.${DOMAIN}" -w /var/www/acme-challenge --keylength ec-256
    echo 'Installing the cert'
    mkdir -p "${CERT_PATH}"
    ~/.acme.sh/acme.sh --install-cert -d "${DOMAIN}" --key-file "${KEY_FILE}" --fullchain-file "${FULLCHAIN_FILE}" --reloadcmd "systemctl restart nginx xray" --ocsp --ecc
    chgrp xray "${KEY_FILE}"
    chmod 640 "${KEY_FILE}"
}

main() {
    show_config
    if ! confirm 'Continue?'; then
        exit
    fi
    check_user 0
    echo 'Starting'
    install_nginx
    install_xray
    install_acmesh
    if ! systemctl start nginx; then
        echo 'Failed to start nginx. Exiting'
        exit 1
    fi
    issue_cert
    systemctl status nginx xray
    echo 'Finished'
}

main
