# Solución: Error de Memoria en EC2

## Problema

Cuando ejecutas `docker compose up -d --build` en EC2, el build falla con:

```
FATAL ERROR: Ineffective mark-compacts near heap limit Allocation failed - JavaScript heap out of memory
```

Esto ocurre porque el build del admin panel de Strapi consume más memoria de la disponible.

## Soluciones (en orden de preferencia)

### ✅ Solución 1: Aumentar memoria de Node.js (YA APLICADA)

**Estado**: Ya se aplicó este fix en el Dockerfile.

El Dockerfile ahora incluye:
```dockerfile
ENV NODE_OPTIONS="--max-old-space-size=2048"
```

**En EC2, actualiza el código:**

```bash
# Conectar a EC2
ssh -i tu-key.pem ubuntu@tu-ec2-ip

# Ir al directorio del proyecto
cd ~/strapi

# Actualizar código desde GitHub
git pull origin main

# Limpiar contenedores e imágenes antiguas
docker compose -f docker-compose.postgres.yml down
docker system prune -f

# Reconstruir y iniciar
docker compose -f docker-compose.postgres.yml up -d --build

# Ver logs
docker compose -f docker-compose.postgres.yml logs -f
```

---

### ✅ Solución 2: Agregar Swap (Memoria Virtual)

Si la Solución 1 no es suficiente, agrega swap en EC2:

```bash
# En EC2, ejecuta:

# Verificar memoria actual
free -h

# Crear archivo de swap de 2GB
sudo fallocate -l 2G /swapfile

# Dar permisos correctos
sudo chmod 600 /swapfile

# Crear swap
sudo mkswap /swapfile

# Activar swap
sudo swapon /swapfile

# Verificar que esté activo
free -h
# Deberías ver 2G en la fila "Swap"

# Hacer permanente (sobrevive reinicios)
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# Ahora intenta el build nuevamente
cd ~/strapi
docker compose -f docker-compose.postgres.yml up -d --build
```

---

### ✅ Solución 3: Usar instancia EC2 más grande (TEMPORAL)

Si tienes una `t2.micro` o `t3.micro`, el build puede fallar por falta de RAM.

**Opción A: Actualizar temporalmente**

1. Ve a AWS Console → EC2 → Tu instancia
2. Stop la instancia
3. Actions → Instance Settings → Change instance type
4. Cambia a `t3.medium` (4 GB RAM) o `t3.large` (8 GB RAM)
5. Inicia la instancia
6. Ejecuta el build
7. Una vez completado el build, puedes volver a `t3.small` o `t3.micro`

**Opción B: Hacer build localmente**

Evita hacer build en EC2:

```bash
# En tu máquina local (Windows)
cd "c:\cv\Nueva carpeta"

# Asegúrate de que docker-compose.postgres.yml NO ejecute el build
# Usa una imagen pre-construida en Docker Hub
```

---

### ✅ Solución 4: Build en dos etapas (AVANZADO)

Modifica el Dockerfile para hacer build incremental:

```dockerfile
FROM node:20-alpine AS builder

# Install dependencies
RUN apk add --no-cache python3 make g++ sqlite

WORKDIR /opt/app

# Copy package files
COPY package*.json ./

# Install ALL dependencies (including dev)
RUN npm install

# Copy source
COPY . .

# Build with increased memory
ENV NODE_OPTIONS="--max-old-space-size=4096"
ENV NODE_ENV=production
RUN npm run build

# Production stage
FROM node:20-alpine

RUN apk add --no-cache sqlite

WORKDIR /opt/app

# Copy package files
COPY package*.json ./

# Install only production dependencies
RUN npm install --omit=dev

# Copy built files from builder
COPY --from=builder /opt/app/dist ./dist
COPY --from=builder /opt/app/build ./build
COPY . .

EXPOSE 1337

CMD ["npm", "run", "start"]
```

---

### ✅ Solución 5: Deshabilitar build del admin (PRODUCCIÓN)

Si NO necesitas modificar el admin panel:

