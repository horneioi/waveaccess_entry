FROM ubuntu:22.04

# Установка зависимостей
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    python3-pip python3-venv python3-dev \
    git ssh openssh-client sshpass \
    curl sudo docker.io docker-compose \
    gnupg lsb-release software-properties-common \
    && rm -rf /var/lib/apt/lists/*

# Установка Ansible
RUN pip3 install --no-cache-dir ansible

# По умолчанию контейнер просто ждет
CMD ["sleep", "infinity"]