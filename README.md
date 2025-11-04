# Strapi CMS - Docker Setup

Este proyecto contiene una aplicación **Strapi CMS v5.27.0** configurada para ejecutarse con Docker, optimizada para desarrollo local y producción con nginx-proxy-manager.

## Estado del Proyecto

✅ **Configurado para producción**
- Desarrollo local: http://localhost:1337
- Producción: https://blog.miguel-anay.nom.pe
- Soporte completo para reverse proxy (nginx-proxy-manager)
- **Error 500 solucionado** en login de administrador

## Características

- ✅ Multi-entorno (desarrollo/producción)
- ✅ Docker Compose con hot-reload para desarrollo
- ✅ Configuración optimizada para nginx-proxy-manager
- ✅ Soporte para SQLite (dev) y PostgreSQL (prod)
- ✅ Base de datos transferible entre entornos
- ✅ SSL/HTTPS con Let's Encrypt
- ✅ Cookies seguras configurables

## Inicio Rápido

### Desarrollo Local

```bash
# Clonar o navegar al proyecto
cd "C:\cv\Nueva carpeta"

# Iniciar con Docker
docker compose up -d --build

# Ver logs
docker compose logs -f strapi
```

Acceder a:
- Admin panel: http://localhost:1337/admin
- API: http://localhost:1337/api

### Producción (AWS EC2 con nginx-proxy-manager)

Ver [PRODUCTION-SETUP.md](PRODUCTION-SETUP.md) para la guía completa de deployment.

## Configuraciones Disponibles

### 1. Desarrollo con SQLite (Recomendado para desarrollo local)

Usa el archivo `docker-compose.yml` con base de datos SQLite integrada.

**Iniciar:**
```bash
docker compose up -d --build
```

**Ver logs en tiempo real:**
```bash
docker compose logs -f strapi
```

**Detener:**
```bash
docker compose down
```

**Rebuild completo:**
```bash
docker compose down
docker compose build --no-cache
docker compose up -d
```

### 2. Producción con PostgreSQL

Usa el archivo `docker-compose.postgres.yml` con base de datos PostgreSQL separada.

**Iniciar:**
```bash
docker compose -f docker-compose.postgres.yml up -d --build
```

**Ver logs:**
```bash
docker compose -f docker-compose.postgres.yml logs -f strapi
```

**Detener:**
```bash
docker compose -f docker-compose.postgres.yml down
```

## Estructura del Proyecto

```
.
├── my-strapi-project/          # Código fuente de Strapi
│   ├── config/                 # Configuración
│   │   ├── server.ts          # ✨ Configurado para proxy inverso
│   │   ├── database.ts        # Soporte multi-base de datos
│   │   ├── middlewares.ts     # ✨ Seguridad mejorada
│   │   ├── admin.ts           # Config del panel admin
│   │   └── api.ts             # Config de API REST
│   ├── src/                   # APIs, components, extensiones
│   ├── public/                # Archivos estáticos y uploads
│   ├── scripts/               # Scripts de utilidad (seed, etc.)
│   ├── .tmp/                  # Base de datos SQLite
│   ├── .env                   # ✨ Variables de entorno (no commitear)
│   ├── .env.example           # Template de variables
│   ├── Dockerfile             # Imagen Docker optimizada
│   └── package.json           # Dependencias del proyecto
│
├── docker-compose.yml          # Docker Compose - SQLite (desarrollo)
├── docker-compose.postgres.yml # Docker Compose - PostgreSQL (producción)
├── PRODUCTION-SETUP.md         # ✨ Guía de producción con nginx-proxy-manager
├── CLAUDE.md                   # Documentación para Claude Code
└── README.md                   # Este archivo
```

## Variables de Entorno

Las variables de entorno se configuran en `my-strapi-project/.env`. Ver `my-strapi-project/.env.example` para el template.

### Variables básicas:
- `HOST`: Host del servidor (default: 0.0.0.0)
- `PORT`: Puerto del servidor (default: 1337)
- `DATABASE_CLIENT`: Tipo de base de datos (sqlite/postgres/mysql)

### Variables de seguridad:
- `APP_KEYS`: Claves de encriptación para sesiones
- `API_TOKEN_SALT`: Salt para tokens de API
- `ADMIN_JWT_SECRET`: Secret para JWT del admin
- `TRANSFER_TOKEN_SALT`: Salt para tokens de transferencia
- `JWT_SECRET`: Secret general para JWT
- `ENCRYPTION_KEY`: Clave de encriptación

### Variables de proxy (NUEVO):
- `PUBLIC_URL`: URL pública de la aplicación
  - Desarrollo: `http://localhost:1337`
  - Producción: `https://blog.miguel-anay.nom.pe`
- `ADMIN_COOKIE_SECURE`: Seguridad de cookies (default: false)
  - **Mantener en `false` cuando se usa reverse proxy**
  - El proxy maneja HTTPS, Strapi recibe HTTP

