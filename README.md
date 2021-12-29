# Thanos docker 部署


## 初始化

1. `git clone`
2. IP 替换成实际地址
3. 部署 minio, 完成后创建 thanos bucket
4. 部署 consul
5. 部署 thanos

替换 IP 的文件：
- sub_prometheus/minio/bucket_storage.yaml
- prometheus/prometheus.yml
- prometheus/alertmanager.yml
- minio/bucket_storage.yaml


## Grafana
http://IP/

8919 面板需设置 thanos 数据源才能正常显示

## Prometheus
http://IP:9090/

## Thanos query
http://IP:9091/

## minio
http://IP:9000/

## alertmanager
http://IP:9093/

## consul
http://IP:8500/

## node-exporter
http://IP:9100/

## cadvisor
http://IP:8080/

## telegraf
http://IP:9273/

---

## 添加新节点

参考 nodes 目录下的 readme

#### 注册

`curl -X PUT -d '{"id": "node-exporter","name": "node-exporter-IP","address": "IP","port": 9100,"tags": ["test"],"checks": [{"http": "http://IP:9100/metrics", "interval": "5s"}]}'  http://IP:8500/v1/agent/service/register`

#### 取消注册

`curl -X PUT http://IP:8500/v1/agent/service/deregister/node-exporter`


---

## 添加子集群

复制 sub_prometheus 文件至节点，按需修改 IP 及其相关信息后启动。

---

## TODO

- telegraf
- loki
