#!/bin/bash
# Объединённый скрипт для обновления системы, установки Ansible,
# обработки инвентарного файла, создания SSH ключевой пары и обновления known_hosts

set -e

##########################
# 1. Обновление системы   #
##########################
echo "Обновление списка пакетов..."
apt-get update

echo "Обновление установленных пакетов..."
apt-get upgrade -y

echo "Установка Ansible..."
apt-get install -y ansible

##########################################
# 2. Создание SSH ключевой пары и копирование публичного ключа
##########################################
KEY_PATH="/root/.ssh/id_rsa"
DEST_DIR="/root/ansible/first/files"

echo "Проверка наличия SSH ключевой пары..."
if [ ! -f "$KEY_PATH" ]; then
    echo "SSH ключевая пара не найдена. Генерирую новую пару..."
    ssh-keygen -t rsa -b 4096 -f "$KEY_PATH" -N ""
else
    echo "SSH ключевая пара уже существует."
fi

echo "Проверка существования директории назначения..."
if [ ! -d "$DEST_DIR" ]; then
    echo "Директория $DEST_DIR не существует. Создаю её..."
    mkdir -p "$DEST_DIR"
fi

echo "Копирую публичный ключ в $DEST_DIR..."
cp "${KEY_PATH}.pub" "$DEST_DIR"
echo "Публичный ключ скопирован в $DEST_DIR"

#################################################
# 3. Сканирование инвентарного файла и обновление known_hosts
#################################################
HOSTS_FILE="hosts"

echo "Убедимся, что директория ~/.ssh существует..."
mkdir -p ~/.ssh
touch ~/.ssh/known_hosts

echo "Сканирую файл $HOSTS_FILE для извлечения ansible_host IP..."
grep -oP 'ansible_host=\K\S+' "$HOSTS_FILE" | sort -u | while read ip; do
    echo "Сканирую $ip..."
    ssh-keyscan -H "$ip" >> ~/.ssh/known_hosts
done

echo "Сканирование завершено."
echo "Setup завершён успешно."

######################################
# 4. Обработка инвентарного файла     #
######################################
INPUT_FILE="hosts"
OUTPUT_DIR=".."
OUTPUT_FILE="${OUTPUT_DIR}/hosts"

echo "Обработка инвентарного файла..."
if [ ! -f "$INPUT_FILE" ]; then
    echo "Файл ${INPUT_FILE} не найден!"
    exit 1
fi

# Удаляем параметры ansible_user и ansible_password, оставляя только ansible_host
sed -E 's/ ansible_user=[^ ]+//g; s/ ansible_password=[^ ]+//g' "$INPUT_FILE" > "$OUTPUT_FILE"

echo "Инвентарный файл обновлен: $OUTPUT_FILE"


