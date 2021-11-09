#!/usr/bin/env sh
# author: dawn
# desc: 安装监控节点，按需修改
set -e

function config_env(){

yum install -y docker-ce docker-compose

echo 'net.bridge.bridge-nf-call-iptables = 1' >> /etc/sysctl.conf
echo 'net.bridge.bridge-nf-call-ip6tables = 1' >> /etc/sysctl.conf
sysctl -p

cat <<EOF | sudo tee /etc/docker/daemon.json
{
    "insecure-registries": ["private-registry.com"],
    "exec-opts": ["native.cgroupdriver=systemd"],
    "log-driver": "json-file",
    "log-opts": {
    "max-size": "100m"
    },
    "storage-driver": "overlay2"
}
EOF

cat <<EOF | sudo tee >> /etc/hosts
IP private-registry.com
EOF

systemctl restart docker
}

IP_NIC=$(ip route | grep default | awk '{print $5}')
IP=$(ip addr show ${IP_NIC} | grep inet | grep brd | awk '{print $2}' | cut -d / -f1)

function configuretion(){
mkdir /srv/prometheus

cat <<EOF | sudo tee /srv/prometheus/docker-compose.yml
version: '3.0'
services:

  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter-${IP}
    restart: unless-stopped
    hostname: \$HOSTNAME
    network_mode: host
#    ports:
#      - "9100:9100"
    cap_add:
      - SYS_TIME
    volumes:
      - /:/host:ro
      - /proc:/host/proc
      - /sys:/host/sys
    command:
      - "--path.procfs=/host/proc"
      - "--path.sysfs=/host/sys"
      - "--collector.filesystem.ignored-mount-points=^/(dev|proc|sys|var/lib/docker/.+)(\$\$|/)"
      - "--collector.filesystem.ignored-fs-types=^(autofs|binfmt_misc|cgroup|configfs|debugfs|devpts|devtmpfs|fusectl|hugetlbfs|mqueue|overlay|proc|procfs|pstore|rpc_pipefs|securityfs|sysfs|tracefs)\$\$"

  cadvisor:
    image: prom/cadvisor:v0.40.0
    container_name: cadvisor-${IP}
    restart: unless-stopped
    hostname: \$HOSTNAME
    network_mode: host
    privileged: true
#    ports:
#      - "8080:8080"
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
      - /dev/disk/:/dev/disk:ro
    devices:
      - "/dev/kmsg:/dev/kmsg"
EOF

cat <<EOF | sudo tee /srv/prometheus/node-exporter.json
        {
            "ID": "node-exporter-${IP}",
            "NAME": "node-exproter-${IP}",
            "TAGS": [
                "node-exporter"
            ],
            "Address": "${IP}",
            "Port": 9100,
            "Meta": {
                "ip": "${IP}",
                "app": "service",
                "environment": "prodution",
                "team": "my-team",
                "project": "my-project"
            },
            "EnableTagOverride": false,
            "Check": {
                "HTTP": "http://${IP}:9100/metrics",
                "Interval": "30s"
            },
            "Weights": {
                "Passing": 10,
                "Warning": 1
            }
        }
EOF
cat <<EOF | sudo tee /srv/prometheus/cadvisor-exporter.json
        {
            "ID": "cadvisor-exporter-${IP}",
            "NAME": "cadvisor-exproter-${IP}",
            "TAGS": [
                "cadvisor-exporter"
            ],
            "Address": "${IP}",
            "Port": 8080,
            "Meta": {
                "ip": "${IP}",
                "app": "my-service",
                "environment": "prodution",
                "team": "my-team",
                "project": "my-project"
            },
            "EnableTagOverride": false,
            "Check": {
                "HTTP": "http://${IP}:8080/metrics",
                "Interval": "30s"
            },
            "Weights": {
                "Passing": 10,
                "Warning": 1
            }
        }
EOF
}

function main(){
config_env
configuretion
docker-compose -f /srv/prometheus/docker-compose.yml up -d

/usr/bin/curl --request PUT --data @/srv/prometheus/cadvisor-exporter.json http://consul-address:8500/v1/agent/service/register?replace-existing-checks=1
/usr/bin/curl --request PUT --data @/srv/prometheus/node-exporter.json http://consul-address:8500/v1/agent/service/register?replace-existing-checks=1

# 取消注册
#curl -X PUT http://consul-address:8500/v1/agent/service/deregister/node-exporter-${IP}
#curl -X PUT http://consul-address:8500/v1/agent/service/deregister/cadvisor-exporter-${IP}
}

main
