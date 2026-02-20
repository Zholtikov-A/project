#!/bin/bash

set -eu -o pipefail

# Массив данных: "IP ИМЯ"
HOSTS_LIST=(
"192.168.1.118 proxy"
"192.168.1.46 backend-api"
"192.168.1.117 redis"
"192.168.1.48 postgres"
)

echo "Updating /etc/hosts..."

for entry in "${HOSTS_LIST[@]}"; do
    IP=$(echo $entry | awk '{print $1}')
    NAME=$(echo $entry | awk '{print $2}')
    
    # Удаляем старые записи с таким именем, чтобы не дублировать
    sed -i "/$NAME/d" /etc/hosts
    
    # Добавляем новую запись
    echo "$IP $NAME" >> /etc/hosts
done

echo "Done! Check with: cat /etc/hosts"
