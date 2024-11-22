#!/bin/bash

# Verifica se o script está sendo executado como root
if [ "$EUID" -ne 0 ]
  then echo "Por favor, execute como root."
  exit
fi

# Verifica se os parâmetros foram fornecidos
if [ $# -ne 2 ]; then
    echo "Uso: $0 <IP_ANTIGO> <IP_NOVO>"
    exit 1
fi

IP_ANTIGO=$1
IP_NOVO=$2

# Adiciona a chave GPG do Wazuh
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import && chmod 644 /usr/share/keyrings/wazuh.gpg

# Adiciona o repositório do Wazuh
echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | tee /etc/apt/sources.list.d/wazuh.list

# Atualiza a lista de pacotes
apt-get update

# Instala ou atualiza o wazuh-agent
apt-get install -y wazuh-agent

# Comenta o repositório do Wazuh (opcional)
sed -i "s/^deb/#deb/" /etc/apt/sources.list.d/wazuh.list

# Atualiza a lista de pacotes novamente
apt-get update

# Caminho para o arquivo de configuração
CONFIG_FILE="/var/ossec/etc/ossec.conf"

# Faz backup do arquivo de configuração
cp $CONFIG_FILE ${CONFIG_FILE}.bak

# Verifica se o backup foi bem-sucedido
if [ $? -ne 0 ]; then
    echo "Erro ao fazer backup do arquivo de configuração."
    exit 1
fi

# Substitui o IP antigo pelo novo no arquivo de configuração
sed -i "s/<address>$IP_ANTIGO<\/address>/<address>$IP_NOVO<\/address>/g" $CONFIG_FILE

# Verifica se a substituição foi bem-sucedida
if [ $? -ne 0 ]; then
    echo "Erro ao atualizar o arquivo de configuração."
    exit 1
fi

# Reinicia o serviço do Wazuh Agent
systemctl restart wazuh-agent

# Verifica se o serviço foi reiniciado com sucesso
if [ $? -ne 0 ]; then
    echo "Erro ao reiniciar o serviço wazuh-agent."
    exit 1
fi

echo "Wazuh Agent atualizado e IP do Manager alterado com sucesso para $IP_NOVO."
