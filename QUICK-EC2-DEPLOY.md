# Guía Rápida: Transferir Docker Compose a EC2

Esta guía asume que ya tienes Docker y Docker Compose instalados en tu EC2.

## Método 1: Transferencia Directa con SCP (Más Rápido)

### Paso 1: Preparar el proyecto localmente

```bash
cd "c:\cv\Nueva carpeta"

# Eliminar archivos grandes innecesarios antes de transferir
cd my-strapi-project
rm -rf node_modules dist .tmp .cache
cd ..
```

### Paso 2: Transferir archivos a EC2

Desde tu máquina local (Git Bash o PowerShell):

```bash
# Reemplaza estos valores
EC2_IP="tu-ip-ec2"              # Ejemplo: 54.123.45.67
KEY_FILE="/ruta/a/tu-key.pem"   # Ejemplo: ~/keys/my-key.pem

# Transferir todo el proyecto
scp -i $KEY_FILE -r my-strapi-project ubuntu@$EC2_IP:~/
scp -i $KEY_FILE docker-compose.postgres.yml ubuntu@$EC2_IP:~/
```

### Paso 3: Conectar a EC2 y configurar

```bash
# Conectar via SSH
ssh -i $KEY_FILE ubuntu@$EC2_IP
```

Una vez dentro de EC2:

```bash
cd ~/my-strapi-project

# Actualizar .env para producción
nano .env
```

**Actualiza estas variables importantes:**

```env
# Cambiar a producción
NODE_ENV=production

# IMPORTANTE: Genera nuevas keys para producción
# Usa este comando para generar keys seguras:
# openssl rand -base64 32

APP_KEYS=nueva-key-1,nueva-key-2,nueva-key-3,nueva-key-4
API_TOKEN_SALT=nuevo-salt
ADMIN_JWT_SECRET=nuevo-secret
TRANSFER_TOKEN_SALT=nuevo-salt
ENCRYPTION_KEY=nueva-key
JWT_SECRET=nuevo-secret

# Database PostgreSQL
DATABASE_CLIENT=postgres
DATABASE_HOST=postgres
DATABASE_PORT=5432
DATABASE_NAME=strapi
DATABASE_USERNAME=strapi
DATABASE_PASSWORD=cambia_este_password_seguro
DATABASE_SSL=false

# Server
HOST=0.0.0.0
PORT=1337
```

### Paso 4: Iniciar Docker Compose

```bash
cd ~

# Iniciar contenedores en background
docker compose -f docker-compose.postgres.yml up -d

# Ver logs en tiempo real
docker compose -f docker-compose.postgres.yml logs -f

# Presiona Ctrl+C para salir de los logs
```

### Paso 5: Verificar que está corriendo

```bash
# Ver estado de contenedores
docker compose -f docker-compose.postgres.yml ps

# Deberías ver algo como:
# NAME                COMMAND                  SERVICE    STATUS
# my-strapi-project   "docker-entrypoint..."   strapi     Up
# strapi-postgres     "docker-entrypoint..."   postgres   Up
```

### Paso 6: Acceder desde tu navegador

Abre tu navegador en:
- `http://TU_IP_EC2:1337/admin`

## Método 2: Usando Git (Recomendado para actualizaciones)

### Paso 1: Subir tu proyecto a GitHub/GitLab

Desde tu máquina local:

```bash
cd "c:\cv\Nueva carpeta"
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/tu-usuario/tu-repo.git
git push -u origin main
```

### Paso 2: Clonar en EC2

Conecta a tu EC2:

```bash
ssh -i $KEY_FILE ubuntu@$EC2_IP
```

Dentro de EC2:

```bash
# Clonar repositorio
git clone https://github.com/tu-usuario/tu-repo.git
cd tu-repo

# Configurar .env (no se sube a Git)
cd my-strapi-project
cp .env.example .env
nano .env
# Configura las variables como se indicó arriba

# Volver al directorio raíz
cd ..

# Iniciar
docker compose -f docker-compose.postgres.yml up -d
```

**Ventaja**: Para actualizar solo necesitas hacer `git pull` y `docker compose up -d --build`

## Método 3: Script Automatizado

Copia este script en tu máquina local y ejecútalo:

### En Git Bash (Windows):

