#!/bin/sh

FWMARK_ID=1
TABLE_ID=100
SO_MARK='0xff'
MANGLE1_NAME='MY_MANGLE1'
MANGLE2_NAME='MY_MANGLE2'
PROXY_IP='127.0.0.1'
PROXY_PORT=3346

show_help() {
    cat <<EOF
usage: $0 <command>
commands:
  start  start tproxy
  stop   stop tproxy
EOF
}

check_root() {
    if [ "$(id -u)" != 0 ]; then
        echo "You need to run it as root"
        exit 1
    fi
}

start_tproxy() {
    echo 'starting'
    ip rule add fwmark "$FWMARK_ID" table "$TABLE_ID"
    ip route add local 0.0.0.0/0 dev lo table "$TABLE_ID"

    iptables -t mangle -N "$MANGLE1_NAME"
    iptables -t mangle -A "$MANGLE1_NAME" -d 0.0.0.0/8 -j RETURN
    iptables -t mangle -A "$MANGLE1_NAME" -d 10.0.0.0/8 -j RETURN
    iptables -t mangle -A "$MANGLE1_NAME" -d 100.64.0.0/10 -j RETURN
    iptables -t mangle -A "$MANGLE1_NAME" -d 127.0.0.0/8 -j RETURN
    iptables -t mangle -A "$MANGLE1_NAME" -d 169.254.0.0/16 -j RETURN
    iptables -t mangle -A "$MANGLE1_NAME" -d 172.16.0.0/12 -j RETURN
    iptables -t mangle -A "$MANGLE1_NAME" -d 192.0.0.0/24 -j RETURN
    iptables -t mangle -A "$MANGLE1_NAME" -d 192.0.2.0/24 -j RETURN
    iptables -t mangle -A "$MANGLE1_NAME" -d 192.88.99.0/24 -j RETURN
    iptables -t mangle -A "$MANGLE1_NAME" -d 192.168.0.0/16 -j RETURN
    iptables -t mangle -A "$MANGLE1_NAME" -d 198.18.0.0/15 -j RETURN
    iptables -t mangle -A "$MANGLE1_NAME" -d 198.51.100.0/24 -j RETURN
    iptables -t mangle -A "$MANGLE1_NAME" -d 203.0.113.0/24 -j RETURN
    iptables -t mangle -A "$MANGLE1_NAME" -d 224.0.0.0/4 -j RETURN
    iptables -t mangle -A "$MANGLE1_NAME" -d 240.0.0.0/4 -j RETURN
    iptables -t mangle -A "$MANGLE1_NAME" -d 255.255.255.255/32 -j RETURN
    iptables -t mangle -A "$MANGLE1_NAME" -j RETURN -m mark --mark "$SO_MARK"
    iptables -t mangle -A "$MANGLE1_NAME" -p tcp -j TPROXY --on-ip "$PROXY_IP" --on-port "$PROXY_PORT" --tproxy-mark "$FWMARK_ID"
    iptables -t mangle -A "$MANGLE1_NAME" -p udp -j TPROXY --on-ip "$PROXY_IP" --on-port "$PROXY_PORT" --tproxy-mark "$FWMARK_ID"
    iptables -t mangle -A PREROUTING -j "$MANGLE1_NAME"

    iptables -t mangle -N "$MANGLE2_NAME"
    iptables -t mangle -A "$MANGLE2_NAME" -d 0.0.0.0/8 -j RETURN
    iptables -t mangle -A "$MANGLE2_NAME" -d 10.0.0.0/8 -j RETURN
    iptables -t mangle -A "$MANGLE2_NAME" -d 100.64.0.0/10 -j RETURN
    iptables -t mangle -A "$MANGLE2_NAME" -d 127.0.0.0/8 -j RETURN
    iptables -t mangle -A "$MANGLE2_NAME" -d 169.254.0.0/16 -j RETURN
    iptables -t mangle -A "$MANGLE2_NAME" -d 172.16.0.0/12 -j RETURN
    iptables -t mangle -A "$MANGLE2_NAME" -d 192.0.0.0/24 -j RETURN
    iptables -t mangle -A "$MANGLE2_NAME" -d 192.0.2.0/24 -j RETURN
    iptables -t mangle -A "$MANGLE2_NAME" -d 192.88.99.0/24 -j RETURN
    iptables -t mangle -A "$MANGLE2_NAME" -d 192.168.0.0/16 -j RETURN
    iptables -t mangle -A "$MANGLE2_NAME" -d 198.18.0.0/15 -j RETURN
    iptables -t mangle -A "$MANGLE2_NAME" -d 198.51.100.0/24 -j RETURN
    iptables -t mangle -A "$MANGLE2_NAME" -d 203.0.113.0/24 -j RETURN
    iptables -t mangle -A "$MANGLE2_NAME" -d 224.0.0.0/4 -j RETURN
    iptables -t mangle -A "$MANGLE2_NAME" -d 240.0.0.0/4 -j RETURN
    iptables -t mangle -A "$MANGLE2_NAME" -d 255.255.255.255/32 -j RETURN
    iptables -t mangle -A "$MANGLE2_NAME" -j RETURN -m mark --mark "$SO_MARK"
    iptables -t mangle -A "$MANGLE2_NAME" -p tcp -j MARK --set-mark 1
    iptables -t mangle -A "$MANGLE2_NAME" -p udp -j MARK --set-mark 1
    iptables -t mangle -A OUTPUT -j "$MANGLE2_NAME"
    echo 'end'
}

stop_tproxy() {
    echo 'stopping'
    ip rule del fwmark "$FWMARK_ID" table "$TABLE_ID"
    ip route flush table "$TABLE_ID"

    iptables -t mangle -D OUTPUT -j "$MANGLE2_NAME"
    iptables -t mangle -D PREROUTING -j "$MANGLE1_NAME"
    iptables -t mangle -F "$MANGLE2_NAME"
    iptables -t mangle -F "$MANGLE1_NAME"
    iptables -t mangle -X "$MANGLE2_NAME"
    iptables -t mangle -X "$MANGLE1_NAME"
    echo 'end'
}

main() {
    case "$@" in
        'start')
            check_root
            start_tproxy
            ;;
        'stop')
            check_root
            stop_tproxy
            ;;
        *)
            show_help
            exit 1
            ;;
    esac
}

main "$@"
