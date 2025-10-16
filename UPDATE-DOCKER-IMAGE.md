# Cómo Actualizar la Imagen en Docker Hub

## Proceso Completo

### 1. Limpiar archivos temporales (IMPORTANTE)

```bash
cd "c:\cv\Nueva carpeta\my-strapi-project"

# Borrar base de datos local (para no incluirla en la imagen)
rm -rf .tmp/*

# Borrar otros archivos temporales
rm -rf .cache/*
rm -rf dist/*
rm -rf build/*
```

### 2. Construir nueva imagen

```bash
cd "c:\cv\Nueva carpeta"

# Build de la imagen
docker build -t k3n5h1n/strapi-blog:latest ./my-strapi-project
```

### 3. Subir a Docker Hub

```bash
# Login (solo primera vez)
docker login

# Push de la imagen
docker push k3n5h1n/strapi-blog:latest
```

### 4. Actualizar en EC2

```bash
# SSH a EC2
ssh -i key.pem ubuntu@ec2-ip

cd ~/strapi

# Pull nueva imagen
docker compose -f docker-compose.dockerhub.yml pull

# Reiniciar con nueva imagen
docker compose -f docker-compose.dockerhub.yml up -d

# Ver logs
docker compose -f docker-compose.dockerhub.yml logs -f
```

## ⚠️ IMPORTANTE

### NO incluir en la imagen:

- ❌ `.tmp/` (base de datos con usuarios)
- ❌ `.cache/` (archivos de build)
- ❌ `dist/` y `build/` (se generan en build)
- ❌ `.env` (secretos de producción)
- ❌ `node_modules/` (se instalan en build)

El `.dockerignore` ya está configurado para excluir estos archivos.

### SÍ incluir en la imagen:

- ✅ Código fuente (`src/`)
- ✅ Configuración (`config/`)
- ✅ `package.json` y `package-lock.json`
- ✅ Admin panel pre-construido (se hace en `npm run build`)

## Script Automatizado

Crea este script para automatizar el proceso:

**update-image.sh** (Git Bash):

```bash
#!/bin/bash

echo "🧹 Cleaning temporary files..."
cd my-strapi-project
rm -rf .tmp/* .cache/* dist/* build/*
cd ..

echo "🏗️  Building Docker image..."
docker build -t k3n5h1n/strapi-blog:latest ./my-strapi-project

echo "📤 Pushing to Docker Hub..."
docker push k3n5h1n/strapi-blog:latest

echo "✅ Image updated successfully!"
echo ""
echo "📋 To deploy on EC2:"
echo "  ssh -i key.pem ubuntu@ec2-ip"
echo "  cd ~/strapi"
echo "  docker compose -f docker-compose.dockerhub.yml pull"
echo "  docker compose -f docker-compose.dockerhub.yml up -d"
```

Uso:
```bash
chmod +x update-image.sh
./update-image.sh
```

## Versioning (Recomendado)

Para mejor control, usa tags de versión:

```bash
# Build con versión específica
docker build -t k3n5h1n/strapi-blog:v1.0.0 ./my-strapi-project
docker build -t k3n5h1n/strapi-blog:latest ./my-strapi-project

# Push ambos tags
docker push k3n5h1n/strapi-blog:v1.0.0
docker push k3n5h1n/strapi-blog:latest
```

En `docker-compose.dockerhub.yml` puedes usar versión fija:
```yaml
services:
  strapi:
    image: k3n5h1n/strapi-blog:v1.0.0  # Versión específica
```

## Verificar imagen en Docker Hub

Después de hacer push, verifica en:
```
https://hub.docker.com/r/k3n5h1n/strapi-blog/tags
```

Deberías ver:
- Tag: `latest`
- Size: ~500-600 MB
- Last pushed: Hace X minutos

## Troubleshooting

### Error: "denied: requested access to the resource is denied"

```bash
# Login de nuevo
docker login
# Username: k3n5h1n
# Password: tu-password-de-docker-hub
```

### Imagen muy pesada (>1GB)

Significa que estás incluyendo archivos innecesarios:

```bash
# Verificar .dockerignore
cat my-strapi-project/.dockerignore

# Debe incluir:
# node_modules/
# .tmp/
# .cache/
# dist/
```

### Build falla con error de memoria

```bash
# Aumentar memoria de Docker Desktop
# Docker Desktop → Settings → Resources → Memory → 4GB+
```

## Workflow Completo

1. **Desarrollo local**: Hacer cambios en `my-strapi-project/`
2. **Test local**: `docker compose -f docker-compose.yml up -d`
3. **Limpiar**: Borrar `.tmp/*`, `.cache/*`, etc.
4. **Build**: `docker build -t k3n5h1n/strapi-blog:latest ./my-strapi-project`
5. **Push**: `docker push k3n5h1n/strapi-blog:latest`
6. **Deploy EC2**:
   ```bash
   ssh ec2
   docker compose pull
   docker compose up -d
   ```
