#!/bin/bash

# Script de despliegue automatizado para EC2
# Uso: ./deploy-to-ec2.sh EC2_IP KEY_FILE

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Strapi EC2 Deployment Script${NC}"
echo -e "${GREEN}================================${NC}\n"

# Verificar argumentos
if [ "$#" -ne 2 ]; then
    echo -e "${RED}Error: Se requieren 2 argumentos${NC}"
    echo "Uso: $0 <EC2_IP> <KEY_FILE>"
    echo "Ejemplo: $0 54.123.45.67 ~/keys/my-key.pem"
    exit 1
fi

EC2_IP=$1
KEY_FILE=$2

# Verificar que el archivo de key existe
if [ ! -f "$KEY_FILE" ]; then
    echo -e "${RED}Error: El archivo de key no existe: $KEY_FILE${NC}"
    exit 1
fi

echo -e "${YELLOW}Configuración:${NC}"
echo "  EC2 IP: $EC2_IP"
echo "  Key File: $KEY_FILE"
echo ""

# Crear archivo temporal con el proyecto
echo -e "${YELLOW}[1/6] Comprimiendo proyecto...${NC}"
TEMP_FILE="strapi-deploy-$(date +%s).tar.gz"
tar -czf "$TEMP_FILE" \
    my-strapi-project/ \
    docker-compose.postgres.yml \
    --exclude='my-strapi-project/node_modules' \
    --exclude='my-strapi-project/.tmp' \
    --exclude='my-strapi-project/dist' \
    --exclude='my-strapi-project/.cache'

echo -e "${GREEN}✓ Proyecto comprimido: $TEMP_FILE${NC}\n"

# Transferir archivo a EC2
echo -e "${YELLOW}[2/6] Transfiriendo archivos a EC2...${NC}"
scp -i "$KEY_FILE" -o StrictHostKeyChecking=no "$TEMP_FILE" ubuntu@"$EC2_IP":~/

echo -e "${GREEN}✓ Archivos transferidos${NC}\n"

# Ejecutar comandos en EC2
echo -e "${YELLOW}[3/6] Configurando instancia EC2...${NC}"
ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no ubuntu@"$EC2_IP" << 'ENDSSH'
set -e

echo "  → Descomprimiendo archivos..."
tar -xzf *.tar.gz

echo "  → Verificando Docker..."
if ! command -v docker &> /dev/null; then
    echo "  → Instalando Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker ubuntu
    rm get-docker.sh
fi

echo "  → Verificando Docker Compose..."
if ! docker compose version &> /dev/null; then
    echo "  → Instalando Docker Compose..."
    sudo apt update
    sudo apt install -y docker-compose-plugin
fi

echo "  → Limpiando archivo temporal..."
rm -f *.tar.gz

ENDSSH

echo -e "${GREEN}✓ Instancia EC2 configurada${NC}\n"

# Generar secrets de producción
echo -e "${YELLOW}[4/6] Generando secrets de producción...${NC}"

ssh -i "$KEY_FILE" ubuntu@"$EC2_IP" << 'ENDSSH'
set -e

cd ~/my-strapi-project

# Generar secrets si no existen
if [ ! -f .env.production ]; then
    echo "  → Generando nuevos secrets..."

    APP_KEY1=$(openssl rand -base64 32)
    APP_KEY2=$(openssl rand -base64 32)
    APP_KEY3=$(openssl rand -base64 32)
    APP_KEY4=$(openssl rand -base64 32)
    API_TOKEN_SALT=$(openssl rand -base64 32)
    ADMIN_JWT_SECRET=$(openssl rand -base64 32)
    TRANSFER_TOKEN_SALT=$(openssl rand -base64 32)
    ENCRYPTION_KEY=$(openssl rand -base64 32)
    JWT_SECRET=$(openssl rand -base64 32)
    DB_PASSWORD=$(openssl rand -base64 16)

    cat > .env.production << EOF
# Server
HOST=0.0.0.0
PORT=1337

# Secrets - Generados automáticamente
APP_KEYS=${APP_KEY1},${APP_KEY2},${APP_KEY3},${APP_KEY4}
API_TOKEN_SALT=${API_TOKEN_SALT}
ADMIN_JWT_SECRET=${ADMIN_JWT_SECRET}
TRANSFER_TOKEN_SALT=${TRANSFER_TOKEN_SALT}
ENCRYPTION_KEY=${ENCRYPTION_KEY}
JWT_SECRET=${JWT_SECRET}

