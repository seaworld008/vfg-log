#!/bin/bash

# VictoriaLogs 单独启动脚本

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 基础目录
BASE_DIR="/data"
VL_DIR="${BASE_DIR}/victorialogs"

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}VictoriaLogs 启动脚本${NC}"
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
if [ ! -f "${VL_DIR}/docker-compose.yaml" ]; then
    echo -e "${RED}错误: ${VL_DIR}/docker-compose.yaml 不存在${NC}"
    exit 1
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

# 启动VictoriaLogs
echo -e "\n${YELLOW}启动VictoriaLogs...${NC}"
cd "${VL_DIR}"
docker-compose down 2>/dev/null || true
docker-compose up -d

# 健康检查
check_service_health "VictoriaLogs" "http://localhost:9428/"

# 显示服务状态
echo -e "\n${BLUE}================================${NC}"
echo -e "${GREEN}VictoriaLogs启动完成！${NC}"
echo -e "${BLUE}================================${NC}"

echo -e "\n${GREEN}服务状态:${NC}"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep victorialogs

echo -e "\n${GREEN}访问地址:${NC}"
echo -e "📊 VictoriaLogs API: ${BLUE}http://$(hostname -I | awk '{print $1}'):9428${NC}"
echo -e "📊 本地访问: ${BLUE}http://localhost:9428${NC}"

echo -e "\n${GREEN}API测试命令:${NC}"
echo -e "${BLUE}curl \"http://localhost:9428/\" ${NC}"
echo -e "${BLUE}curl \"http://localhost:9428/select/logsql/query\" -d 'query=*'${NC}"

echo -e "\n${GREEN}停止命令:${NC}"
echo -e "${BLUE}cd ${VL_DIR} && docker-compose down${NC}"

echo -e "\n${BLUE}================================${NC}"
echo -e "${GREEN}🎉 VictoriaLogs启动完成！${NC}"
echo -e "${BLUE}================================${NC}" 