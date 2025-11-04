# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository contains a Strapi 5.27.0 CMS application built with TypeScript and Node.js. The project includes Docker configurations for both development and production deployments.

## Architecture

The project uses a monorepo structure with:
- **my-strapi-project/**: Main Strapi application source code
  - **config/**: Configuration files (database, server, admin, middlewares)
  - **src/**: Application source code (API, components, extensions)
  - **public/**: Static assets
  - **scripts/**: Utility scripts (e.g., seed data)
- **Docker Compose**: Two configurations available
  - `docker-compose.yml`: Development setup with SQLite
  - `docker-compose.postgres.yml`: Production setup with PostgreSQL

## Essential Commands

### Local Development (without Docker)
```bash
cd my-strapi-project
npm install
npm run develop      # Start with hot-reload
npm run build        # Build admin panel
npm run start        # Start production server
```

### Docker Development (SQLite)
```bash
docker-compose up -d --build      # Build and start
docker-compose logs -f strapi     # View logs
docker-compose down               # Stop
```

### Docker Production (PostgreSQL)
```bash
docker-compose -f docker-compose.postgres.yml up -d --build
docker-compose -f docker-compose.postgres.yml logs -f strapi
docker-compose -f docker-compose.postgres.yml down
```

### Access Container Shell
```bash
docker-compose exec strapi sh
```

### Run Seed Script
```bash
cd my-strapi-project
npm run seed:example
```

## Database Configuration

The application supports multiple database options configured in [my-strapi-project/config/database.ts](my-strapi-project/config/database.ts):

- **SQLite** (default for development): Database stored in `.tmp/data.db`
- **PostgreSQL**: Configured via environment variables
- **MySQL**: Configurable via environment variables

Switch databases by modifying `DATABASE_CLIENT` in [my-strapi-project/.env](my-strapi-project/.env).

## Environment Variables

Key variables in [my-strapi-project/.env](my-strapi-project/.env):
- `HOST`: Server host (default: 0.0.0.0)
- `PORT`: Server port (default: 1337)
- `DATABASE_CLIENT`: Database type (sqlite/postgres/mysql)
- `APP_KEYS`: Encryption keys for sessions
- `API_TOKEN_SALT`, `ADMIN_JWT_SECRET`, etc.: Security tokens
- `PUBLIC_URL`: Public URL for the application (for reverse proxy setup)
- `ADMIN_COOKIE_SECURE`: Set to `false` when behind a reverse proxy

**Note**: Never commit the `.env` file. Use `.env.example` as a template.

## Reverse Proxy Configuration

This project is configured to work with reverse proxies like nginx-proxy-manager:

- [my-strapi-project/config/server.ts](my-strapi-project/config/server.ts): Has `proxy: true` enabled
- Cookie security is configurable via `ADMIN_COOKIE_SECURE` environment variable
- See [PRODUCTION-SETUP.md](PRODUCTION-SETUP.md) for complete nginx-proxy-manager configuration

**Important**: Keep `ADMIN_COOKIE_SECURE=false` when using a reverse proxy to avoid error 500 on login.

## Technology Stack

- **Strapi**: v5.27.0 (Headless CMS)
- **Node.js**: v18-22 (see engines in package.json)
- **TypeScript**: v5
- **Database**: SQLite (dev) / PostgreSQL (prod)
- **React**: v18 (for admin panel)
- **Docker**: Multi-stage builds with Alpine Linux

## Accessing Strapi

Once running:
- Admin panel: http://localhost:1337/admin
- API endpoints: http://localhost:1337/api
- Documentation: http://localhost:1337/documentation (if enabled)

## Docker Volume Mounts

Development volumes for hot-reload:
- `./my-strapi-project/config` → `/opt/app/config`
- `./my-strapi-project/src` → `/opt/app/src`
- `./my-strapi-project/public` → `/opt/app/public`

Production volumes persist:
- SQLite database (`.tmp/` directory)
- PostgreSQL data (named volume `postgres-data`)
- Uploaded files (`strapi-uploads` volume)

## Deployment to AWS EC2

### Production with Nginx Proxy Manager

For production deployment with reverse proxy (nginx-proxy-manager):
- See [PRODUCTION-SETUP.md](PRODUCTION-SETUP.md) for complete setup guide
- Includes nginx-proxy-manager configuration
- Fixes error 500 on admin login
- SSL/HTTPS configuration

### Quick Transfer (if Docker is already installed on EC2)

1. **Edit the transfer script** [transfer-to-ec2.sh](transfer-to-ec2.sh):
   - Set your EC2 IP address
   - Set your .pem key file path

2. **Run the script**:
   ```bash
   chmod +x transfer-to-ec2.sh
   ./transfer-to-ec2.sh
   ```

3. **Configure environment variables** on EC2:
   ```bash
   ssh -i key.pem ubuntu@EC2_IP
   cd ~/my-strapi-project
   nano .env  # Update production secrets
   # Add: PUBLIC_URL=https://your-domain.com
   # Add: ADMIN_COOKIE_SECURE=false
   ```

4. **Start Docker Compose**:
   ```bash
   cd ~
   docker compose up -d --build
   ```

See [QUICK-EC2-DEPLOY.md](QUICK-EC2-DEPLOY.md) for detailed steps.

### Full EC2 Setup (from scratch)

For complete EC2 setup including Docker installation, Nginx, and SSL, see [EC2-DEPLOYMENT.md](EC2-DEPLOYMENT.md).