# Database
DATABASE_CLIENT=postgres
DATABASE_HOST=postgres
DATABASE_PORT=5432
DATABASE_NAME=strapi
DATABASE_USERNAME=strapi
DATABASE_PASSWORD=${DB_PASSWORD}
DATABASE_SSL=false

# Environment
NODE_ENV=production
EOF

    # Copiar .env.production a .env
    cp .env.production .env

    echo ""
    echo "  ================================"
    echo "  IMPORTANTE: Secrets generados"
    echo "  ================================"
    echo "  Password de PostgreSQL: ${DB_PASSWORD}"
    echo "  Guarda esta información en un lugar seguro!"
    echo "  ================================"
    echo ""
else
    echo "  → .env.production ya existe, usando configuración existente"
fi

ENDSSH

echo -e "${GREEN}✓ Secrets configurados${NC}\n"

# Actualizar docker-compose con password
echo -e "${YELLOW}[5/6] Iniciando contenedores...${NC}"

ssh -i "$KEY_FILE" ubuntu@"$EC2_IP" << 'ENDSSH'
set -e

cd ~

# Detener contenedores existentes
if docker compose -f docker-compose.postgres.yml ps &> /dev/null; then
    echo "  → Deteniendo contenedores existentes..."
    docker compose -f docker-compose.postgres.yml down
fi

# Iniciar contenedores
echo "  → Iniciando contenedores..."
docker compose -f docker-compose.postgres.yml up -d

# Esperar a que PostgreSQL esté listo
echo "  → Esperando a PostgreSQL..."
sleep 10

# Verificar estado
echo "  → Verificando contenedores..."
docker compose -f docker-compose.postgres.yml ps

ENDSSH

echo -e "${GREEN}✓ Contenedores iniciados${NC}\n"

# Configurar Nginx (opcional)
echo -e "${YELLOW}[6/6] ¿Deseas configurar Nginx como reverse proxy? (y/n)${NC}"
read -r SETUP_NGINX

if [ "$SETUP_NGINX" = "y" ] || [ "$SETUP_NGINX" = "Y" ]; then
    echo -e "${YELLOW}  → Configurando Nginx...${NC}"

    ssh -i "$KEY_FILE" ubuntu@"$EC2_IP" << 'ENDSSH'
    set -e

    # Instalar Nginx
    if ! command -v nginx &> /dev/null; then
        echo "  → Instalando Nginx..."
        sudo apt update
        sudo apt install -y nginx
    fi

    # Crear configuración de Nginx
    sudo tee /etc/nginx/sites-available/strapi > /dev/null << 'EOF'
server {
    listen 80;
    server_name _;

    client_max_body_size 100M;

    location / {
        proxy_pass http://localhost:1337;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
EOF

    # Activar configuración
    sudo ln -sf /etc/nginx/sites-available/strapi /etc/nginx/sites-enabled/strapi
    sudo rm -f /etc/nginx/sites-enabled/default

    # Probar y reiniciar Nginx
    sudo nginx -t
    sudo systemctl restart nginx
    sudo systemctl enable nginx

    echo "  → Nginx configurado correctamente"
ENDSSH

    echo -e "${GREEN}✓ Nginx configurado${NC}\n"
fi

# Limpiar archivo temporal local
rm -f "$TEMP_FILE"

# Resumen final
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}¡Despliegue completado!${NC}"
echo -e "${GREEN}================================${NC}\n"

echo -e "${YELLOW}URLs de acceso:${NC}"
if [ "$SETUP_NGINX" = "y" ] || [ "$SETUP_NGINX" = "Y" ]; then
    echo "  → Aplicación: http://$EC2_IP"
    echo "  → Admin: http://$EC2_IP/admin"
else
    echo "  → Aplicación: http://$EC2_IP:1337"
    echo "  → Admin: http://$EC2_IP:1337/admin"
fi

echo -e "\n${YELLOW}Comandos útiles:${NC}"
echo "  → Ver logs: ssh -i $KEY_FILE ubuntu@$EC2_IP 'docker compose -f docker-compose.postgres.yml logs -f'"
echo "  → Reiniciar: ssh -i $KEY_FILE ubuntu@$EC2_IP 'docker compose -f docker-compose.postgres.yml restart'"
echo "  → Detener: ssh -i $KEY_FILE ubuntu@$EC2_IP 'docker compose -f docker-compose.postgres.yml down'"

echo -e "\n${YELLOW}Próximos pasos:${NC}"
echo "  1. Accede al admin panel y crea tu usuario administrador"
echo "  2. Configura SSL con Let's Encrypt si tienes un dominio"
echo "  3. Configura backups automáticos de la base de datos"

echo -e "\n${GREEN}¡Listo para usar!${NC}\n"
