# VFG日志收集系统快速部署指南

## 系统概述

VictoriaLogs + Fluent Bit + Grafana (VFG) 是一套完整的日志收集、存储和可视化解决方案。

### 架构图

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   应用服务      │───▶│   Fluent Bit    │───▶│  VictoriaLogs   │───▶│    Grafana      │
│                 │    │                 │    │                 │    │                 │
│ • Nginx         │    │ • 日志收集      │    │ • 日志存储      │    │ • 日志可视化    │
│ • Java App      │    │ • 数据解析      │    │ • 高性能查询    │    │ • 报警配置      │
│ • 其他应用      │    │ • 数据过滤      │    │ • 数据压缩      │    │ • 仪表板        │
└─────────────────┘    └─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 一键部署

### 前置条件

- Linux系统 (CentOS 7+/Ubuntu 18+)
- Docker 20.0+
- Docker Compose 1.27+
- 至少2GB内存
- 至少10GB磁盘空间

### 快速部署步骤

```bash
# 1. 下载部署文件
git clone <repository> /data
cd /data

# 2. 设置权限
sudo chmod +x scripts/*.sh
sudo scripts/setup-permissions.sh

# 3. 启动所有服务
sudo scripts/start-all.sh

# 4. 验证部署
curl http://localhost:9428/health
curl http://localhost:3000/api/health
curl http://localhost:2020/
```

## 文件结构

```
/data/
├── README.md                           # 详细文档
├── DEPLOYMENT.md                       # 本文件
├── victorialogs/
│   └── docker-compose.yaml           # VictoriaLogs服务
├── fluentbit/
│   ├── docker-compose.yaml           # Fluent Bit服务
│   └── conf/
│       ├── fluent-bit.conf           # 主配置文件
│       ├── nginx-case.conf           # Nginx日志配置
│       └── java-case.conf            # Java日志配置
├── grafana/
│   ├── docker-compose.yaml           # Grafana服务
│   └── datasources/
│       └── victorialogs.yaml         # 数据源配置
├── cases/
│   ├── nginx-demo/                    # Nginx演示案例
│   └── java-demo/                     # Java演示案例
└── scripts/
    ├── setup-permissions.sh          # 权限设置脚本
    ├── start-all.sh                   # 一键启动脚本
    └── stop-all.sh                    # 一键停止脚本
```

## 服务端口

| 服务 | 端口 | 用途 |
|------|------|------|
| VictoriaLogs | 9428 | HTTP API接口 |
| Grafana | 3000 | Web界面 |
| Fluent Bit | 2020 | 监控和状态API |
| Fluent Bit | 24224 | Forward输入 |
| Fluent Bit | 5140 | Syslog输入 |
| Nginx Demo | 8080 | 演示应用 |
| Java Demo | 8090 | 演示应用 |

## 默认账号

| 服务 | 用户名 | 密码 |
|------|--------|------|
| Grafana | admin | admin123 |

## 案例使用

### Nginx日志收集案例

```bash
# 启动Nginx演示
cd /data/cases/nginx-demo
docker-compose up -d

# 访问应用生成日志
curl http://localhost:8080/
curl http://localhost:8080/api/users
curl http://localhost:8080/api/status

# 查看日志
tail -f /data/fluentbit/logs/nginx/access.log
```

### Java应用日志收集案例

```bash
# 启动Java演示
cd /data/cases/java-demo
docker-compose up -d

# 查看应用日志
tail -f /data/fluentbit/logs/java-app/application.log

# 查看GC日志
tail -f /data/fluentbit/logs/java-app/gc.log
```

## Grafana配置

### 1. 添加数据源

- 数据源类型: Loki
- URL: `http://victorialogs:9428`
- 访问模式: Server (default)

### 2. 基础查询语法

```bash
# 查看所有日志
{service="nginx"}

# 查看错误日志
{service="nginx"} |= "ERROR"

# 查看Java应用日志
{service="java-app"} |= "Exception"

# 时间范围查询
{service="nginx"} | time("5m")
```

### 3. 常用仪表板

创建以下仪表板：
- 系统日志概览
- Nginx访问统计
- Java应用监控
- 错误日志分析

## 维护操作

### 服务管理

```bash
# 查看服务状态
docker ps

# 查看服务日志
docker logs victorialogs
docker logs fluentbit
docker logs grafana

# 重启服务
docker-compose restart

# 停止所有服务
sudo /data/scripts/stop-all.sh
```

### 数据管理

```bash
# 查看存储使用
du -sh /data/victorialogs/victoria-logs-data
du -sh /data/grafana/grafana-data

# 清理日志数据 (谨慎操作)
sudo rm -rf /data/victorialogs/victoria-logs-data/*

# 备份配置
tar -czf vfg-config-backup.tar.gz /data
```

### 性能监控

```bash
# VictoriaLogs指标
curl http://localhost:9428/metrics

# Fluent Bit指标
curl http://localhost:2020/api/v1/metrics/prometheus

# Grafana健康检查
curl http://localhost:3000/api/health
```

## 故障排除

### 常见问题

1. **端口冲突**
   ```bash
   netstat -tlnp | grep :9428
   # 修改docker-compose.yaml中的端口映射
   ```

2. **权限问题**
   ```bash
   sudo /data/scripts/setup-permissions.sh
   ```

3. **磁盘空间不足**
   ```bash
   df -h /data
   # 清理日志或增加磁盘空间
   ```

4. **内存不足**
   ```bash
   free -h
   # 调整docker-compose.yaml中的内存限制
   ```

### 日志调试

```bash
# 查看Fluent Bit配置
docker exec fluentbit cat /fluent-bit/etc/fluent-bit.conf

# 测试VictoriaLogs连接
curl -X POST "http://localhost:9428/insert/jsonline" \
  -H "Content-Type: application/json" \
  -d '{"timestamp":"2024-01-01T00:00:00Z","message":"test log","level":"info"}'

# 查询测试日志
curl "http://localhost:9428/select/logsql/query" -d 'query=message:test'
```

### 网络诊断

```bash
# 检查Docker网络
docker network ls
docker network inspect vfg-network

# 测试容器间连通性
docker exec fluentbit ping victorialogs
docker exec grafana ping victorialogs
```

## 扩展配置

### 添加新的日志源

1. 修改 `/data/fluentbit/conf/fluent-bit.conf`
2. 添加新的 INPUT 配置
3. 配置相应的 FILTER 和 OUTPUT
4. 重启 Fluent Bit 服务

### 自定义Grafana仪表板

1. 访问 http://localhost:3000
2. 登录后创建新仪表板
3. 配置日志查询和可视化
4. 保存仪表板

### 添加告警规则

1. 在Grafana中配置告警规则
2. 设置通知渠道 (邮件、Webhook等)
3. 配置告警条件和阈值

## 生产环境建议

### 安全配置

- 修改默认密码
- 配置HTTPS访问
- 限制网络访问
- 定期更新镜像版本

### 性能优化

- 根据日志量调整VictoriaLogs内存配置
- 配置Fluent Bit缓冲区大小
- 设置日志轮转和保留策略
- 监控系统资源使用

### 高可用配置

- 配置VictoriaLogs集群
- 设置Grafana高可用
- 配置负载均衡
- 实施备份策略

## 联系支持

如遇到问题，请：
1. 查看服务日志
2. 检查配置文件
3. 运行诊断脚本
4. 提供详细错误信息

---

**部署完成后，请访问 http://localhost:3000 开始使用Grafana进行日志分析！** 