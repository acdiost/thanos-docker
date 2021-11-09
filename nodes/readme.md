添加新节点,需修改 json 文件中 IP 地址, 按需修改 meta 元数据

```bash
docker-compose up -d

sed -i s/changeme/ip/g node-exporter.json
sed -i s/changeme/ip/g cadvisor-exporter.json

# 注册
curl --request PUT --data @node-exporter.json http://consul-address:8500/v1/agent/service/register?replace-existing-checks=1
curl --request PUT --data @cadvisor-exporter.json http://consul-address:8500/v1/agent/service/register?replace-existing-checks=1

# 取消注册,需要等待一会儿才会生效
curl -X PUT http://consul-address:8500/v1/agent/service/deregister/服务id
```

