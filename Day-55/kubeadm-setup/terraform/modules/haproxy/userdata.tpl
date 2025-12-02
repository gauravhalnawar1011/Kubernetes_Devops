#!/bin/bash
set -euo pipefail
exec > /var/log/haproxy-userdata.log 2>&1

echo "=== Starting HAProxy setup ==="

apt-get update -y
apt-get install -y haproxy

echo "Generating HAProxy config..."

cat <<EOF >/etc/haproxy/haproxy.cfg
global
    log /dev/log local0
    log /dev/log local1 notice
    maxconn 60000
    daemon

defaults
    log     global
    mode    tcp
    option  tcplog
    option  dontlognull
    timeout connect 10s
    timeout client  300s
    timeout server  300s
    timeout tunnel  300s
    retries 3

# Frontend for Kubernetes API server
frontend k8s-apiserver
    bind *:6443
    mode tcp
    option tcplog
    default_backend k8s-masters

# Backend pointing to control-plane nodes
backend k8s-masters
    mode tcp
    option tcp-check
    balance roundrobin
%{ for i, ip in master_ips ~}
    server master-${i} ${ip}:6443 check fall 3 rise 2
%{ endfor ~}

# Optional HAProxy stats UI
listen stats
    bind *:8404
    mode http
    stats enable
    stats hide-version
    stats realm HAProxy\ Statistics
    stats uri /
    stats refresh 10s
EOF

systemctl enable haproxy
systemctl restart haproxy

echo "HAProxy configured with backend master IPs:"
%{ for i, ip in master_ips ~}
echo " - ${ip}"
%{ endfor ~}

echo "=== HAProxy Setup Complete ==="
