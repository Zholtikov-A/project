#!/bin/bash

set -eu -o pipefail

#Переменные должны совпадать с /etc/hosts
CURRENT_HOST=$(hostname)
PROXY="proxy"
BACKEND="backend-api"
REDIS="redis"
DB="postgres"

echo "Configuring STRICT firewall for: $CURRENT_HOST"

iptables -F
iptables -X
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP


iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

iptables -A INPUT -p tcp --dport 22 -j ACCEPT

case "$CURRENT_HOST" in
    "$PROXY")
        echo "Strict PROXY config..."
        # Вход снаружи на порт 5000
        iptables -A INPUT -p tcp --dport 5000 -j ACCEPT
        # Выход на Бэкенд и Редис
        iptables -A OUTPUT -p tcp -d "$BACKEND" --dport 8080 -j ACCEPT
        iptables -A OUTPUT -p tcp -d "$REDIS" --dport 6379 -j ACCEPT
        ;;

    "$BACKEND")
        echo "Strict BACKEND config..."
        # Вход только от Прокси на 8080
        iptables -A INPUT -p tcp -s "$PROXY" --dport 8080 -j ACCEPT
        # Выход только на Базу Данных
        iptables -A OUTPUT -p tcp -d "$DB" --dport 5432 -j ACCEPT
        ;;

    "$REDIS")
        echo "Strict REDIS config..."
        # Вход только от Прокси
        iptables -A INPUT -p tcp -s "$PROXY" --dport 6379 -j ACCEPT
        ;;

    "$DB")
        echo "Strict POSTGRES config..."
        # Вход только от Бэкенда
        iptables -A INPUT -p tcp -s "$BACKEND" --dport 5432 -j ACCEPT
        ;;

    *)
        echo "Unknown host. Only basic SSH/Lo rules applied."
        ;;
esac

# 6. Сохранение правил
if [ -f /etc/redhat-release ]; then
    iptables-save > /etc/sysconfig/iptables
else
    # Для Ubuntu требуется пакет iptables-persistent
    iptables-save > /etc/iptables/rules.v4
fi

echo "Security Lockdown Complete."
