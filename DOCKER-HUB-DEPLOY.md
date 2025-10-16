# Despliegue con Docker Hub (Sin Build en EC2)

Esta guía usa tu imagen pre-construida en Docker Hub: `k3n5h1n/strapi-blog`

## Ventajas

✅ **No consume RAM en EC2** - Solo descarga la imagen
✅ **Más rápido** - 1-2 minutos vs 10+ minutos de build
✅ **Instancia pequeña** - Puedes usar t3.micro sin problemas
✅ **Sin errores de memoria** - No hay build, no hay problemas

## Comandos en EC2

### Primera vez (Deployment inicial):

```bash
# Conectar a EC2
ssh -i tu-key.pem ubuntu@tu-ec2-ip

# Clonar repositorio (si aún no lo has hecho)
git clone https://github.com/miguel-anay/strapi.git
cd strapi

# Configurar variables de entorno
cd my-strapi-project
cp .env.example .env
nano .env  # Configura tus secrets de producción

# Volver al directorio raíz
cd ..

# Descargar imagen desde Docker Hub
docker compose -f docker-compose.dockerhub.yml pull

# Iniciar contenedores (SIN --build)
docker compose -f docker-compose.dockerhub.yml up -d

# Ver logs
docker compose -f docker-compose.dockerhub.yml logs -f
```

### Actualizar a nueva versión:

Cuando subas una nueva imagen a Docker Hub:

```bash
# En EC2
cd ~/strapi

# Detener contenedores
docker compose -f docker-compose.dockerhub.yml down

# Descargar nueva versión de la imagen
docker compose -f docker-compose.dockerhub.yml pull

# Iniciar con la nueva imagen
docker compose -f docker-compose.dockerhub.yml up -d

# Ver logs
docker compose -f docker-compose.dockerhub.yml logs -f
```

### Comandos útiles:

```bash
# Ver estado
docker compose -f docker-compose.dockerhub.yml ps

# Ver logs en tiempo real
docker compose -f docker-compose.dockerhub.yml logs -f strapi

# Reiniciar solo Strapi
docker compose -f docker-compose.dockerhub.yml restart strapi

# Detener todo
docker compose -f docker-compose.dockerhub.yml down

# Ver imágenes descargadas
docker images | grep strapi-blog
```

## Workflow Completo

### 1. Hacer cambios localmente (en tu PC):

```bash
cd "c:\cv\Nueva carpeta\my-strapi-project"
# Hacer cambios en el código...
```

### 2. Construir imagen localmente:

```bash
cd "c:\cv\Nueva carpeta"

# Construir imagen
docker compose -f docker-compose.yml build

# O construir directamente con docker:
docker build -t k3n5h1n/strapi-blog:latest ./my-strapi-project
```

### 3. Subir imagen a Docker Hub:

```bash
# Login en Docker Hub (solo primera vez)
docker login

# Subir imagen
docker push k3n5h1n/strapi-blog:latest
```

### 4. Actualizar en EC2:

```bash
# SSH a EC2
ssh -i key.pem ubuntu@ec2-ip

cd ~/strapi

# Pull nueva imagen
docker compose -f docker-compose.dockerhub.yml pull

# Reiniciar
docker compose -f docker-compose.dockerhub.yml up -d
```

## Comparación de Archivos

| Archivo | Uso | Build | RAM en EC2 |
|---------|-----|-------|------------|
| `docker-compose.yml` | Desarrollo local (SQLite) | Sí | N/A |
| `docker-compose.postgres.yml` | Build en EC2 | Sí | Alto (2GB+) |
| `docker-compose.dockerhub.yml` | Producción (imagen pre-construida) | No | Bajo (100MB) |

## Automatización con Script

Crea este script en tu PC para automatizar el push:

**build-and-push.sh** (Git Bash en Windows):

