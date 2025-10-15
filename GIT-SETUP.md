# Configuración de Git y GitHub

Esta guía te ayudará a configurar Git y subir tu proyecto a GitHub/GitLab.

## Inicializar Repositorio Git

### Paso 1: Inicializar Git en tu proyecto

```bash
cd "c:\cv\Nueva carpeta"

# Inicializar repositorio
git init

# Configurar tu nombre y email (si no lo has hecho antes)
git config --global user.name "Tu Nombre"
git config --global user.email "tu-email@ejemplo.com"
```

### Paso 2: Verificar que .gitignore funciona correctamente

```bash
# Ver qué archivos se agregarán
git status

# VERIFICA que NO aparezcan estos archivos:
# - .env
# - my-strapi-project/.env
# - my-strapi-project/node_modules/
# - my-strapi-project/.tmp/
# - *.pem
```

### Paso 3: Agregar archivos

```bash
# Agregar todos los archivos (respetando .gitignore)
git add .

# Verificar qué se agregó
git status
```

### Paso 4: Crear primer commit

```bash
git commit -m "Initial commit: Strapi CMS with Docker configuration"
```

## Subir a GitHub

### Opción 1: Crear Repositorio desde GitHub Web

1. Ve a [GitHub](https://github.com) y haz login
2. Click en el botón **"New repository"** (o el ícono + arriba a la derecha)
3. Configura:
   - **Repository name**: `strapi-cms-project` (o el nombre que prefieras)
   - **Description**: "Strapi CMS with Docker setup for AWS EC2"
   - **Visibility**: Private (recomendado por los secrets)
   - **NO marques**: "Initialize this repository with a README"
4. Click en **"Create repository"**

### Opción 2: Desde tu máquina local

```bash
# Conectar con GitHub
git remote add origin https://github.com/tu-usuario/tu-repositorio.git

# Renombrar rama a main (si es necesario)
git branch -M main

# Subir código
git push -u origin main
```

Si GitHub te pide autenticación, usa un **Personal Access Token** en lugar de tu password:
1. Ve a GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Generate new token
3. Dale permisos de "repo"
4. Copia el token y úsalo como password

## Subir a GitLab

### Crear repositorio en GitLab

1. Ve a [GitLab](https://gitlab.com) y haz login
2. Click en **"New project"** → **"Create blank project"**
3. Configura:
   - **Project name**: `strapi-cms-project`
   - **Visibility Level**: Private
4. Click en **"Create project"**

### Conectar y subir

```bash
git remote add origin https://gitlab.com/tu-usuario/tu-repositorio.git
git branch -M main
git push -u origin main
```

## Verificaciones Importantes ANTES de hacer Push

### ⚠️ NUNCA subas archivos .env a Git

```bash
# Verificar que .env NO esté en el repositorio
git ls-files | grep .env

# Si aparece .env, removelo:
git rm --cached .env
git rm --cached my-strapi-project/.env
git commit -m "Remove .env files from repository"
```

### ✅ Crear .env.example (sin secrets)

```bash
cd my-strapi-project

# Copiar .env a .env.example
cp .env .env.example

# Editar .env.example y reemplazar secrets
nano .env.example
```

Reemplaza los valores reales con placeholders:

```env
# .env.example - Template sin secrets
HOST=0.0.0.0
PORT=1337
NODE_ENV=development

# Genera estos valores para producción usando: openssl rand -base64 32
APP_KEYS=key1,key2,key3,key4
API_TOKEN_SALT=your-api-token-salt
ADMIN_JWT_SECRET=your-admin-jwt-secret
TRANSFER_TOKEN_SALT=your-transfer-token-salt
ENCRYPTION_KEY=your-encryption-key
JWT_SECRET=your-jwt-secret

DATABASE_CLIENT=sqlite
DATABASE_FILENAME=.tmp/data.db
```

```bash
# Agregar .env.example al repositorio
git add .env.example
git commit -m "Add .env.example template"
git push
```

## Desplegar desde GitHub/GitLab en EC2

### Método 1: HTTPS (más fácil)

```bash
# Conectar a EC2
ssh -i tu-key.pem ubuntu@TU_EC2_IP

# Clonar repositorio
git clone https://github.com/tu-usuario/tu-repositorio.git
cd tu-repositorio
```

### Método 2: SSH (más seguro)

```bash
# En EC2, generar SSH key
ssh-keygen -t ed25519 -C "tu-email@ejemplo.com"

# Ver la key pública
cat ~/.ssh/id_ed25519.pub

# Copiar el output y agregarlo a:
# GitHub: Settings → SSH and GPG keys → New SSH key
# GitLab: Preferences → SSH Keys → Add new key

# Clonar repositorio
git clone git@github.com:tu-usuario/tu-repositorio.git
cd tu-repositorio
```

### Configurar y ejecutar en EC2

```bash
# Configurar .env
cd my-strapi-project
cp .env.example .env
nano .env  # Edita con valores de producción

# Generar secrets seguros
openssl rand -base64 32  # Ejecuta varias veces para cada secret

# Iniciar Docker Compose
cd ..
docker compose -f docker-compose.postgres.yml up -d

# Ver logs
docker compose -f docker-compose.postgres.yml logs -f
```

## Actualizar Código en Producción

### Cuando hagas cambios locales:

```bash
# En tu máquina local
git add .
git commit -m "Descripción de los cambios"
git push origin main
```

### En EC2, actualizar:

```bash
# Conectar a EC2
ssh -i tu-key.pem ubuntu@TU_EC2_IP

# Ir al directorio del proyecto
cd ~/tu-repositorio

# Obtener últimos cambios
git pull origin main

# Reconstruir y reiniciar contenedores
docker compose -f docker-compose.postgres.yml up -d --build

# Ver logs
docker compose -f docker-compose.postgres.yml logs -f strapi
```

## Comandos Git Útiles

### Ver estado del repositorio
```bash
git status
```

### Ver historial de commits
```bash
git log --oneline
```

### Ver diferencias antes de commit
```bash
git diff
```

### Descartar cambios locales
```bash
git checkout -- archivo.txt
```

### Crear rama para nuevas features
```bash
git checkout -b feature/nueva-funcionalidad
# Hacer cambios...
git add .
git commit -m "Add nueva funcionalidad"
git push origin feature/nueva-funcionalidad
```

### Fusionar rama
```bash
git checkout main
git merge feature/nueva-funcionalidad
git push origin main
```

## Estructura de Commits Recomendada

Usa mensajes de commit descriptivos:

```bash
# Buenos ejemplos:
git commit -m "Add user authentication API"
git commit -m "Fix database connection timeout"
git commit -m "Update Docker configuration for production"
git commit -m "Add nginx reverse proxy setup"

# Evita:
git commit -m "fix"
git commit -m "update"
git commit -m "changes"
```

## Archivos que NUNCA deben estar en Git

✅ Verificado por .gitignore:
- ❌ `.env` (contiene secrets)
- ❌ `*.pem` (SSH keys)
- ❌ `node_modules/` (muy pesado)
- ❌ `.tmp/` (archivos temporales)
- ❌ `*.db` (base de datos)
- ❌ Backups (`.sql`, `.dump`)

✅ Estos SÍ deberían estar:
- ✓ `.env.example` (template sin secrets)
- ✓ `docker-compose.yml`
- ✓ `Dockerfile`
- ✓ Código fuente (`src/`, `config/`)
- ✓ `package.json` y `package-lock.json`
- ✓ Documentación (`.md`)

## Troubleshooting

### Error: "remote: Support for password authentication was removed"

GitHub ya no acepta passwords. Usa un Personal Access Token:
1. GitHub → Settings → Developer settings → Personal access tokens
2. Generate new token (classic)
3. Usa el token como password

### Error: "Permission denied (publickey)"

Si usas SSH, verifica que tu key esté agregada:
```bash
ssh -T git@github.com  # Para GitHub
ssh -T git@gitlab.com  # Para GitLab
```

### Accidentalmente subiste .env con secrets

```bash
# 1. Remover del repositorio
git rm --cached .env
git commit -m "Remove .env from repository"
git push

# 2. IMPORTANTE: Regenera TODOS los secrets en producción
# porque ya fueron expuestos públicamente

# 3. Si el repositorio es público, considera eliminarlo y crear uno nuevo
```

## Recursos Adicionales

- [GitHub Docs](https://docs.github.com)
- [GitLab Docs](https://docs.gitlab.com)
- [Git Cheat Sheet](https://education.github.com/git-cheat-sheet-education.pdf)
- [Atlassian Git Tutorial](https://www.atlassian.com/git/tutorials)
