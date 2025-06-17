#!/bin/bash

# VictoriaLogs + Fluent Bit + Grafana 一键停止脚本

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
CASES_DIR="${BASE_DIR}/cases"

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}VFG日志收集系统一键停止脚本${NC}"
echo -e "${BLUE}================================${NC}"

# 停止自定义案例服务（如果有）
echo -e "\n${YELLOW}1. 检查自定义案例服务...${NC}"
if [ -d "${CASES_DIR}" ] && [ "$(ls -A ${CASES_DIR} 2>/dev/null)" ]; then
    echo -e "${YELLOW}发现自定义案例目录，请手动停止相关服务${NC}"
    ls -la "${CASES_DIR}/"
else
    echo -e "${GREEN}✅ 没有发现自定义案例服务${NC}"
fi

# 停止Grafana
echo -e "\n${YELLOW}2. 停止Grafana...${NC}"
if [ -f "${GF_DIR}/docker-compose.yaml" ]; then
    cd "${GF_DIR}"
    docker-compose down 2>/dev/null || true
    echo -e "${GREEN}✅ Grafana已停止${NC}"
else
    echo -e "${YELLOW}⚠️  Grafana配置文件不存在，跳过${NC}"
fi

# 停止Fluent Bit
echo -e "\n${YELLOW}3. 停止Fluent Bit...${NC}"
if [ -f "${FB_DIR}/docker-compose.yaml" ]; then
    cd "${FB_DIR}"
    docker-compose down 2>/dev/null || true
    echo -e "${GREEN}✅ Fluent Bit已停止${NC}"
else
    echo -e "${YELLOW}⚠️  Fluent Bit配置文件不存在，跳过${NC}"
fi

# 停止VictoriaLogs
echo -e "\n${YELLOW}4. 停止VictoriaLogs...${NC}"
if [ -f "${VL_DIR}/docker-compose.yaml" ]; then
    cd "${VL_DIR}"
    docker-compose down 2>/dev/null || true
    echo -e "${GREEN}✅ VictoriaLogs已停止${NC}"
else
    echo -e "${YELLOW}⚠️  VictoriaLogs配置文件不存在，跳过${NC}"
fi

# 清理孤立容器
echo -e "\n${YELLOW}5. 清理相关容器...${NC}"
CONTAINERS_TO_REMOVE=$(docker ps -a --filter "name=victorialogs" --filter "name=fluentbit" --filter "name=grafana" -q 2>/dev/null || true)

if [ -n "$CONTAINERS_TO_REMOVE" ]; then
    echo -e "${YELLOW}发现相关容器，正在清理...${NC}"
    docker rm -f $CONTAINERS_TO_REMOVE 2>/dev/null || true
    echo -e "${GREEN}✅ 容器清理完成${NC}"
else
    echo -e "${GREEN}✅ 没有需要清理的容器${NC}"
fi

# 清理未使用的网络
echo -e "\n${YELLOW}6. 清理网络...${NC}"
if docker network ls | grep -q "vfg-network"; then
    echo -e "${YELLOW}是否删除vfg-network网络? (y/n): ${NC}"
    read -r REMOVE_NETWORK
    if [[ $REMOVE_NETWORK =~ ^[Yy]$ ]]; then
        docker network rm vfg-network 2>/dev/null || true
        echo -e "${GREEN}✅ 网络已删除${NC}"
    else
        echo -e "${YELLOW}⚠️  保留vfg-network网络${NC}"
    fi
else
    echo -e "${GREEN}✅ vfg-network网络不存在${NC}"
fi

# 清理未使用的卷
echo -e "\n${YELLOW}7. 清理Docker卷...${NC}"
VOLUMES_TO_REMOVE=$(docker volume ls --filter "dangling=true" -q 2>/dev/null || true)
if [ -n "$VOLUMES_TO_REMOVE" ]; then
    echo -e "${YELLOW}是否清理未使用的Docker卷? (y/n): ${NC}"
    read -r REMOVE_VOLUMES
    if [[ $REMOVE_VOLUMES =~ ^[Yy]$ ]]; then
        docker volume rm $VOLUMES_TO_REMOVE 2>/dev/null || true
        echo -e "${GREEN}✅ 未使用的卷已清理${NC}"
    fi
else
    echo -e "${GREEN}✅ 没有未使用的卷需要清理${NC}"
fi

# 显示当前状态
echo -e "\n${BLUE}================================${NC}"
echo -e "${GREEN}停止操作完成！${NC}"
echo -e "${BLUE}================================${NC}"

echo -e "\n${GREEN}当前运行的相关容器:${NC}"
RUNNING_CONTAINERS=$(docker ps --filter "name=victorialogs" --filter "name=fluentbit" --filter "name=grafana" --format "{{.Names}}" 2>/dev/null || true)

if [ -n "$RUNNING_CONTAINERS" ]; then
    echo -e "${RED}⚠️  以下容器仍在运行:${NC}"
    echo "$RUNNING_CONTAINERS"
    echo -e "\n${YELLOW}如需强制停止，请运行:${NC}"
    echo -e "${BLUE}docker stop \$(docker ps -q --filter \"name=victorialogs\" --filter \"name=fluentbit\" --filter \"name=grafana\")${NC}"
else
    echo -e "${GREEN}✅ 所有相关容器已停止${NC}"
fi

echo -e "\n${GREEN}数据目录状态:${NC}"
echo -e "📁 VictoriaLogs数据: ${BASE_DIR}/victorialogs/victoria-logs-data"
echo -e "📁 Grafana数据: ${BASE_DIR}/grafana/grafana-data"
echo -e "📁 日志目录: ${BASE_DIR}/fluentbit/logs"

echo -e "\n${YELLOW}注意事项:${NC}"
echo -e "• 数据目录未被删除，重启服务时会保留历史数据"
echo -e "• 如需完全清理，请手动删除 ${BASE_DIR} 目录下的数据文件夹"
echo -e "• 重新启动服务: sudo ${BASE_DIR}/scripts/start-all.sh"

echo -e "\n${BLUE}================================${NC}"
echo -e "${GREEN}🛑 VFG日志收集系统已停止！${NC}"
echo -e "${BLUE}================================${NC}" 