#!/bin/bash/
export PATH="/home/$USER/.local/bin:$PATH"
cd ~ || exit
echo "Digite o nome do banco de dados que você configurou em settings.py:"
read -r banco_de_dados
echo "Digite o nome de usuário que você configurou em settings.py:"
read -r nome_usuario
echo "Digite a senha que você configurou em settings.py:"
read -r senha
echo "Digite o nome da pasta raiz do seu projeto:"
read -r projeto
sudo apt update && sudo apt upgrade && sudo apt autoremove
sudo apt install python3 python3-pip python3-venv python3-dev
sudo apt install postgresql postgresql-contrib libpq-dev git curl nginx
sudo -u postgres psql -c "CREATE DATABASE $banco_de_dados;"
sudo -u postgres psql -c "CREATE USER $nome_usuario WITH PASSWORD '$senha';"
sudo -u postgres psql -c "ALTER ROLE $nome_usuario SET client_encoding TO 'utf8';"
sudo -u postgres psql -c "ALTER ROLE $nome_usuario SET default_transaction_isolation TO 'read committed';"
sudo -u postgres psql -c "ALTER ROLE $nome_usuario SET timezone TO 'America/Sao_Paulo';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $banco_de_dados TO $nome_usuario;"
cd "$projeto" || exit
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
sudo mv -f ~/"$projeto"/deploy/gunicorn.socket /etc/systemd/system
sudo mv -f ~/"$projeto"/deploy/gunicorn.service /etc/systemd/system
sudo mv -f ~/"$projeto"/deploy/site_django /etc/nginx/sites-available
sudo ln -s /etc/nginx/sites-available/site_django /etc/nginx/sites-enabled
sudo systemctl start gunicorn.socket
sudo systemctl enable gunicorn.socket
file /run/gunicorn.sock
sudo systemctl daemon-reload
sudo systemctl restart gunicorn
sudo systemctl restart nginx && sudo systemctl restart gunicorn
sudo ufw allow 'Nginx Full'