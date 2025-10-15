You are helping deploy this Strapi application to production.

**Task**: Guide the deployment process with a checklist and best practices.

**Pre-deployment Checklist**:
1. ✅ Build admin panel: `npm run build`
2. ✅ Set NODE_ENV=production
3. ✅ Configure production database (PostgreSQL recommended)
4. ✅ Generate strong secrets for .env
5. ✅ Configure upload provider (local/S3/Cloudinary)
6. ✅ Set up email provider if needed
7. ✅ Configure CORS for frontend domain
8. ✅ Enable security headers
9. ✅ Test production build locally

**Deployment Options**:
- Strapi Cloud (easiest): `npm run deploy`
- Docker/Docker Compose
- VPS (Ubuntu/Debian with PM2)
- PaaS (Heroku, Railway, Render)
- Serverless (AWS Lambda - requires adaptation)

**Post-deployment**:
1. Run database migrations
2. Seed initial data if needed
3. Create admin user
4. Configure roles and permissions
5. Test API endpoints
6. Set up monitoring
7. Configure backups

Ask the user which deployment method they prefer and guide them through the specific steps.
