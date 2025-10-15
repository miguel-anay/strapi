#!/bin/bash

# Script simple para transferir proyecto a EC2
# Uso: ./transfer-to-ec2.sh

# ============================================
# CONFIGURACIÓN - EDITA ESTOS VALORES
# ============================================
EC2_IP="54.123.45.67"                    # Cambia por la IP de tu EC2
KEY_FILE="$HOME/keys/my-key.pem"         # Cambia por la ruta a tu archivo .pem

# ============================================
# NO EDITES DEBAJO DE ESTA LÍNEA
# ============================================

set -e

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Transfer Strapi to EC2${NC}"
echo -e "${GREEN}================================${NC}\n"

# Verificar que existe el archivo de key
if [ ! -f "$KEY_FILE" ]; then
    echo -e "${RED}Error: No se encuentra el archivo de key: $KEY_FILE${NC}"
    echo "Por favor edita este script y configura la ruta correcta."
    exit 1
fi

# Verificar conectividad
echo -e "${YELLOW}[1/4] Verificando conexión a EC2...${NC}"
if ! ssh -i "$KEY_FILE" -o ConnectTimeout=5 -o StrictHostKeyChecking=no ubuntu@"$EC2_IP" "echo 'OK'" &> /dev/null; then
    echo -e "${RED}Error: No se puede conectar a $EC2_IP${NC}"
    echo "Verifica:"
    echo "  - La IP es correcta"
    echo "  - El Security Group permite SSH desde tu IP"
    echo "  - El archivo .pem tiene los permisos correctos (chmod 400)"
    exit 1
fi
echo -e "${GREEN}✓ Conexión exitosa${NC}\n"

# Limpiar archivos locales
echo -e "${YELLOW}[2/4] Limpiando archivos innecesarios...${NC}"
cd my-strapi-project
rm -rf node_modules dist .tmp .cache 2>/dev/null || true
cd ..
echo -e "${GREEN}✓ Archivos limpiados${NC}\n"

# Transferir archivos
echo -e "${YELLOW}[3/4] Transfiriendo archivos a EC2...${NC}"
echo "  → Transfiriendo my-strapi-project/"
scp -i "$KEY_FILE" -r -o StrictHostKeyChecking=no my-strapi-project ubuntu@"$EC2_IP":~/

echo "  → Transfiriendo docker-compose.postgres.yml"
scp -i "$KEY_FILE" -o StrictHostKeyChecking=no docker-compose.postgres.yml ubuntu@"$EC2_IP":~/

echo -e "${GREEN}✓ Archivos transferidos${NC}\n"

# Configurar y ejecutar en EC2
echo -e "${YELLOW}[4/4] Configurando en EC2...${NC}"

ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no ubuntu@"$EC2_IP" << 'ENDSSH'
set -e

cd ~/my-strapi-project

# Verificar si existe .env
if [ ! -f .env ]; then
    echo "  → Creando archivo .env desde .env.example"
    if [ -f .env.example ]; then
        cp .env.example .env
    else
        echo "  ⚠ No existe .env.example, creando .env básico"
        cat > .env << 'EOF'
HOST=0.0.0.0
PORT=1337
NODE_ENV=production

# IMPORTANTE: Cambia estos valores en producción
APP_KEYS=key1,key2,key3,key4
API_TOKEN_SALT=salt1
ADMIN_JWT_SECRET=secret1
TRANSFER_TOKEN_SALT=salt2
ENCRYPTION_KEY=key5
JWT_SECRET=secret2

DATABASE_CLIENT=postgres
DATABASE_HOST=postgres
DATABASE_PORT=5432
DATABASE_NAME=strapi
DATABASE_USERNAME=strapi
DATABASE_PASSWORD=strapi_password
DATABASE_SSL=false
EOF
    fi

    echo ""
    echo "  ================================"
    echo "  ⚠  IMPORTANTE"
    echo "  ================================"
    echo "  Se ha creado un archivo .env básico."
    echo "  Debes editarlo y cambiar los secrets de producción:"
    echo ""
    echo "  cd ~/my-strapi-project"
    echo "  nano .env"
    echo ""
    echo "  Para generar secrets seguros usa:"
    echo "  openssl rand -base64 32"
    echo "  ================================"
    echo ""
else
    echo "  → Archivo .env ya existe"
fi

ENDSSH

echo -e "${GREEN}✓ Configuración completada${NC}\n"

# Preguntar si iniciar Docker Compose
echo -e "${YELLOW}¿Deseas iniciar Docker Compose ahora? (y/n)${NC}"
read -r START_DOCKER

if [ "$START_DOCKER" = "y" ] || [ "$START_DOCKER" = "Y" ]; then
    echo -e "${YELLOW}Iniciando contenedores...${NC}"

    ssh -i "$KEY_FILE" ubuntu@"$EC2_IP" << 'ENDSSH'
    cd ~

    echo "  → Deteniendo contenedores existentes (si los hay)..."
    docker compose -f docker-compose.postgres.yml down 2>/dev/null || true

    echo "  → Iniciando contenedores..."
    docker compose -f docker-compose.postgres.yml up -d

    echo "  → Esperando a que los servicios estén listos..."
    sleep 5

    echo "  → Estado de contenedores:"
    docker compose -f docker-compose.postgres.yml ps

    echo ""
    echo "  → Últimas líneas de logs:"
    docker compose -f docker-compose.postgres.yml logs --tail=20
ENDSSH

    echo ""
    echo -e "${GREEN}================================${NC}"
    echo -e "${GREEN}¡Despliegue completado!${NC}"
    echo -e "${GREEN}================================${NC}\n"

    echo -e "${YELLOW}Accede a tu aplicación:${NC}"
    echo "  → Admin: http://$EC2_IP:1337/admin"
    echo "  → API: http://$EC2_IP:1337/api"

    echo -e "\n${YELLOW}Comandos útiles:${NC}"
    echo "  → Ver logs: ssh -i $KEY_FILE ubuntu@$EC2_IP 'docker compose -f docker-compose.postgres.yml logs -f'"
    echo "  → Reiniciar: ssh -i $KEY_FILE ubuntu@$EC2_IP 'docker compose -f docker-compose.postgres.yml restart'"
    echo "  → Detener: ssh -i $KEY_FILE ubuntu@$EC2_IP 'docker compose -f docker-compose.postgres.yml down'"
else
    echo ""
    echo -e "${GREEN}Archivos transferidos exitosamente${NC}"
    echo ""
    echo -e "${YELLOW}Para iniciar manualmente, conecta a EC2:${NC}"
    echo "  ssh -i $KEY_FILE ubuntu@$EC2_IP"
    echo ""
    echo -e "${YELLOW}Luego ejecuta:${NC}"
    echo "  cd ~/my-strapi-project"
    echo "  nano .env  # Configura las variables de entorno"
    echo "  cd .."
    echo "  docker compose -f docker-compose.postgres.yml up -d"
fi

echo ""