```bash
#!/bin/bash

# Configuración
EC2_IP="54.123.45.67"  # CAMBIA ESTO
KEY_FILE="~/keys/my-key.pem"  # CAMBIA ESTO

# Comprimir proyecto (excluyendo archivos grandes)
echo "Comprimiendo proyecto..."
tar -czf strapi-deploy.tar.gz \
    --exclude='my-strapi-project/node_modules' \
    --exclude='my-strapi-project/.tmp' \
    --exclude='my-strapi-project/dist' \
    --exclude='my-strapi-project/.cache' \
    my-strapi-project/ \
    docker-compose.postgres.yml

# Transferir
echo "Transfiriendo a EC2..."
scp -i $KEY_FILE strapi-deploy.tar.gz ubuntu@$EC2_IP:~/

# Descomprimir y ejecutar en EC2
echo "Iniciando en EC2..."
ssh -i $KEY_FILE ubuntu@$EC2_IP << 'EOF'
    tar -xzf strapi-deploy.tar.gz
    cd my-strapi-project

    # Generar .env si no existe
    if [ ! -f .env ]; then
        cp .env.example .env
        echo "¡IMPORTANTE! Configura el archivo .env antes de continuar"
        exit 1
    fi

    cd ..
    docker compose -f docker-compose.postgres.yml up -d
    docker compose -f docker-compose.postgres.yml logs
EOF

echo "¡Listo!"
echo "Accede a: http://$EC2_IP:1337/admin"

# Limpiar
rm strapi-deploy.tar.gz
```

Guarda como `deploy.sh` y ejecuta:

```bash
chmod +x deploy.sh
./deploy.sh
```

## Comandos Útiles en EC2

### Ver logs:
```bash
docker compose -f docker-compose.postgres.yml logs -f strapi
docker compose -f docker-compose.postgres.yml logs -f postgres
```

### Reiniciar:
```bash
docker compose -f docker-compose.postgres.yml restart
```

### Detener:
```bash
docker compose -f docker-compose.postgres.yml down
```

### Reconstruir (después de cambios en código):
```bash
docker compose -f docker-compose.postgres.yml up -d --build
```

### Ver uso de recursos:
```bash
docker stats
```

### Entrar al contenedor de Strapi:
```bash
docker compose -f docker-compose.postgres.yml exec strapi sh
```

### Backup de base de datos:
```bash
docker compose -f docker-compose.postgres.yml exec postgres pg_dump -U strapi strapi > backup.sql
```

### Restaurar backup:
```bash
docker compose -f docker-compose.postgres.yml exec -T postgres psql -U strapi strapi < backup.sql
```

## Configurar Acceso (Security Groups)

En AWS Console → EC2 → Security Groups:

Asegúrate de tener estas reglas de entrada:

| Type  | Port  | Source      | Description |
|-------|-------|-------------|-------------|
| SSH   | 22    | Tu IP       | SSH access  |
| Custom| 1337  | 0.0.0.0/0   | Strapi      |
| HTTP  | 80    | 0.0.0.0/0   | Nginx (opcional) |
| HTTPS | 443   | 0.0.0.0/0   | SSL (opcional) |

## Troubleshooting

### Error: "Cannot connect to Docker daemon"
```bash
sudo systemctl start docker
sudo usermod -aG docker ubuntu
# Desconectar y volver a conectar SSH
```

### Error: "Port 1337 already in use"
```bash
# Ver qué está usando el puerto
sudo netstat -tulpn | grep 1337

# Detener proceso
sudo kill -9 <PID>
```

### Error: "Out of memory"
```bash
# Agregar swap
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

### Ver errores de Strapi:
```bash
docker compose -f docker-compose.postgres.yml logs --tail=100 strapi
```

## Próximos Pasos (Opcional)

### 1. Configurar Nginx como Reverse Proxy

```bash
sudo apt install nginx -y

sudo nano /etc/nginx/sites-available/strapi
```

Pega:
```nginx
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:1337;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

Activa:
```bash
sudo ln -s /etc/nginx/sites-available/strapi /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx
```

Ahora accede en: `http://TU_IP_EC2` (sin puerto 1337)

### 2. Configurar SSL con Let's Encrypt

```bash
sudo apt install certbot python3-certbot-nginx -y
sudo certbot --nginx -d tu-dominio.com
```

### 3. Configurar Auto-start

Docker Compose ya está configurado con `restart: unless-stopped`, por lo que los contenedores se reiniciarán automáticamente si el servidor se reinicia.

## Resumen de Comandos

```bash
# TRANSFERIR (desde tu máquina local)
scp -i key.pem -r my-strapi-project ubuntu@EC2_IP:~/
scp -i key.pem docker-compose.postgres.yml ubuntu@EC2_IP:~/

# CONECTAR
ssh -i key.pem ubuntu@EC2_IP

# INICIAR (en EC2)
cd ~
docker compose -f docker-compose.postgres.yml up -d

# VER LOGS (en EC2)
docker compose -f docker-compose.postgres.yml logs -f

# DETENER (en EC2)
docker compose -f docker-compose.postgres.yml down
```

¡Eso es todo! Tu Strapi debería estar corriendo en EC2.
