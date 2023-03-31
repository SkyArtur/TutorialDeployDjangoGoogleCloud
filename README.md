## Inicializando uma VM

### Google Cloud

Faça sua inscrição na plataforma Google Cloud e ative o seu período de avaliação, preencha seus dados, entre na plataforma
e ative o serviço de instâncias VM seguindo até o menu 'hamburguer' no canto superior esquedo da página.

![iniciando-VM](https://user-images.githubusercontent.com/93395366/228640782-5cee4061-5e5f-450d-9b83-93c1271f5797.jpg)

Após a ativação do serviço, siga pelo mesmo caminho até `instâncias VM` e clique em `Criar instâcia`. 

![criando-vm](https://user-images.githubusercontent.com/93395366/228641616-658411f6-9819-4f10-8346-06acb9297ff2.jpg)

Há diversas configurações, mas vamos nos ater apenas ao necessário, deixando o restante para estudos posteriores, por isso, role a 
página até `Disco de inicialização` e clique em `Mudar`:

![image-so-disco](https://user-images.githubusercontent.com/93395366/228640912-bf0444ec-eed8-40b4-8cc5-479093a927c9.jpg)

Selecione o sistema operacional Ubuntu:

![image-so-selecao](https://user-images.githubusercontent.com/93395366/228641443-3f72a31c-6281-4f52-a17c-6a9fc7fa757a.jpg)

Escolha a versão 22.04 LTS e clieque em `Selecionar`.

:warning: Fique atento e selecione a arquitetura x86/64.

![image-so-versao](https://user-images.githubusercontent.com/93395366/228641469-9df8eb2e-0324-4ff6-9ba5-120ad454c9b2.jpg)

Marque as caixas de seleção para permitir coneção na porta :80(HTTP) e :443(HTTPS) e clique em `Criar`.

![image-so-criar](https://user-images.githubusercontent.com/93395366/228641659-b8e2337f-3604-45ce-8813-3de546d57205.jpg)

Na tela de Instâncias da VM, vá até a guia ``conectar``, que inclusve, está ao lado do IP externo da sua VM, e clique em ``SSH``.

![abrindo-ssh](https://user-images.githubusercontent.com/93395366/228711479-11f48e66-8292-4ece-ae54-1a5009105b9b.png)

Essa ação abrirá uma janela do seu navegador, onde uma conexão será realizada e você poderá acessar o terminal da sua
VM na Google Cloud. Você pode fechar esta janela por enquanto, pois abriremos ela novamente mais tarde.

Agora vamos voltar ao projeto Django e prepará-lo para o Deploy.

### Preparando o projeto

* Instalando WhiteNoise e gerenciando pacotes.

Instale o middleware WhiteNoise, para gerenciamento de arquivos estáticos pelo servidor, e o drive psycopg2, 
para o banco de dados PostgreSQL que usaremos no servidor.

````markdown
pip install whitenoise psycopg2
````

Gerencie os pacotes (Python) de seu projeto.

````markdown
pip freeze > requirements.txt
````

* Realizando alterações necessárias no arquivo settings.py do seu projeto.

Assegure-se de mudar a variável ``DEBUG`` para ``False``

```
DEBUG = False
```

Inclua em ``ALLOWED_HOSTS``  o ip externo de sua VM Google Cloud, você pode copiá-lo na mesma guia de ``Instâncias da VM``
onde realizamos a conexão com o servidor.

````markdown
ALLOWED_HOSTS = ['localhost', 'ip_google_cloud_aqui']
````

Edite a variável ``DATABASES`` para o seu novo banco de dados PostgreSQL. Realize as alterações necessárias em
``NAME``, ``USER`` e ``PASSWORD``, e guarde estas informações, pois, elas serão solicitadas mais adiante.

````
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql_psycopg2',
        'NAME': 'nome_do_banco_de_dados',
        'USER': 'nome_de_usuario',
        'PASSWORD': 'crie_uma_senha',
        'HOST': 'localhost',
        'PORT': '5432'
    }
}
````

Em ``MIDDLEWARE`` coloque o WhiteNoise logo após ``django.middleware.security.SecurityMiddleware``.
Não copie o código a seguir, ele apenas exemplifica a prosição em que o WitheNoise deve ficar entre os demais middlewares

````
MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'whitenoise.middleware.WhiteNoiseMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    '...',
    '...',
]
````

Coloque o código a seguir no corpo de seu arquivo settings.py logo acima da sua configuração de `STATIC_URL`.

```
STORAGES = {
    'staticfiles': {
        'BACKEND': 'whitenoise.storage.CompressedManifestStaticFilesStorage'
    }
}
```

Altere sua ``STATIC_ROOT`` para ``staticfiles``, não altere a ``STATIC_URL``.

```
STATIC_ROOT = BASE_DIR / 'staticfiles'
```

Para saber mais sobre o WhiteNoise confira a <a href="https://whitenoise.readthedocs.io/en/latest/django.html">documentação.</a>

* Arquivos necessários

Baixe este repósitorio e copie a pasta ``deploy`` para a pasta raiz do seu projeto django. Ela contém os arquivos
``gunicorn.socket`` e ``gunicorn.service``, que são configurações para o servidor wsgi Gunicorn, o arquivo ``site_django``,
que contém a configuração do servidor HTTP Nginx, e o arquivo ``auto.sh``', um shell script que realizara as instalações
e configurações basicas.

Você deve editar o arquivo ``gunicorn.service``, alterando ``NOME_USUARIO`` pelo nome do seu usuario na Google Cloud, 
``PASTA_RAIZ_PROJETO`` para o nome do diretório raiz da sua aplicação e ``PASTA_SETTINGS`` para o nome do diretório onde 
está o seu arquivo wsgi.py, o mesmo em que está o arquivo settings.py:

````markdown
[Unit]
Description=gunicorn daemon
Requires=gunicorn.socket
After=network.target

[Service]
User=NOME_USUARIO
Group=www-data
WorkingDirectory=/home/NOME_USUARIO/PASTA_RAIZ_PROJETO
ExecStart=/home/NOME_USUARIO/PASTA_RAIZ_PROJETO/venv/bin/gunicorn \
          --access-logfile - \
          --workers 3 \
          --bind unix:/run/gunicorn.sock \
          PASTA_SETTINGS.wsgi:application

[Install]
WantedBy=multi-user.target
````

:warning: Se você esqueceu ou não sabe o usuário da sua VM, inicie o terminal dela como mostrado anteriormente e 
digite o comando abaixo na linha de commando:

````markdown
echo $USER
````

Você também deve editar o arquivo ``site_django`` substituindo ``IP_VM_GOOGLE`` pelo ip externo de sua VM Google. 
 Não se esqueça de editar também ``NOME_USUARIO`` e ``PASTA_RAIZ_PROJETO``

````markdown
server {
    listen 80;
    server_name IP_VM_GOOGLE;

    location = /favicon.ico { access_log off; log_not_found off; }
    location /staticfiles/ {
        root /home/NOME_USUARIO/PASTA_RAIZ_PROJETO;
    }
    location /media {
        alias /home/NOME_USUARIO/PASTA_RAIZ_PROJETO/media/;
    }
    location / {
        include proxy_params;
        proxy_pass http://unix:/run/gunicorn.sock;
    }
}
````

Por fim, edite ou crie o seu arquivo ``.gitignore`` incluindo nele, a sua ``venv``, importante que você não leve
a ``venv`` do projeto para o repositório dele no GitHub, nem para o servidor, para não haver conflitos entre a versão 
do Pyhton no servidor e a que você tem instalada na sua `venv` ,por isso um novo ambiente virtual para a aplicação deve ser criado. 
A seguir, se já tiver criado um repositório no GitHub para a sua aplicação, realize os commites incluindo os arquivos 
que acabou de baixar e editar, realize o push das auterações. 
Caso contrário crie o repositório para prosseguirmos com os próximos passo.

### Retornado ao Google Cloud

Abra o terminal da sua VM no Google Cloud e clone o seu repositorio com o comando

````markdown
git clone URL_DO_REPOSITORIO
````
 
Em seguida digite:

````markdown
bash ~/PASTA_RAIZ_PROJETO/deploy/auto.sh
````
* Obsevações
  * Preencha corretamente os requisitos, confirme as alterações e aguarde o final do processo.
  * Se tudo ocorrer como planejado :pray:, sua aplicação estará disponivel na porta 80(HTTP).
