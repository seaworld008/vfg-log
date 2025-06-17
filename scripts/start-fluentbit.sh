#!/bin/bash

# Fluent Bit 单独启动脚本

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 基础目录
BASE_DIR="/data"
FB_DIR="${BASE_DIR}/fluentbit"

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}Fluent Bit 启动脚本${NC}"
echo -e "${BLUE}================================${NC}"

# 检查Docker是否运行
if ! docker info >/dev/null 2>&1; then
    echo -e "${RED}错误: Docker未运行，请先启动Docker服务${NC}"
    exit 1
fi

# 检查docker-compose是否可用
if ! command -v docker-compose >/dev/null 2>&1; then
    echo -e "${RED}错误: docker-compose未安装${NC}"
    exit 1
fi

# 检查配置文件是否存在
if [ ! -f "${FB_DIR}/docker-compose.yaml" ]; then
    echo -e "${RED}错误: ${FB_DIR}/docker-compose.yaml 不存在${NC}"
    exit 1
fi

# 检查环境变量
VICTORIA_LOGS_HOST=${VICTORIA_LOGS_HOST:-127.0.0.1}
VICTORIA_LOGS_PORT=${VICTORIA_LOGS_PORT:-9428}

echo -e "${YELLOW}配置信息:${NC}"
echo -e "VictoriaLogs地址: ${BLUE}${VICTORIA_LOGS_HOST}:${VICTORIA_LOGS_PORT}${NC}"

# 提示如何设置环境变量
if [ "$VICTORIA_LOGS_HOST" = "127.0.0.1" ]; then
    echo -e "${YELLOW}注意: 使用默认的VictoriaLogs地址 127.0.0.1:9428${NC}"
    echo -e "${YELLOW}如需连接远程VictoriaLogs，请设置环境变量:${NC}"
    echo -e "${BLUE}export VICTORIA_LOGS_HOST=<VictoriaLogs服务器IP>${NC}"
    echo -e "${BLUE}export VICTORIA_LOGS_PORT=<VictoriaLogs端口，默认9428>${NC}"
    echo ""
fi

# 函数：检查服务健康状态
check_service_health() {
    local service_name="$1"
    local health_url="$2"
    local max_attempts=30
    local attempt=1
    
    echo -e "${YELLOW}等待 ${service_name} 健康检查...${NC}"
    
    while [ $attempt -le $max_attempts ]; do
        if curl -sf "$health_url" >/dev/null 2>&1; then
            echo -e "${GREEN}✅ ${service_name} 健康检查通过${NC}"
            return 0
        fi
        echo -n "."
        sleep 2
        ((attempt++))
    done
    
    echo -e "\n${RED}❌ ${service_name} 健康检查失败${NC}"
    return 1
}

# 测试VictoriaLogs连接
echo -e "${YELLOW}测试VictoriaLogs连接...${NC}"
if curl -sf "http://${VICTORIA_LOGS_HOST}:${VICTORIA_LOGS_PORT}/" >/dev/null 2>&1; then
    echo -e "${GREEN}✅ VictoriaLogs连接正常${NC}"
else
    echo -e "${RED}❌ 无法连接到VictoriaLogs: ${VICTORIA_LOGS_HOST}:${VICTORIA_LOGS_PORT}${NC}"
    echo -e "${YELLOW}请确保:${NC}"
    echo -e "1. VictoriaLogs服务已启动"
    echo -e "2. 网络连接正常"
    echo -e "3. 防火墙允许访问端口 ${VICTORIA_LOGS_PORT}"
    read -p "是否继续启动Fluent Bit? (y/n): " -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# 启动Fluent Bit
echo -e "\n${YELLOW}启动Fluent Bit...${NC}"
cd "${FB_DIR}"
docker-compose down 2>/dev/null || true

# 导出环境变量并启动
export VICTORIA_LOGS_HOST
export VICTORIA_LOGS_PORT
docker-compose up -d

# 健康检查
check_service_health "Fluent Bit" "http://localhost:2020/"

# 显示服务状态
echo -e "\n${BLUE}================================${NC}"
echo -e "${GREEN}Fluent Bit启动完成！${NC}"
echo -e "${BLUE}================================${NC}"

echo -e "\n${GREEN}服务状态:${NC}"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep fluentbit

echo -e "\n${GREEN}访问地址:${NC}"
echo -e "📋 Fluent Bit监控: ${BLUE}http://$(hostname -I | awk '{print $1}'):2020${NC}"
echo -e "📋 本地监控: ${BLUE}http://localhost:2020${NC}"

echo -e "\n${GREEN}日志输入端口:${NC}"
echo -e "📝 Forward输入: ${BLUE}$(hostname -I | awk '{print $1}'):24224${NC}"
echo -e "📝 Syslog输入: ${BLUE}$(hostname -I | awk '{print $1}'):5140${NC}"

echo -e "\n${GREEN}配置信息:${NC}"
echo -e "🎯 VictoriaLogs目标: ${BLUE}${VICTORIA_LOGS_HOST}:${VICTORIA_LOGS_PORT}${NC}"

echo -e "\n${GREEN}测试命令:${NC}"
echo -e "${BLUE}curl \"http://localhost:2020/\"${NC}"
echo -e "${BLUE}docker logs fluentbit${NC}"

echo -e "\n${GREEN}停止命令:${NC}"
echo -e "${BLUE}cd ${FB_DIR} && docker-compose down${NC}"

echo -e "\n${BLUE}================================${NC}"
echo -e "${GREEN}🎉 Fluent Bit启动完成！${NC}"
echo -e "${BLUE}================================${NC}" 