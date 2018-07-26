# imagem - ultima versao estavel do debian
FROM debian:latest

# mantenedor da imagem
MAINTAINER caio abreu ferreira - abreuferr@gmail.com

# Atualizar o repositorio e atualizar a distribuicao
RUN apt-get update && \
    apt-get upgrade -y

# Instalacao do nginx
RUN apt-get install -y nginx -y &&  \
    rm -rf /var/lib/apt/lists/*

# copiar o arquivo index.html do host para a imagem
RUN rm /usr/share/nginx/html/index.html
COPY index.html /usr/share/nginx/html/

# expor a porta 80 do container
EXPOSE 80

# inicializar o nginx no container
CMD ["nginx", "-g", "daemon off;"]
