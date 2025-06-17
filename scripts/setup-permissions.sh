#!/bin/bash

# VictoriaLogs + Fluent Bit + Grafana 权限设置脚本
# 用于设置目录权限和解决Docker容器权限问题

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}开始设置VFG日志收集系统权限...${NC}"

# 检查是否为root用户
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}请使用root权限运行此脚本: sudo $0${NC}"
    exit 1
fi

# 创建用户和组（如果不存在）
if ! id -u 472 >/dev/null 2>&1; then
    useradd -r -u 472 -g root -s /bin/false grafana || true
fi

# 基础目录
BASE_DIR="/data"
VL_DIR="${BASE_DIR}/victorialogs"
FB_DIR="${BASE_DIR}/fluentbit"
GF_DIR="${BASE_DIR}/grafana"
CASES_DIR="${BASE_DIR}/cases"
SCRIPTS_DIR="${BASE_DIR}/scripts"

echo -e "${YELLOW}创建目录结构...${NC}"

# 创建主要目录
mkdir -p "${VL_DIR}/victoria-logs-data"
mkdir -p "${FB_DIR}/conf"
mkdir -p "${FB_DIR}/logs"
mkdir -p "${GF_DIR}/grafana-data"
mkdir -p "${GF_DIR}/dashboards"
mkdir -p "${GF_DIR}/datasources"
mkdir -p "${SCRIPTS_DIR}"

# VictoriaLogs权限设置
echo -e "${YELLOW}设置VictoriaLogs权限...${NC}"
chown -R 1000:1000 "${VL_DIR}/victoria-logs-data"
chmod -R 755 "${VL_DIR}/victoria-logs-data"

# Fluent Bit权限设置
echo -e "${YELLOW}设置Fluent Bit权限...${NC}"
chown -R root:root "${FB_DIR}/logs"
chmod -R 755 "${FB_DIR}/logs"
chmod -R 644 "${FB_DIR}/conf"

# Grafana权限设置 (Grafana容器使用uid=472)
echo -e "${YELLOW}设置Grafana权限...${NC}"
chown -R 472:472 "${GF_DIR}/grafana-data"
chmod -R 755 "${GF_DIR}/grafana-data"
chmod -R 644 "${GF_DIR}/dashboards"
chmod -R 644 "${GF_DIR}/datasources"

# 创建案例目录（可选）
echo -e "${YELLOW}创建案例目录（可选）...${NC}"
mkdir -p "${CASES_DIR}"
chown -R root:root "${CASES_DIR}"
chmod -R 755 "${CASES_DIR}"

# 脚本权限设置
echo -e "${YELLOW}设置脚本执行权限...${NC}"
chmod +x "${SCRIPTS_DIR}"/*.sh

# Docker网络创建
echo -e "${YELLOW}创建Docker网络...${NC}"
if ! docker network ls | grep -q "vfg-network"; then
    docker network create vfg-network
    echo -e "${GREEN}创建网络 vfg-network 成功${NC}"
else
    echo -e "${GREEN}网络 vfg-network 已存在${NC}"
fi

# 创建示例配置模板
echo -e "${YELLOW}创建配置模板...${NC}"
cat > "${CASES_DIR}/README.md" << 'EOF'
# 自定义案例目录

这个目录用于存放您的自定义日志收集案例配置。

## 添加新的日志源

1. 在 /data/fluentbit/conf/ 目录下创建新的配置文件
2. 在 fluent-bit.conf 中使用 @INCLUDE 引入新配置
3. 重启 Fluent Bit 服务

## 示例配置模板

参考 /data/fluentbit/conf/fluent-bit.conf 中的配置格式
EOF

# 设置SELinux上下文 (如果启用了SELinux)
if command -v getenforce >/dev/null 2>&1 && [ "$(getenforce)" != "Disabled" ]; then
    echo -e "${YELLOW}设置SELinux上下文...${NC}"
    setsebool -P container_manage_cgroup true
    chcon -Rt svirt_sandbox_file_t "${BASE_DIR}"
fi

# 检查磁盘空间
AVAILABLE_SPACE=$(df "${BASE_DIR}" | awk 'NR==2 {print $4}')
REQUIRED_SPACE=1048576  # 1GB in KB

if [ "${AVAILABLE_SPACE}" -lt "${REQUIRED_SPACE}" ]; then
    echo -e "${YELLOW}警告: ${BASE_DIR} 可用空间不足1GB，建议清理磁盘空间${NC}"
fi

# 检查内存
TOTAL_MEM=$(free -m | awk 'NR==2{print $2}')
if [ "${TOTAL_MEM}" -lt 2048 ]; then
    echo -e "${YELLOW}警告: 系统内存少于2GB，可能影响服务性能${NC}"
fi

# 输出配置信息
echo -e "${GREEN}权限设置完成！${NC}"
echo -e "${GREEN}目录结构:${NC}"
echo "  VictoriaLogs数据: ${VL_DIR}/victoria-logs-data"
echo "  Fluent Bit配置: ${FB_DIR}/conf"
echo "  Fluent Bit日志: ${FB_DIR}/logs"
echo "  Grafana数据: ${GF_DIR}/grafana-data"
echo "  案例目录: ${CASES_DIR}"

echo -e "\n${GREEN}下一步操作:${NC}"
echo "1. 启动所有服务: sudo ${SCRIPTS_DIR}/start-all.sh"
echo "2. 或单独启动各组件:"
echo "   cd ${VL_DIR} && docker-compose up -d"
echo "   cd ${FB_DIR} && docker-compose up -d"
echo "   cd ${GF_DIR} && docker-compose up -d"

echo -e "\n${GREEN}访问地址:${NC}"
echo "- VictoriaLogs: http://localhost:9428"
echo "- Grafana: http://localhost:3000 (admin/admin123)"
echo "- Fluent Bit监控: http://localhost:2020"

echo -e "\n${GREEN}权限设置脚本执行完成！${NC}" 