### Ejemplo para desarrollo local:
```env
HOST=0.0.0.0
PORT=1337
DATABASE_CLIENT=sqlite
PUBLIC_URL=http://localhost:1337
ADMIN_COOKIE_SECURE=false
# ... otros secrets
```

### Ejemplo para producción (con nginx-proxy-manager):
```env
HOST=0.0.0.0
PORT=1337
DATABASE_CLIENT=sqlite
PUBLIC_URL=https://blog.miguel-anay.nom.pe
ADMIN_COOKIE_SECURE=false  # Mantener false con proxy
# ... otros secrets
```

## Configuración de Reverse Proxy

Este proyecto está **optimizado para nginx-proxy-manager**. La configuración incluye:

### Características implementadas:
- ✅ `proxy: true` en [my-strapi-project/config/server.ts](my-strapi-project/config/server.ts)
- ✅ Cookies configurables por variable de entorno
- ✅ Compatibilidad con HTTPS/SSL
- ✅ **Solución al error 500** en login de admin

### Problema del Error 500 (RESUELTO)

**Síntoma:**
```
Failed to create admin refresh session
Cannot send secure cookie over unencrypted connection
POST /admin/login (500)
```

**Causa:** Strapi intenta enviar cookies seguras (HTTPS) pero recibe conexiones HTTP desde el proxy.

**Solución aplicada:**
1. `proxy: true` en `config/server.ts` - Detecta headers del proxy
2. `ADMIN_COOKIE_SECURE=false` en `.env` - Permite cookies en HTTP
3. El proxy maneja HTTPS, Strapi recibe HTTP internamente

Ver [PRODUCTION-SETUP.md](PRODUCTION-SETUP.md) para más detalles.

## Deployment en Producción

### Opción 1: AWS EC2 con nginx-proxy-manager (Recomendado)

Guía completa en [PRODUCTION-SETUP.md](PRODUCTION-SETUP.md) que incluye:
- Configuración de nginx-proxy-manager
- Certificados SSL con Let's Encrypt
- Variables de entorno para producción
- Troubleshooting del error 500
- Mejores prácticas de seguridad

**Pasos resumidos:**

1. **Transferir configuración al servidor:**
```bash
scp -i "ruta/a/key.pem" -r my-strapi-project/config ubuntu@IP_SERVIDOR:/home/ubuntu/strapi/my-strapi-project/
scp -i "ruta/a/key.pem" my-strapi-project/.env ubuntu@IP_SERVIDOR:/home/ubuntu/strapi/my-strapi-project/
```

2. **Actualizar .env en el servidor:**
```bash
ssh -i "ruta/a/key.pem" ubuntu@IP_SERVIDOR
nano /home/ubuntu/strapi/my-strapi-project/.env
# Actualizar: PUBLIC_URL=https://tu-dominio.com
# Mantener: ADMIN_COOKIE_SECURE=false
```

3. **Rebuild y reiniciar:**
```bash
cd /home/ubuntu/strapi
sudo docker compose down
sudo docker compose build --no-cache
sudo docker compose up -d
```

4. **Configurar nginx-proxy-manager:**
- Domain: tu-dominio.com
- Forward to: localhost:1337
- SSL: Let's Encrypt
- Ver [PRODUCTION-SETUP.md](PRODUCTION-SETUP.md) para configuración avanzada

### Opción 2: Desarrollo Local (sin Docker)

```bash
cd my-strapi-project
npm install
npm run develop     # Desarrollo con hot-reload
npm run build       # Build del admin panel
npm run start       # Producción
```

## Comandos Útiles

### Docker Compose

```bash
# Iniciar servicios
docker compose up -d

# Iniciar con rebuild
docker compose up -d --build

# Ver logs en tiempo real
docker compose logs -f strapi

# Ver logs con filtro de errores
docker compose logs strapi | grep error

# Estado de contenedores
docker compose ps

# Detener servicios
docker compose down

# Rebuild completo (sin cache)
docker compose build --no-cache

# Acceder al shell del contenedor
docker compose exec strapi sh

# Reiniciar solo Strapi
docker compose restart strapi

# Ver uso de recursos
docker stats my-strapi-project
```

### Build de imagen Docker con tag

```bash
# Build con tag específico
cd my-strapi-project
docker build -t my-strapi-project:prod1 .

# Build sin cache
docker build --no-cache -t my-strapi-project:prod1 .

# Listar imágenes
docker images | grep strapi
```

### Mantenimiento

```bash
# Ejecutar seed script
cd my-strapi-project
npm run seed:example

# Backup de base de datos SQLite
cp my-strapi-project/.tmp/data.db backups/data-$(date +%Y%m%d).db

# Limpiar builds antiguos de Docker
docker system prune -a

# Ver tamaño de volúmenes
docker system df
```

## Primer Uso

### Desarrollo Local

1. **Configurar variables de entorno:**
   ```bash
   cd my-strapi-project
   cp .env.example .env
   # Editar .env con tus valores
   ```

2. **Iniciar el contenedor:**
   ```bash
   docker compose up -d --build
   ```

