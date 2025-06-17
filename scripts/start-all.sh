#!/bin/bash

# VictoriaLogs + Fluent Bit + Grafana 一键启动脚本

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 基础目录
BASE_DIR="/data"
VL_DIR="${BASE_DIR}/victorialogs"
FB_DIR="${BASE_DIR}/fluentbit"
GF_DIR="${BASE_DIR}/grafana"

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}VFG日志收集系统一键启动脚本${NC}"
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

# 检查网络是否存在
if ! docker network ls | grep -q "vfg-network"; then
    echo -e "${YELLOW}创建Docker网络...${NC}"
    docker network create vfg-network
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
echo -e "\n${YELLOW}1. 启动VictoriaLogs...${NC}"
if [ -f "${VL_DIR}/docker-compose.yaml" ]; then
    cd "${VL_DIR}"
    docker-compose down 2>/dev/null || true
    docker-compose up -d
    check_service_health "VictoriaLogs" "http://localhost:9428/"
else
    echo -e "${RED}错误: ${VL_DIR}/docker-compose.yaml 不存在${NC}"
    exit 1
fi

# 启动Fluent Bit
echo -e "\n${YELLOW}2. 启动Fluent Bit...${NC}"
if [ -f "${FB_DIR}/docker-compose.yaml" ]; then
    cd "${FB_DIR}"
    docker-compose down 2>/dev/null || true
    docker-compose up -d
    check_service_health "Fluent Bit" "http://localhost:2020/"
else
    echo -e "${RED}错误: ${FB_DIR}/docker-compose.yaml 不存在${NC}"
    exit 1
fi

# 启动Grafana
echo -e "\n${YELLOW}3. 启动Grafana...${NC}"
if [ -f "${GF_DIR}/docker-compose.yaml" ]; then
    cd "${GF_DIR}"
    docker-compose down 2>/dev/null || true
    docker-compose up -d
    check_service_health "Grafana" "http://localhost:3000/api/health"
else
    echo -e "${RED}错误: ${GF_DIR}/docker-compose.yaml 不存在${NC}"
    exit 1
fi

# 显示服务状态
echo -e "\n${BLUE}================================${NC}"
echo -e "${GREEN}所有服务启动完成！${NC}"
echo -e "${BLUE}================================${NC}"

echo -e "\n${GREEN}服务状态:${NC}"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(victorialogs|fluentbit|grafana)"

echo -e "\n${GREEN}访问地址:${NC}"
echo -e "📊 VictoriaLogs API: ${BLUE}http://localhost:9428${NC}"
echo -e "📈 Grafana界面: ${BLUE}http://localhost:3000${NC} (admin/admin123)"
echo -e "📋 Fluent Bit监控: ${BLUE}http://localhost:2020${NC}"

# 提示自定义配置
echo -e "\n${YELLOW}注意事项:${NC}"
echo -e "• 如需添加自定义日志源，请参考 /data/cases/README.md"
echo -e "• 配置文件位于 /data/fluentbit/conf/"
echo -e "• 修改配置后需重启 Fluent Bit 服务"

echo -e "\n${GREEN}快速操作命令:${NC}"
echo -e "📄 查看日志: ${BLUE}docker logs <容器名>${NC}"
echo -e "🔄 重启服务: ${BLUE}docker-compose restart${NC}"
echo -e "⏹️  停止所有服务: ${BLUE}sudo ${BASE_DIR}/scripts/stop-all.sh${NC}"

echo -e "\n${GREEN}VictoriaLogs查询示例:${NC}"
echo -e "${BLUE}curl \"http://localhost:9428/select/logsql/query\" -d 'query=*'${NC}"
echo -e "${BLUE}curl \"http://localhost:9428/select/logsql/query\" -d 'query=service:nginx'${NC}"

echo -e "\n${GREEN}Grafana数据源配置:${NC}"
echo -e "数据源类型: Loki"
echo -e "URL: http://victorialogs:9428"

echo -e "\n${BLUE}================================${NC}"
echo -e "${GREEN}🎉 VFG日志收集系统启动完成！${NC}"
echo -e "${BLUE}================================${NC}" 