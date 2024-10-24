#!/bin/bash

logo=$(cat << 'EOF'
\033[32m
███╗   ██╗ ██████╗ ██████╗ ███████╗██████╗ ██╗   ██╗███╗   ██╗███╗   ██╗███████╗██████╗ 
████╗  ██║██╔═══██╗██╔══██╗██╔════╝██╔══██╗██║   ██║████╗  ██║████╗  ██║██╔════╝██╔══██╗
██╔██╗ ██║██║   ██║██║  ██║█████╗  ██████╔╝██║   ██║██╔██╗ ██║██╔██╗ ██║█████╗  ██████╔╝
██║╚██╗██║██║   ██║██║  ██║██╔══╝  ██╔══██╗██║   ██║██║╚██╗██║██║╚██╗██║██╔══╝  ██╔══██╗
██║ ╚████║╚██████╔╝██████╔╝███████╗██║  ██║╚██████╔╝██║ ╚████║██║ ╚████║███████╗██║  ██║
╚═╝  ╚═══╝ ╚═════╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝
\033[0m
Подписаться на канал may.crypto{🦅}, чтобы быть в курсе самых актуальных нод - https://t.me/maycrypto
EOF
)

echo -e "$logo"

echo "Обновляем и улучшаем пакеты..."
sudo apt update && sudo apt upgrade -y

echo "Устанавливаем необходимые пакеты..."
sudo apt install -y curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip

echo "Проверяем наличие Rust..."
install_rust() {
    echo "Устанавливаем или восстанавливаем Rust..."
    rustup self uninstall -y
    curl https://sh.rustup.rs -sSf | sh -s -- -y
    source $HOME/.cargo/env
    rustup update
}

if ! command -v rustc &> /dev/null; then
    install_rust
else
    echo "Rust уже установлен. Обновляем Rust..."
    rustup update || install_rust
fi

if rustc --version &> /dev/null; then
    echo "Rust успешно установлен и обновлен."
else
    echo "Ошибка установки Rust. Пытаемся установить заново."
    install_rust
fi

echo "Проверяем версию Rust..."
export PATH="$HOME/.cargo/bin:$PATH"
rustc --version

NEXUS_HOME=$HOME/.nexus

while [ -z "$NONINTERACTIVE" ]; do
    read -p "Вы соглашаетесь с условиями использования Beta Nexus (https://nexus.xyz/terms-of-use)? (Y/n) " yn </dev/tty
    case $yn in
        [Nn]* ) echo "Установка отменена."; exit;;
        [Yy]* ) break;;
        "" ) break;;
        * ) echo "Пожалуйста, ответьте да или нет.";;
    esac
done

echo "Проверяем наличие git..."
if ! command -v git &> /dev/null; then
    echo "Git не установлен. Пожалуйста, установите git и повторите попытку."
    exit 1
fi

echo "Настраиваем Nexus network-api..."
if [ -d "$NEXUS_HOME/network-api" ]; then
    echo "$NEXUS_HOME/network-api уже существует. Обновляем репозиторий."
    (cd $NEXUS_HOME/network-api && git pull)
else
    mkdir -p $NEXUS_HOME
    (cd $NEXUS_HOME && git clone https://github.com/nexus-xyz/network-api)
fi

echo "Запускаем Nexus Prover в screen-сессии..."
screen -S nexus -d -m bash -c "(cd $NEXUS_HOME/network-api/clients/cli && cargo run --release --bin prover -- beta.orchestrator.nexus.xyz; exec bash)"