```bash
#!/bin/bash

echo "Building Strapi image..."
docker build -t k3n5h1n/strapi-blog:latest ./my-strapi-project

echo "Pushing to Docker Hub..."
docker push k3n5h1n/strapi-blog:latest

echo "Done! Image available at: k3n5h1n/strapi-blog:latest"
echo ""
echo "To deploy on EC2, run:"
echo "  ssh -i key.pem ubuntu@ec2-ip"
echo "  cd ~/strapi"
echo "  docker compose -f docker-compose.dockerhub.yml pull"
echo "  docker compose -f docker-compose.dockerhub.yml up -d"
```

Uso:
```bash
chmod +x build-and-push.sh
./build-and-push.sh
```

## Versionado de Imágenes

Para mejor control de versiones:

```bash
# Tag con versión específica
docker build -t k3n5h1n/strapi-blog:v1.0.0 ./my-strapi-project
docker build -t k3n5h1n/strapi-blog:latest ./my-strapi-project

# Push ambos tags
docker push k3n5h1n/strapi-blog:v1.0.0
docker push k3n5h1n/strapi-blog:latest
```

En EC2, usar versión específica:
```yaml
# docker-compose.dockerhub.yml
services:
  strapi:
    image: k3n5h1n/strapi-blog:v1.0.0  # Versión fija
```

## Rollback a Versión Anterior

Si algo falla:

```bash
# En EC2
docker compose -f docker-compose.dockerhub.yml down

# Cambiar versión en docker-compose.dockerhub.yml
nano docker-compose.dockerhub.yml
# Cambiar: k3n5h1n/strapi-blog:v1.0.0

# Pull versión anterior
docker compose -f docker-compose.dockerhub.yml pull

# Iniciar
docker compose -f docker-compose.dockerhub.yml up -d
```

## Troubleshooting

### Error: "Image not found"

```bash
# Verificar que la imagen existe en Docker Hub
# Ve a: https://hub.docker.com/r/k3n5h1n/strapi-blog

# O intenta pull manual
docker pull k3n5h1n/strapi-blog:latest
```

### Error: "unauthorized: incorrect username or password"

```bash
# Login en Docker Hub (en tu PC, no en EC2)
docker login
# Username: k3n5h1n
# Password: tu-password-de-docker-hub
```

### Imagen desactualizada en EC2

```bash
# Forzar descarga de nueva versión
docker compose -f docker-compose.dockerhub.yml down
docker image rm k3n5h1n/strapi-blog:latest
docker compose -f docker-compose.dockerhub.yml pull
docker compose -f docker-compose.dockerhub.yml up -d
```

## Configuración de .env en EC2

Recuerda que el `.env` NO está en la imagen Docker, debes configurarlo manualmente:

```bash
# En EC2
cd ~/strapi/my-strapi-project
nano .env
```

Variables importantes:
```env
NODE_ENV=production
DATABASE_CLIENT=postgres
DATABASE_HOST=postgres
DATABASE_PASSWORD=cambia-este-password

# Genera con: openssl rand -base64 32
APP_KEYS=key1,key2,key3,key4
ADMIN_JWT_SECRET=secret1
API_TOKEN_SALT=salt1
```

## Verificación

```bash
# Ver que la imagen se descargó
docker images | grep strapi-blog

# Deberías ver:
# k3n5h1n/strapi-blog   latest   abc123   X minutes ago   XXX MB

# Ver contenedores corriendo
docker compose -f docker-compose.dockerhub.yml ps

# Deberías ver:
# my-strapi-project   Up
# strapi-postgres     Up

# Acceder en navegador
# http://TU_EC2_IP:1337/admin
```

## Resumen

**En tu PC:**
```bash
# 1. Hacer cambios
# 2. Build local
docker build -t k3n5h1n/strapi-blog:latest ./my-strapi-project

# 3. Push a Docker Hub
docker push k3n5h1n/strapi-blog:latest
```

**En EC2:**
```bash
# 1. Pull nueva imagen
docker compose -f docker-compose.dockerhub.yml pull

# 2. Reiniciar
docker compose -f docker-compose.dockerhub.yml up -d
```

✅ **Sin build en EC2 = Sin problemas de memoria**
