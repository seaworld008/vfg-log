# 一个基于VictoriaLogs + Fluent Bit + Grafana 的高新能日志收集系统 VFG-LOG

## 系统架构

```
应用服务 → Fluent Bit → VictoriaLogs → Grafana
```

- **VictoriaLogs**: 高性能日志存储数据库
- **Fluent Bit**: 轻量级日志收集器
- **Grafana**: 日志可视化和查询界面

## 目录结构

```
项目根目录/
├── README.md                              # 项目说明文档
├── DEPLOYMENT.md                          # 详细部署指南
├── victorialogs/
│   └── docker-compose.yaml               # VictoriaLogs服务配置
├── fluentbit/
│   ├── docker-compose.yaml               # Fluent Bit服务配置
│   └── conf/
│       ├── fluent-bit.conf               # 主配置文件
│       ├── custom-logs.conf              # 通用日志收集模板
│       ├── nginx-logs-template.conf      # Nginx日志收集模板
│       └── java-logs-template.conf       # Java日志收集模板
├── grafana/
│   ├── docker-compose.yaml               # Grafana服务配置
│   ├── generate-datasource.sh            # 动态生成数据源配置
│   └── dashboards/
│       └── dashboard.yaml                # Dashboard自动发现配置
└── scripts/
    ├── setup-permissions.sh              # 权限设置脚本
    ├── start-all.sh                      # 启动所有服务
    ├── stop-all.sh                       # 停止所有服务
    ├── start-victorialogs.sh             # 单独启动VictoriaLogs
    ├── start-fluentbit.sh                # 单独启动Fluent Bit
    └── start-grafana.sh                  # 单独启动Grafana
```

## 🚀 快速部署

### 1. 准备环境

```bash
# 克隆项目
git clone <your-repo-url>
cd victorialogs-fluentbit-grafana

# 设置权限
chmod +x scripts/*.sh
./scripts/setup-permissions.sh
```

### 2. 启动服务

```bash
# 方式1: 一键启动所有服务
./scripts/start-all.sh

# 方式2: 单独启动各组件
./scripts/start-victorialogs.sh
./scripts/start-fluentbit.sh
./scripts/start-grafana.sh

# 方式3: 使用docker-compose（支持跨机器部署）
# 设置环境变量（可选，默认127.0.0.1:9428）
export VICTORIA_LOGS_HOST=192.168.1.100
export VICTORIA_LOGS_PORT=9428

cd victorialogs && docker-compose up -d
cd ../fluentbit && docker-compose up -d
cd ../grafana && docker-compose up -d
```

## ⚙️ 配置示例

项目提供了完整的VictoriaLogs日志收集配置模板，支持多种认证方式和部署场景：

### 🌐 Nginx日志收集配置

查看文件：`fluentbit/conf/nginx-logs-template.conf`

#### 基础配置（默认启用）
```yaml
[OUTPUT]
    Name              http
    Host              192.168.1.100          # 你的VictoriaLogs服务器IP
    Port              9428                    # VictoriaLogs端口
    Header            Authorization Basic dXNlcjpwYXNzd29yZA==
    # 将 dXNlcjpwYXNzd29yZA== 替换为你的用户名:密码的Base64编码
```

#### 高级配置选项（注释状态，按需启用）
- **HTTPS + 基础认证**：支持SSL/TLS加密连接
- **多租户配置**：AccountID、ProjectID、自定义租户标签
- **Bearer Token认证**：JWT Token企业级认证
- **API Key认证**：简单的API密钥认证

### ☕ Java应用日志收集配置  

查看文件：`fluentbit/conf/java-logs-template.conf`

#### 基础配置（默认启用）
```yaml
[OUTPUT]
    Name              http
    Host              192.168.1.100          # 你的VictoriaLogs服务器IP
    Port              9428                    # VictoriaLogs端口
    Header            Authorization Basic dXNlcjpwYXNzd29yZA==
    # 将 dXNlcjpwYXNzd29yZA== 替换为你的用户名:密码的Base64编码
```

#### 高级配置选项（注释状态，按需启用）
- **HTTPS + SSL证书认证**：双向SSL认证
- **多租户 + 服务标识**：细粒度的租户和服务管理
- **企业版JWT认证**：组织级别的权限控制
- **云服务商认证**：AWS/GCP/Azure等云平台IAM认证
- **API Key + 多环境**：开发/测试/生产环境隔离

### 🔐 认证配置指南

#### 1. Basic认证（用户名密码）
```bash
# 生成用户名密码的Base64编码
echo -n 'your_username:your_password' | base64

# 例如用户名admin，密码123456
echo -n 'admin:123456' | base64
# 输出: YWRtaW46MTIzNDU2
```

#### 2. HTTPS配置
```yaml
tls               on          # 启用TLS
tls.verify        on          # 验证服务器证书
tls.ca_file       /path/to/ca.crt      # CA证书（可选）
tls.crt_file      /path/to/client.crt  # 客户端证书（可选）
tls.key_file      /path/to/client.key  # 客户端私钥（可选）
```

#### 3. 多租户配置
```yaml
Header            AccountID 1
Header            ProjectID 0
Header            X-Tenant production
Header            X-Environment prod
```

