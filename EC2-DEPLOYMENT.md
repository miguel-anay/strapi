# Guía de Despliegue en AWS EC2

Esta guía te ayudará a desplegar tu aplicación Strapi en una instancia EC2 de AWS.

## Requisitos Previos

- Cuenta de AWS con acceso a EC2
- Dominio (opcional, pero recomendado para producción)
- Cliente SSH configurado

## Paso 1: Crear y Configurar Instancia EC2

### 1.1 Lanzar Instancia EC2

1. Ve al **Dashboard de EC2** en AWS Console
2. Click en **"Launch Instance"**
3. Configura:
   - **Name**: `strapi-production`
   - **AMI**: Ubuntu Server 22.04 LTS (64-bit x86)
   - **Instance Type**: `t3.medium` (mínimo recomendado) o `t3.large` para mejor rendimiento
   - **Key Pair**: Crea o selecciona una key pair existente (guarda el archivo .pem)
   - **Storage**: 30 GB gp3 (mínimo recomendado)

### 1.2 Configurar Security Group

Configura las siguientes reglas de entrada:

| Type  | Protocol | Port Range | Source          | Description            |
|-------|----------|------------|-----------------|------------------------|
| SSH   | TCP      | 22         | My IP / 0.0.0.0/0 | SSH access           |
| HTTP  | TCP      | 80         | 0.0.0.0/0       | HTTP traffic           |
| HTTPS | TCP      | 443        | 0.0.0.0/0       | HTTPS traffic          |
| Custom| TCP      | 1337       | 0.0.0.0/0       | Strapi (temporal)      |

**Nota**: Para producción, remueve el acceso directo al puerto 1337 una vez configurado Nginx.

### 1.3 Elastic IP (Recomendado)

1. Ve a **Elastic IPs** en el panel de EC2
2. Click en **"Allocate Elastic IP address"**
3. Asocia la IP a tu instancia EC2

Esto asegura que tu IP pública no cambie si reinicias la instancia.

## Paso 2: Conectar a la Instancia

### Desde Windows (Git Bash / PowerShell):

```bash
# Cambiar permisos del archivo .pem
chmod 400 /path/to/your-key.pem

# Conectar via SSH
ssh -i /path/to/your-key.pem ubuntu@YOUR_EC2_PUBLIC_IP
```

### Desde Mac/Linux:

```bash
chmod 400 ~/path/to/your-key.pem
ssh -i ~/path/to/your-key.pem ubuntu@YOUR_EC2_PUBLIC_IP
```

## Paso 3: Instalar Dependencias en EC2

Una vez conectado a tu instancia, ejecuta:

```bash
# Actualizar el sistema
sudo apt update && sudo apt upgrade -y

# Instalar Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker ubuntu

# Instalar Docker Compose
sudo apt install docker-compose-plugin -y

# Instalar Git
sudo apt install git -y

# Instalar Nginx (reverse proxy)
sudo apt install nginx -y

# Cerrar sesión y volver a conectar para aplicar cambios de Docker
exit
```

Vuelve a conectarte via SSH.

## Paso 4: Subir el Proyecto a EC2

### Opción A: Usando Git (Recomendado)

Si tu proyecto está en GitHub/GitLab:

```bash
# Clonar repositorio
git clone https://github.com/tu-usuario/tu-repositorio.git
cd tu-repositorio
```

### Opción B: Usando SCP (Transferencia directa)

Desde tu máquina local:

```bash
# Comprimir el proyecto
cd "c:\cv\Nueva carpeta"
tar -czf strapi-project.tar.gz my-strapi-project/ docker-compose.postgres.yml .env

# Transferir a EC2
scp -i /path/to/your-key.pem strapi-project.tar.gz ubuntu@YOUR_EC2_PUBLIC_IP:~

# En EC2, descomprimir
ssh -i /path/to/your-key.pem ubuntu@YOUR_EC2_PUBLIC_IP
tar -xzf strapi-project.tar.gz
```

### Opción C: Usar el Script de Deploy

Usa el script `deploy-to-ec2.sh` que se proporciona más adelante.

## Paso 5: Configurar Variables de Entorno

En tu instancia EC2:

```bash
cd ~/my-strapi-project
nano .env
```

Actualiza las siguientes variables para producción:

```env
# Server
HOST=0.0.0.0
PORT=1337

# IMPORTANTE: Genera nuevas keys para producción
APP_KEYS=genera-nueva-key-1,genera-nueva-key-2,genera-nueva-key-3,genera-nueva-key-4
API_TOKEN_SALT=genera-nuevo-salt
ADMIN_JWT_SECRET=genera-nuevo-secret
TRANSFER_TOKEN_SALT=genera-nuevo-salt
ENCRYPTION_KEY=genera-nueva-key
JWT_SECRET=genera-nuevo-secret

# Database (PostgreSQL)
DATABASE_CLIENT=postgres
DATABASE_HOST=postgres
DATABASE_PORT=5432
DATABASE_NAME=strapi
DATABASE_USERNAME=strapi
DATABASE_PASSWORD=CAMBIA_ESTE_PASSWORD_SEGURO
DATABASE_SSL=false

# Producción
NODE_ENV=production

# URL del sitio (si tienes dominio)
STRAPI_ADMIN_BACKEND_URL=https://tu-dominio.com
```

