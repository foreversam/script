#!/usr/bin/env bash

show_help() {
    cat << EOF
$0 - install xray

Usage: $0 [options]

Options:
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
EOF
}

confirm() {
    read -r -p "$1 [y/N] " resp
    case "$resp" in
        [yY])
            true
            ;;
        *)
            false
            ;;
    esac
}

# download <url> <output>
download() {
    if [[ "$1" = '' ]] || [[ "$2" = '' ]]; then
        echo 'download() requires url and output'
        return 1
    fi
    curl -m "$curl_timeout" -x "$proxy" -L# "$1" -o "$2"
}

# Check if running as the specified user
check_user() {
    if [[ -z "$1" ]]; then
        echo 'check_user() requires uid'
        return 1
    fi
    if [[ $(id -u) != "$1" ]]; then
        echo "You need to run it as $(id -un "$1")"
        return 1
    fi
}

# load_config [file]
load_config() {
    # Set some default values
    curl_timeout=60
    geoip_url='https://github.com/v2fly/geoip/releases/latest/download/geoip.dat'
    geosite_url='https://github.com/v2fly/domain-list-community/releases/latest/download/dlc.dat'
    proxy="$http_proxy"
    xray_archive_url='https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip'
    xray_assets_path=/usr/local/share/xray
    xray_bin_path=/usr/local/bin
    xray_config_path=/usr/local/etc/xray
    xray_config_url='https://raw.githubusercontent.com/foreversam/config/main/xray/server.json'
    xray_service_path=/etc/systemd/system
    xray_service_url='https://raw.githubusercontent.com/foreversam/config/main/xray/xray.service'

    if [[ -r "$1" ]]; then
        echo "Loading config: $1"
        . "$1"
    fi
}

show_config() {
    cat << EOF
curl_timeout=$curl_timeout
geoip_url=$geoip_url
geosite_url=$geosite_url
proxy=$proxy
xray_archive_url=$xray_archive_url
xray_assets_path=$xray_assets_path
xray_bin_path=$xray_bin_path
xray_config_path=$xray_config_path
xray_config_url=$xray_config_url
xray_service_path=$xray_service_path
xray_service_url=$xray_service_url
EOF
}

# install_this <asset>
install_this() {
    if ! confirm "Are you going to install $1?"; then
        exit
    fi

    local file_name
    local install_dst
    local mode
    local url

    case "$1" in
        'config')
            file_name='config.json'
            install_dst="$xray_config_path/$file_name"
            mode=644
            url="$xray_config_url"
            ;;
        'geoip')
            file_name='geoip.dat'
            install_dst="$xray_assets_path/$file_name"
            mode=644
            url="$geoip_url"
            ;;
        'geosite')
            file_name='geosite.dat'
            install_dst="$xray_assets_path/$file_name"
            mode=644
            url="$geosite_url"
            ;;
        'service')
            file_name='xray.service'
            install_dst="$xray_service_path/$file_name"
            mode=644
            url="$xray_service_url"
            ;;
        'xray')
            file_name='xray-archive.zip'
            install_dst="$xray_bin_path/xray"
            mode=755
            url="$xray_archive_url"
            ;;
        *)
            echo "Wrong asset: '$1'"
            exit 1
            ;;
    esac

    tmp_dir="$(mktemp -d)"
    echo "Created a temp dir $tmp_dir"

    echo "Downloading $url"
    if ! download "$url" "$tmp_dir/$file_name"; then
        echo "Failed to download $url"
        echo "Removing temp dir $tmp_dir"
        rm -rf "$tmp_dir"
        exit 1
    fi

    if [[ "$1" == 'xray' ]]; then
        if ! unzip -q "$tmp_dir/$file_name" -d "$tmp_dir"; then
            echo "Failed to unzip $tmp_dir/$file_name"
            echo "Removing temp dir $tmp_dir"
            rm -rf "${tmp_dir}"
            exit 1
        fi
    fi

    echo "Installing $install_dst"
    if [[ "$1" == 'xray' ]]; then
        install -D -m "$mode" "$tmp_dir/xray" "$install_dst"
    else
        install -D -m "$mode" "$tmp_dir/$file_name" "$install_dst"
    fi

    if [[ "$1" == 'service' ]]; then
        systemctl daemon-reload
    fi

    echo "Removing temp dir $tmp_dir"
    rm -rf "$tmp_dir"
}

# remove_this <asset>
remove_this() {
    if ! confirm "Are you going to remove $1?"; then
        exit
    fi

    local to_be_removed
    case "$1" in
        'config')
            to_be_removed="$xray_config_path"
            ;;
        'geoip')
            to_be_removed="$xray_assets_path/geoip.dat"
            ;;
        'geosite')
            to_be_removed="$xray_assets_path/geosite.dat"
            ;;
        'service')
            to_be_removed="$xray_service_path/xray.service"
            ;;
        'xray')
            to_be_removed="$xray_bin_path/xray"
            ;;
        *)
            echo "Wrong asset: '$1'"
            exit 1
            ;;
    esac

    echo "Removing $to_be_removed"
    sleep 3
    rm -rf "$to_be_removed"
    rmdir --ignore-fail-on-non-empty "$xray_config_path" "$xray_assets_path"

    if [[ "$1" == 'service' ]]; then
        systemctl daemon-reload
    fi
}

main() {
    if [[ "$#" -eq 0 ]]; then
        show_help
        exit 1
    fi

    if ! parsed=$(getopt -n "$0" -o x:h -l install:,remove:,proxy:,show-config,help -- "$@"); then
        show_help
        exit 1
    fi
    eval set -- "$parsed"

    if ! check_user 0; then
        exit 1
    fi

    load_config "$HOME/.config/xray-installer.sh/config"

    while true; do
        case "$1" in
            '--install')
                asset_to_be_installed="$2"
                shift 2
                ;;
            '--remove')
                asset_to_be_removed="$2"
                shift 2
                ;;
            '-x' | '--proxy')
                proxy="$2"
                shift 2
                ;;
            '--show-config')
                show_config
                shift
                ;;
            '-h' | '--help')
                show_help
                shift
                ;;
            '--')
                shift
                break
                ;;
            *)
                echo "Invalid option: '$1'"
                show_help
                exit 1
                ;;
        esac
    done

    if [[ "$asset_to_be_installed" != '' ]]; then
        install_this "$asset_to_be_installed"
    fi

    if [[ "$asset_to_be_removed" != '' ]]; then
        remove_this "$asset_to_be_removed"
    fi
}

main "$@"