```bash
# En EC2, edita .env
nano ~/strapi/my-strapi-project/.env

# Agrega:
STRAPI_DISABLE_REMOTE_DATA_TRANSFER=true

# Simplifica el Dockerfile eliminando el build step
# (solo si ya tienes el admin pre-construido)
```

---

## Comandos de Diagnóstico

### Verificar memoria disponible en EC2:
```bash
free -h
```

### Verificar tipo de instancia:
```bash
curl -s http://169.254.169.254/latest/meta-data/instance-type
```

### Ver uso de memoria durante build:
```bash
# En otra terminal SSH
watch -n 1 free -h
```

### Limpiar espacio en Docker:
```bash
docker system prune -af --volumes
```

---

## Recomendaciones por Tipo de Instancia

| Tipo de Instancia | RAM  | Solución Recomendada |
|-------------------|------|----------------------|
| t2.micro / t3.micro | 1 GB | Swap + NODE_OPTIONS=2048 |
| t2.small / t3.small | 2 GB | NODE_OPTIONS=2048 (suficiente) |
| t2.medium / t3.medium | 4 GB | NODE_OPTIONS=2048 (óptimo) |
| t2.large / t3.large | 8 GB | Sin problemas |

---

## Pasos para Aplicar la Solución

### En EC2 (AHORA):

```bash
# 1. Actualizar código desde GitHub
cd ~/strapi
git pull origin main

# 2. Agregar swap (si usas t3.micro o t3.small)
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
free -h  # Verificar

# 3. Limpiar Docker
docker compose -f docker-compose.postgres.yml down
docker system prune -f

# 4. Reconstruir
docker compose -f docker-compose.postgres.yml up -d --build

# 5. Monitorear logs
docker compose -f docker-compose.postgres.yml logs -f strapi
```

### Verificar que funciona:

```bash
# El build debería completarse sin errores
# Verás algo como:
# ✔ Building admin panel (XXXXXms)

# Verificar que Strapi está corriendo
docker compose -f docker-compose.postgres.yml ps

# Deberías ver:
# NAME                STATUS
# my-strapi-project   Up
# strapi-postgres     Up

# Acceder en navegador
# http://TU_EC2_IP:1337/admin
```

---

## Troubleshooting

### Si aún falla después de agregar swap:

```bash
# Aumenta el límite de memoria a 4096 MB
# Edita el Dockerfile en GitHub:
ENV NODE_OPTIONS="--max-old-space-size=4096"

# Actualiza en EC2
git pull origin main
docker compose -f docker-compose.postgres.yml up -d --build
```

### Si el swap no se activa:

```bash
# Verificar swap
sudo swapon --show

# Si no aparece nada, reactiva:
sudo swapon /swapfile

# Verificar nuevamente
free -h
```

### Si Docker usa mucho espacio:

```bash
# Ver uso de disco
df -h

# Limpiar todo Docker
docker system prune -af --volumes

# Esto liberará espacio pero BORRARÁ todos los contenedores y volúmenes
```

---

## Costos de Instancias EC2

Si decides usar una instancia más grande temporalmente:

| Tipo      | RAM  | vCPU | Precio/hora (aprox) | Precio/mes |
|-----------|------|------|---------------------|------------|
| t3.micro  | 1 GB | 2    | $0.0104            | ~$7.50     |
| t3.small  | 2 GB | 2    | $0.0208            | ~$15.00    |
| t3.medium | 4 GB | 2    | $0.0416            | ~$30.00    |
| t3.large  | 8 GB | 2    | $0.0832            | ~$60.00    |

**Consejo**: Usa `t3.medium` solo para el build inicial, luego vuelve a `t3.small` o `t3.micro` para ahorrar costos.

---

## Resumen

1. ✅ **Ya aplicado**: Aumentar `NODE_OPTIONS` a 2048 MB
2. 🔄 **Por hacer en EC2**:
   - `git pull origin main`
   - Agregar swap de 2 GB
   - Reconstruir con `docker compose up -d --build`

3. 📊 **Verificar**: El build debería completarse exitosamente

¡El Dockerfile ya está actualizado en GitHub! Solo falta aplicarlo en EC2.
