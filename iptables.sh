#!/bin/bash

CURRENT_HOST=$(hostname)

# Имена хостов
PROXY="proxy"
BACKEND="backend-api"
REDIS="redis"
DB="postgres"

# 1. Очистка и стандартные настройки (SSH, Loopback, Состояния)
iptables -F
iptables -X
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT # По умолчанию исходящие разрешены (стандартная настройка)

iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

case "$CURRENT_HOST" in
    "$PROXY")
        echo "Configuring PROXY..."
        # Принимает запросы ото всех на 5000
        iptables -A INPUT -p tcp --dport 5000 -j ACCEPT
        # Доступ к Redis и Backend разрешен, так как OUTPUT ACCEPT
        ;;

    "$BACKEND")
        echo "Configuring BACKEND..."
        # Принимает только от прокси на 8080
        iptables -A INPUT -p tcp -s "$PROXY" --dport 8080 -j ACCEPT
        
        # Специфическое ограничение: не имеет доступа к proxy и redis (инициация соединений)
        # Ответы на запросы прокси пройдут по правилу ESTABLISHED выше
        iptables -A OUTPUT -p tcp -d "$PROXY" -j REJECT
        iptables -A OUTPUT -p tcp -d "$REDIS" -j REJECT
        
        # Доступ к Postgres разрешен (OUTPUT ACCEPT по умолчанию)
        ;;

    "$REDIS")
        echo "Configuring REDIS..."
        # Принимает запросы только от PROXY (согласно логике задания)
        iptables -A INPUT -p tcp -s "$PROXY" --dport 6379 -j ACCEPT
        ;;

    "$DB")
        echo "Configuring DB..."
        # Принимает подключения только от Backend
        iptables -A INPUT -p tcp -s "$BACKEND" --dport 5432 -j ACCEPT
        ;;

    *)
        echo "Unknown hostname: $CURRENT_HOST"
        exit 1
        ;;
esac

# Сохранение
if [ -f /etc/redhat-release ]; then
    iptables-save > /etc/sysconfig/iptables
else
    iptables-save > /etc/iptables/rules.v4
fi