#### 4. JWT Token认证
```yaml
Header            Authorization Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### 📝 使用方法

1. **选择配置类型**：根据你的VictoriaLogs部署方式选择对应配置
2. **取消注释**：将需要的配置块取消注释（删除开头的#）
3. **修改参数**：替换IP地址、认证信息、租户ID等
4. **应用配置**：复制到主配置文件或重启Fluent Bit

#### 快速配置命令

```bash
# 复制nginx配置模板
cat fluentbit/conf/nginx-logs-template.conf >> fluentbit/conf/fluent-bit.conf

# 复制java配置模板
cat fluentbit/conf/java-logs-template.conf >> fluentbit/conf/fluent-bit.conf

# 编辑配置文件，取消注释需要的部分
vim fluentbit/conf/fluent-bit.conf

# 重启Fluent Bit应用配置
./scripts/start-fluentbit.sh
```

## 自定义配置

### 使用日志收集模板

项目提供了专用的日志收集模板，可直接复制使用：

#### 1. Nginx日志收集
```bash
# 复制nginx模板内容到主配置文件
cat fluentbit/conf/nginx-logs-template.conf >> fluentbit/conf/fluent-bit.conf

# 或者编辑配置文件，取消注释相关配置
vim fluentbit/conf/nginx-logs-template.conf
```

#### 2. Java应用日志收集
```bash
# 复制java模板内容到主配置文件
cat fluentbit/conf/java-logs-template.conf >> fluentbit/conf/fluent-bit.conf

# 或者编辑配置文件，取消注释相关配置
vim fluentbit/conf/java-logs-template.conf
```

#### 3. 自定义日志收集
参考 `fluentbit/conf/custom-logs.conf` 中的通用示例配置

### 添加新的日志源

1. 在 `fluentbit/conf/` 目录下创建新的配置文件
2. 在 `fluent-bit.conf` 中使用 `@INCLUDE` 引入新配置
3. 重启 Fluent Bit 服务：`./scripts/start-fluentbit.sh`

## 配置说明

### VictoriaLogs配置

- 数据保留期: 180天
- HTTP监听端口: 9428
- 数据存储路径: /victoria-logs-data

### Fluent Bit配置

- HTTP监听端口: 2020
- 输入: 文件和TCP
- 输出: VictoriaLogs
- 缓冲: 内存模式

### Grafana配置

- 默认用户: admin/admin
- 数据源: VictoriaLogs
- 端口: 3000

## 日志查询

### VictoriaLogs查询语法

```bash
# 基本查询
curl "http://localhost:9428/select/logsql/query" -d 'query=*'

# 按服务过滤
curl "http://localhost:9428/select/logsql/query" -d 'query=service:nginx'

# 时间范围查询
curl "http://localhost:9428/select/logsql/query" -d 'query=* | time:5m'
```

### Grafana查询

在Grafana中使用LogQL语法查询日志：

```
# 查看所有日志
{service="*"}

# 查看错误日志  
{level="ERROR"}

# 按时间范围查询
{service="*"} | time("5m")
```

## 故障排除

### 常见问题

1. **权限问题**
   ```bash
   ./scripts/setup-permissions.sh
   ```

2. **端口冲突**
   - 检查端口占用: `netstat -tlnp | grep :9428`
   - 修改docker-compose.yaml中的端口映射

3. **日志不显示**
   - 检查Fluent Bit状态: `docker logs fluentbit`
   - 验证日志路径挂载是否正确
   - 查看模板配置是否正确启用

4. **VictoriaLogs连接失败**
   - 检查网络: `docker network ls`
   - 确认VictoriaLogs服务正常: `curl http://localhost:9428/health`
   - 跨机器部署时检查环境变量: `echo $VICTORIA_LOGS_HOST`

5. **模板配置不生效**
   - 确认配置文件中已取消注释
   - 检查日志文件路径是否存在
   - 重启Fluent Bit服务

### 日志调试

```bash
# 查看各组件日志
docker logs victorialogs
docker logs fluentbit  
docker logs grafana

# 检查Fluent Bit配置
docker exec fluentbit cat /fluent-bit/etc/fluent-bit.conf
```

## 跨机器部署

项目支持组件部署在不同机器上，通过环境变量配置：

```bash
# 在Fluent Bit和Grafana机器上设置VictoriaLogs地址
export VICTORIA_LOGS_HOST=192.168.1.100  # VictoriaLogs服务器IP
export VICTORIA_LOGS_PORT=9428           # VictoriaLogs端口

# 启动服务
./scripts/start-fluentbit.sh
./scripts/start-grafana.sh
```

## 配置模板说明

- **nginx-logs-template.conf**: 包含访问日志、错误日志收集，状态码分类，健康检查过滤
- **java-logs-template.conf**: 支持应用日志、GC日志、TCP输入，异常提取，多行解析
- **custom-logs.conf**: 通用日志收集示例，可根据需求自定义

## 性能调优

### VictoriaLogs优化

- 增加内存限制: `--memory.allowedPercent=80`
- 调整并发数: `--search.maxConcurrentRequests=8`

### Fluent Bit优化  

- 调整缓冲区大小: `Mem_Buf_Limit 10MB`
- 设置刷新间隔: `Flush 5`

## 监控指标

- VictoriaLogs写入速率
- Fluent Bit处理延迟
- 磁盘空间使用率
- 内存使用情况

---

> 📖 更多详细信息请参阅 [DEPLOYMENT.md](DEPLOYMENT.md) 
