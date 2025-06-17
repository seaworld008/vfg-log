#!/bin/bash

# 动态生成Grafana数据源配置
# 使用环境变量 VICTORIA_LOGS_HOST 和 VICTORIA_LOGS_PORT

VICTORIA_LOGS_HOST=${VICTORIA_LOGS_HOST:-127.0.0.1}
VICTORIA_LOGS_PORT=${VICTORIA_LOGS_PORT:-9428}

cat > /data/grafana/datasources/victorialogs.yaml << EOF
apiVersion: 1

deleteDatasources:
  - name: VictoriaLogs
    orgId: 1

datasources:
  - name: VictoriaLogs
    type: prometheus
    uid: victorialogs
    access: proxy
    url: http://${VICTORIA_LOGS_HOST}:${VICTORIA_LOGS_PORT}/select/logsql
    isDefault: true
    editable: true
    orgId: 1
    version: 1
    jsonData:
      httpMethod: POST
      manageAlerts: true
      timeInterval: 30s
      queryTimeout: 60s
    secureJsonData: {}
    
  - name: VictoriaLogs-LogQL
    type: loki
    uid: victorialogs-logql
    access: proxy
    url: http://${VICTORIA_LOGS_HOST}:${VICTORIA_LOGS_PORT}
    isDefault: false
    editable: true
    orgId: 1
    version: 1
    jsonData:
      maxLines: 1000
      timeout: 60s
      httpHeaderName1: Content-Type
    secureJsonData:
      httpHeaderValue1: application/json
EOF

echo "Grafana数据源配置已生成: VictoriaLogs地址 ${VICTORIA_LOGS_HOST}:${VICTORIA_LOGS_PORT}" 