**Generar Keys Seguras:**

```bash
# Genera keys aleatorias seguras
openssl rand -base64 32
```

## Paso 6: Iniciar la Aplicación

```bash
cd ~/my-strapi-project/..

# Iniciar con Docker Compose (PostgreSQL)
docker compose -f docker-compose.postgres.yml up -d

# Ver logs
docker compose -f docker-compose.postgres.yml logs -f

# Verificar que está corriendo
docker compose -f docker-compose.postgres.yml ps
```

## Paso 7: Configurar Nginx como Reverse Proxy

### Crear configuración de Nginx:

```bash
sudo nano /etc/nginx/sites-available/strapi
```

Pega la siguiente configuración:

```nginx
server {
    listen 80;
    server_name tu-dominio.com www.tu-dominio.com;  # O usa la IP pública

    # Aumentar tamaño de upload
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
```

### Activar configuración:

```bash
# Crear symlink
sudo ln -s /etc/nginx/sites-available/strapi /etc/nginx/sites-enabled/

# Probar configuración
sudo nginx -t

# Reiniciar Nginx
sudo systemctl restart nginx

# Habilitar Nginx al inicio
sudo systemctl enable nginx
```

## Paso 8: Configurar SSL con Let's Encrypt (HTTPS)

Si tienes un dominio:

```bash
# Instalar Certbot
sudo apt install certbot python3-certbot-nginx -y

# Obtener certificado SSL
sudo certbot --nginx -d tu-dominio.com -d www.tu-dominio.com

# Certbot configurará automáticamente Nginx para HTTPS
```

El certificado se renovará automáticamente.

## Paso 9: Verificar Acceso

- **Con IP pública**: `http://YOUR_EC2_PUBLIC_IP`
- **Con dominio (HTTP)**: `http://tu-dominio.com`
- **Con dominio (HTTPS)**: `https://tu-dominio.com`

Deberías ver el panel de administración de Strapi.

## Comandos Útiles para Mantenimiento

### Ver logs de Strapi:
```bash
docker compose -f docker-compose.postgres.yml logs -f strapi
```

### Reiniciar Strapi:
```bash
docker compose -f docker-compose.postgres.yml restart strapi
```

### Detener todo:
```bash
docker compose -f docker-compose.postgres.yml down
```

### Backup de base de datos PostgreSQL:
```bash
docker compose -f docker-compose.postgres.yml exec postgres pg_dump -U strapi strapi > backup-$(date +%Y%m%d).sql
```

### Actualizar aplicación:
```bash
git pull origin main
docker compose -f docker-compose.postgres.yml up -d --build
```

### Ver uso de recursos:
```bash
docker stats
```

## Seguridad Adicional

### 1. Firewall UFW:
```bash
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

### 2. Fail2Ban (protección contra fuerza bruta):
```bash
sudo apt install fail2ban -y
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

### 3. Actualizar Security Group:
Remover acceso directo al puerto 1337 una vez que Nginx esté configurado.

## Monitoreo

### Instalar htop:
```bash
sudo apt install htop -y
htop
```

### Ver logs del sistema:
```bash
sudo journalctl -u docker -f
```

## Troubleshooting

### Si Strapi no inicia:
```bash
# Ver logs detallados
docker compose -f docker-compose.postgres.yml logs strapi

# Verificar que PostgreSQL esté corriendo
docker compose -f docker-compose.postgres.yml ps
```

### Si hay problemas de memoria:
```bash
# Verificar memoria disponible
free -h

# Si es necesario, agregar swap
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

### Si el puerto 1337 no responde:
```bash
# Verificar que Docker esté escuchando
sudo netstat -tulpn | grep 1337

# Verificar logs de Nginx
sudo tail -f /var/log/nginx/error.log
```

## Costos Estimados (AWS)

- **t3.medium**: ~$30-35/mes
- **t3.large**: ~$60-70/mes
- **30 GB gp3 storage**: ~$2.40/mes
- **Elastic IP**: Gratis mientras esté asociada
- **Transfer**: Depende del tráfico

**Total estimado**: $32-72/mes dependiendo del tipo de instancia.

## Backup Automático

Crea un cron job para backups automáticos:

```bash
crontab -e
```

Agrega:
```cron
# Backup diario a las 2 AM
0 2 * * * cd ~/my-strapi-project && docker compose -f docker-compose.postgres.yml exec -T postgres pg_dump -U strapi strapi > ~/backups/backup-$(date +\%Y\%m\%d).sql
```

## Recursos Adicionales

- [Documentación de Strapi](https://docs.strapi.io)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [AWS EC2 Documentation](https://docs.aws.amazon.com/ec2/)
