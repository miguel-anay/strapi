# Strapi CMS - Docker Setup

Este proyecto contiene una aplicación Strapi CMS v5.27.0 configurada para ejecutarse con Docker.

## Estado del Proyecto

✅ **Contenedor ejecutándose correctamente**
- Strapi está disponible en: http://localhost:1337
- Panel de administración: http://localhost:1337/admin
- API endpoints: http://localhost:1337/api

## Configuraciones Disponibles

### 1. Desarrollo con SQLite (Recomendado para desarrollo local)

Usa el archivo `docker-compose.yml` con base de datos SQLite integrada.

**Iniciar:**
```bash
docker-compose up -d
```

**Ver logs:**
```bash
docker-compose logs -f strapi
```

**Detener:**
```bash
docker-compose down
```

### 2. Producción con PostgreSQL

Usa el archivo `docker-compose.postgres.yml` con base de datos PostgreSQL separada.

**Iniciar:**
```bash
docker-compose -f docker-compose.postgres.yml up -d
```

**Ver logs:**
```bash
docker-compose -f docker-compose.postgres.yml logs -f
```

**Detener:**
```bash
docker-compose -f docker-compose.postgres.yml down
```

## Desarrollo Local (Sin Docker)

Si prefieres ejecutar Strapi sin Docker:

```bash
cd my-strapi-project
npm install
npm run develop
```

## Estructura del Proyecto

```
.
├── my-strapi-project/          # Código fuente de Strapi
│   ├── config/                 # Configuración (database, server, etc.)
│   ├── src/                    # APIs, components, extensiones
│   ├── public/                 # Archivos estáticos
│   ├── scripts/                # Scripts de utilidad (seed, etc.)
│   ├── .env                    # Variables de entorno
│   ├── Dockerfile              # Imagen Docker de Strapi
│   └── package.json            # Dependencias del proyecto
│
├── docker-compose.yml          # Docker Compose - SQLite (desarrollo)
├── docker-compose.postgres.yml # Docker Compose - PostgreSQL (producción)
└── CLAUDE.md                   # Documentación para Claude Code
```

## Variables de Entorno

Las variables de entorno se configuran en `my-strapi-project/.env`:

- `HOST`: Host del servidor (default: 0.0.0.0)
- `PORT`: Puerto del servidor (default: 1337)
- `DATABASE_CLIENT`: Tipo de base de datos (sqlite/postgres/mysql)
- `APP_KEYS`: Claves de encriptación para sesiones
- Security tokens: `API_TOKEN_SALT`, `ADMIN_JWT_SECRET`, etc.

## Comandos Útiles

### Reconstruir contenedores
```bash
docker-compose up -d --build
```

### Acceder al shell del contenedor
```bash
docker-compose exec strapi sh
```

### Ver estado de contenedores
```bash
docker-compose ps
```

### Ejecutar seed script
```bash
cd my-strapi-project
npm run seed:example
```

## Primer Uso

1. Inicia el contenedor:
   ```bash
   docker-compose up -d
   ```

2. Espera a que Strapi esté listo (30-60 segundos la primera vez)

3. Abre tu navegador en: http://localhost:1337/admin

4. Crea tu primer usuario administrador

## Problemas Comunes

### El contenedor no inicia
```bash
# Ver logs detallados
docker-compose logs strapi

# Reconstruir desde cero
docker-compose down
docker-compose up -d --build
```

### Puerto 1337 en uso
Cambia el puerto en `docker-compose.yml`:
```yaml
ports:
  - "3000:1337"  # Usar puerto 3000 en lugar de 1337
```

### Problemas con node_modules
```bash
cd my-strapi-project
rm -rf node_modules package-lock.json
npm install
```

## Persistencia de Datos

- **SQLite**: Los datos se guardan en `my-strapi-project/.tmp/data.db`
- **PostgreSQL**: Los datos se guardan en el volumen Docker `postgres-data`
- **Uploads**: Los archivos subidos se guardan en `my-strapi-project/public/uploads`

## Tecnologías

- **Strapi**: v5.27.0
- **Node.js**: v20 Alpine
- **Database**: SQLite (dev) / PostgreSQL 16 (prod)
- **TypeScript**: v5
- **React**: v18
