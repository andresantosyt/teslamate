#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

# Função para verificar se o sistema é Ubuntu 22
function verificar_ubuntu_22() {
  if [[ $(lsb_release -rs) != "22.04" ]]; then
    echo "Erro: Este script só funciona em sistemas Ubuntu 22.04."
    exit 1
  fi
}

# Função para instalar o Docker
function instalar_docker() {

  echo "--> Remover pacotes que podem causar conflitos"
  for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get -y remove $pkg; done

  echo "--> Adicionar repositoris oficiais do Docker"
  sudo apt-get update
  sudo apt-get -y install ca-certificates curl
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc

  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get update

  echo "--> Instalar a ultima versão do Docker e docker compose"
  sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  echo "--> A Iniciar o Docker"
  sudo systemctl enable docker
  sudo systemctl start docker

  echo "--> Verificar se o Docker foi instalado..."
  if ! command -v docker > /dev/null; then
    echo "Erro: Falha ao instalar o Docker."
    exit 1
  fi

  echo "--> Docker instalado com sucesso!"
}

# Função para criar o utilizador "teslamate"
function criar_utilizador_teslamate() {
  echo "--> Criando o utilizador 'teslamate'..."
  sudo adduser --system --shell /bin/bash teslamate

  echo "--> Adicionando o utilizador 'teslamate' ao grupo 'docker'..."
  sudo usermod -aG docker teslamate

  echo "--> Utilizador 'teslamate' criado com sucesso!"
}

# Função para criar o docker compose
function criar_docker_compose() {
  local teslamate_home="/home/teslamate"

  # Criar pasta do docker-compose
  if [[ ! -d "$teslamate_home/docker-compose" ]]; then
    sudo mkdir -p "$teslamate_home/docker-compose"
  fi

  # Criar ficheiro docker-compose.yml
  sudo  cp ./docker-compose.yml "$teslamate_home/docker-compose/"

  # Fix das permissões
  sudo chown -R teslamate "$teslamate_home/docker-compose/"

  echo "Pasta e ficheiro do docker-compose criados com sucesso!!!"
}
# Função para iniciar o tesla mate
function iniciar_tesla_mate() {
  local teslamate_home="/home/teslamate"

  echo "--> A iniciar o TeslaMate..."
  sudo -u teslamate bash -c "cd $teslamate_home/docker-compose && docker compose up -d"

  echo "--> Verificando o status do TeslaMate..."
  sudo -u teslamate bash -c "cd $teslamate_home/docker-compose && docker compose ls"
}

# Chamada das funções
verificar_ubuntu_22
instalar_docker
criar_utilizador_teslamate
criar_docker_compose
iniciar_tesla_mate

echo "Script finalizado"

