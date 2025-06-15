# Railway Deployment Checklist

## Pre-deployment Checklist
- [ ] Code is committed to a GitHub repository
- [ ] All sensitive data is moved to environment variables
- [ ] Database migrations are ready
- [ ] Frontend assets are properly configured for production build

## Railway Setup Steps

### 1. Create Railway Account
- Go to [railway.app](https://railway.app)
- Sign up or login with GitHub

### 2. Create New Project
- Click "New Project"
- Select "Deploy from GitHub repo"
- Choose your repository
- Railway will automatically detect it's a Laravel project

### 3. Add MySQL Database
- In your Railway dashboard, click "New"
- Select "Database" → "MySQL"
- Railway will automatically provide connection variables

### 4. Configure Environment Variables
In your app service settings, add these variables:

**Required:**
```
APP_NAME=Your App Name
APP_ENV=production
APP_DEBUG=false
APP_URL=https://your-generated-domain.up.railway.app
```

**Optional (if using):**
```
MAIL_MAILER=smtp
MAIL_HOST=your-smtp-host
MAIL_PORT=587
MAIL_USERNAME=your-email
MAIL_PASSWORD=your-password
MAIL_ENCRYPTION=tls
MAIL_FROM_ADDRESS=noreply@yourdomain.com
```

### 5. Custom Domain (Optional)
- In Railway dashboard, go to your app service
- Click "Settings" → "Domains"
- Add your custom domain and configure DNS

### 6. Deploy
- Railway will automatically build and deploy
- Check the deployment logs for any issues
- Visit your app URL to verify deployment

## Post-deployment
- [ ] Test all major functionality
- [ ] Verify database connections
- [ ] Check email functionality (if configured)
- [ ] Monitor application logs
- [ ] Set up any additional monitoring/alerting

## Troubleshooting

**Common Issues:**
1. **Build fails:** Check the build logs, usually missing dependencies
2. **App won't start:** Check environment variables, especially APP_KEY
3. **Database connection fails:** Verify MySQL service is running and variables are set
4. **Assets not loading:** Check that `npm run build` completed successfully

**Useful Railway CLI Commands:**
```bash
# Install Railway CLI
npm install -g @railway/cli

# Login
railway login

# Link to project
railway link

# View logs
railway logs

# Open shell
railway shell
```
