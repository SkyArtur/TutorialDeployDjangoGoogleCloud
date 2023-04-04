#!/bin/bash/
###########################################################################################
#
# auto.sh - Script para deploy automatico.
#
# Autor: Artur dos Santos Shon (sky_artur@hotmail.com)
# Data de Criação: 02/04/2023
#
# Descrição: Script de instalação básica em uma VM, de um servidor Nginx para deploy de
# aplicações Django.
#
# Exemplo de uso: :bash ~/PASTA_RAIZ_PROJETO/deploy/auto.sh
#
# Observação:
#       Os comandos neste sprit podem ser digitados diretamente no terminal.
# Alterações:
#       04/04/2023 - inclusão de cabeçalho e comentários.
#
###########################################################################################

# exportando PATH do usuário
ip=$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip -H "Metadata-Flavor: Google")
export PATH="/home/$USER/.local/bin:$PATH"
cd ~ || exit

# Coletando dados para o banco de dados e arquivamento.
echo "Digite o nome do banco de dados que você configurou em settings.py:"
read -r banco_de_dados
echo "Digite o nome de usuário que você configurou em settings.py:"
read -r nome_usuario
echo "Digite a senha que você configurou em settings.py:"
read -r senha
echo "Digite o nome da pasta raiz do seu projeto:"
read -r projeto

# Realizando updates, atualizações e instalações importantes
sudo apt update && sudo apt upgrade && sudo apt autoremove
sudo apt install python3 python3-pip python3-venv python3-dev
sudo apt install postgresql postgresql-contrib libpq-dev git curl nginx

# Criando banco de dados da aplicação.
sudo -u postgres psql -c "CREATE DATABASE $banco_de_dados;"
sudo -u postgres psql -c "CREATE USER $nome_usuario WITH PASSWORD '$senha';"
sudo -u postgres psql -c "ALTER ROLE $nome_usuario SET client_encoding TO 'utf8';"
sudo -u postgres psql -c "ALTER ROLE $nome_usuario SET default_transaction_isolation TO 'read committed';"
sudo -u postgres psql -c "ALTER ROLE $nome_usuario SET timezone TO 'America/Sao_Paulo';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $banco_de_dados TO $nome_usuario;"
cd "$projeto" || exit

# Preparando o ambiente virtual da aplicação.
python3 -m venv venv
source venv/bin/activate
python3 -m pip install --upgrade pip wheel setuptools
pip install gunicorn pyscopg2
pip install django
pip install -r requirements.txt
python3 manage.py makemigrations
python3 manage.py migrate
python3 manage.py collectstatic
python3 manage.py createsuperuser
deactivate
cd ~ || exit

# movendo arquivos de configurações do servidor
sudo mv -f ~/"$projeto"/deploy/gunicorn.socket /etc/systemd/system
sudo mv -f ~/"$projeto"/deploy/gunicorn.service /etc/systemd/system
sudo mv -f ~/"$projeto"/deploy/site_django /etc/nginx/sites-available
sudo ln -s /etc/nginx/sites-available/site_django /etc/nginx/sites-enabled
sudo rm -rf /etc/nginx/sites-enabled/default

# iniciando serviços
sudo systemctl start gunicorn.socket
sudo systemctl enable gunicorn.socket
file /run/gunicorn.sock
sudo systemctl daemon-reload
sudo systemctl restart gunicorn
sudo systemctl restart nginx && sudo systemctl restart gunicorn
sudo ufw allow 'Nginx Full'
echo ------------------------------------------------------------------------------
echo Configurações finalizadas, sua aplicação deve estar disponível em HTTP://"$ip"
echo ------------------------------------------------------------------------------
echo