3. **Esperar a que Strapi esté listo** (30-60 segundos la primera vez)
   ```bash
   docker compose logs -f strapi
   # Buscar: "Strapi started successfully"
   ```

4. **Abrir el navegador:** http://localhost:1337/admin

5. **Crear el primer usuario administrador**

### Producción (EC2)

Ver [PRODUCTION-SETUP.md](PRODUCTION-SETUP.md) para la guía completa.

## Persistencia de Datos

### SQLite (Desarrollo)
- **Ubicación**: `my-strapi-project/.tmp/data.db`
- **Backup**: Copiar el archivo `.db`
- **Transferible**: Sí, copiar entre entornos

### PostgreSQL (Producción)
- **Volumen Docker**: `postgres-data`
- **Backup**: `docker exec postgres pg_dump...`
- **Persistente**: Sobrevive a recreación de contenedores

### Archivos Subidos
- **Ubicación**: `my-strapi-project/public/uploads`
- **Volumen**: Montado en Docker
- **Persistente**: Sí

## Transferir Base de Datos entre Entornos

### De Local a EC2 (SQLite):

```bash
# Transferir carpeta .tmp completa
scp -i "C:\ruta\key.pem" -r "C:\cv\Nueva carpeta\my-strapi-project\.tmp" ubuntu@IP_SERVIDOR:/home/ubuntu/strapi/my-strapi-project/

# Configurar permisos en EC2
ssh -i "C:\ruta\key.pem" ubuntu@IP_SERVIDOR
sudo chown -R ubuntu:ubuntu /home/ubuntu/strapi/my-strapi-project/.tmp
sudo chmod -R 755 /home/ubuntu/strapi/my-strapi-project/.tmp
```

## Problemas Comunes

### Error 500 en Login de Admin

**Solución:**
1. Verificar que `proxy: true` esté en `config/server.ts`
2. Verificar que `ADMIN_COOKIE_SECURE=false` esté en `.env`
3. Hacer rebuild del contenedor
4. Ver [PRODUCTION-SETUP.md](PRODUCTION-SETUP.md)

### El contenedor no inicia

```bash
# Ver logs detallados
docker compose logs strapi

# Ver últimos errores
docker compose logs --tail=50 strapi | grep -i error

# Reconstruir desde cero
docker compose down
docker compose build --no-cache
docker compose up -d
```

### Puerto 1337 en uso

```bash
# Ver qué proceso usa el puerto
netstat -ano | findstr :1337  # Windows
lsof -i :1337                 # Linux/Mac

# O cambiar el puerto en docker-compose.yml:
ports:
  - "3000:1337"  # Usar puerto 3000 en lugar de 1337
```

### Problemas con node_modules

```bash
cd my-strapi-project
rm -rf node_modules package-lock.json
npm install

# O en Docker:
docker compose down
docker compose build --no-cache
docker compose up -d
```

### Base de datos bloqueada (SQLite)

```bash
# Detener Strapi
docker compose down

# Verificar que no haya procesos usando la DB
lsof my-strapi-project/.tmp/data.db

# Reiniciar
docker compose up -d
```

### Cookies no funcionan con proxy

**Verificar:**
1. `PUBLIC_URL` coincide con el dominio real
2. `ADMIN_COOKIE_SECURE=false` en `.env`
3. nginx-proxy-manager tiene las cabeceras correctas
4. Limpiar cookies del navegador

Ver troubleshooting completo en [PRODUCTION-SETUP.md](PRODUCTION-SETUP.md).

## Tecnologías

- **Strapi**: v5.27.0 (Headless CMS)
- **Node.js**: v20 Alpine
- **Database**: SQLite (dev) / PostgreSQL 16 (prod)
- **TypeScript**: v5
- **React**: v18 (admin panel)
- **Docker**: Multi-stage builds
- **Proxy**: nginx-proxy-manager compatible

## Seguridad

### Desarrollo:
- Cookies: HTTP permitido
- CORS: Configurado en `config/middlewares.ts`
- CSP: Política de seguridad de contenido habilitada

### Producción:
- **HTTPS**: Manejado por nginx-proxy-manager
- **Cookies**: Secure via proxy, HTTP a Strapi
- **Firewall**: Solo puertos 80, 443, 22
- **Secrets**: Nunca commitear `.env`
- **Backups**: Programar backups regulares

## Recursos Adicionales

- [PRODUCTION-SETUP.md](PRODUCTION-SETUP.md) - Guía completa de producción
- [CLAUDE.md](CLAUDE.md) - Documentación para Claude Code
- [Strapi Documentation](https://docs.strapi.io/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)

## Soporte

Para problemas o preguntas:
1. Revisar [PRODUCTION-SETUP.md](PRODUCTION-SETUP.md)
2. Verificar logs: `docker compose logs strapi`
3. Consultar [Strapi Discord](https://discord.strapi.io/)
4. Revisar [Strapi GitHub Issues](https://github.com/strapi/strapi/issues)

## Licencia

Este proyecto usa Strapi Community Edition.

---

**Última actualización:** 2025-11-03
**Versión:** 1.0.0
**Estado:** ✅ Producción
