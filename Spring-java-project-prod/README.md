# CI/CD Pipeline Configuration Guide

This GitHub Actions workflow automates the build and deployment process for the datastore application. This document explains how to configure all required secrets and environment variables.

## Overview


The pipeline performs the following steps:
1. Checkout source code
2. Setup Java 17
3. Run SonarQube analysis
4. Build JAR file
5. Upload JAR to EC2
6. Stop existing application
7. Deploy and run new application on EC2

## Required GitHub Secrets

GitHub Secrets are sensitive values that must be configured in your repository settings. Navigate to **Settings → Secrets and variables → Actions** to add these secrets.

### 1. **SONAR_TOKEN**
- **Description**: Authentication token for SonarQube analysis
- **How to get it**:
  - Log in to your SonarQube server
  - Go to **My Account → Security → Tokens**
  - Generate a new token (e.g., "GitHub-Actions")
  - Copy the token value
- **Example**: `squ_1a2b3c4d5e6f7g8h9i0j1k2l3m4n5o6p`
- **Used in**: SonarQube Scan step

### 2. **SONAR_URL**
- **Description**: URL of your SonarQube server instance
- **Format**: `http://publicip:9000` or `https://your-sonarqube-domain.com`
- **Example**: `http://publicip:9000`
- **Used in**: SonarQube Scan step




## Step-by-Step Configuration

### Step 1: Add SonarQube Secrets
1. Go to your GitHub repository
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add `SONAR_TOKEN`:
   - Name: `SONAR_TOKEN`
   - Value: Your SonarQube token
5. Add `SONAR_URL`:
   - Name: `SONAR_URL`
   - Value: Your SonarQube URL (e.g., `https://sonar.example.com`)

### Step 2: Add EC2 Secrets
1. Click **New repository secret**
2. Add `EC2_HOST`:
   - Name: `EC2_HOST`
   - Value: Your EC2 public IP or hostname
3. Add `EC2_KEY`:
   - Name: `EC2_KEY`
   - Value: The entire content of your `.pem` file

### Step 3: Update Database Configuration
1. Open `main.yaml` in the repository
2. Find the "Run Application on EC2" step
3. Update the database connection string with your RDS details
4. Commit and push the changes

## Verifying the Configuration

### Test SonarQube Connection
Push a commit to the `main` branch and check the workflow logs:
- Go to **Actions** tab
- Click on the latest workflow run
- Look for the "Sonar Scan" step
- Verify it completes without authentication errors

### Test EC2 Connection
Check the workflow logs for:
- "Upload JAR to EC2" step should complete successfully
- "Run Application on EC2" step should show "🚀 New Application Started"

If there are connection errors:
- Verify `EC2_HOST` is correct and reachable
- Verify `EC2_KEY` is properly formatted with line breaks preserved
- Ensure EC2 security group allows inbound SSH (port 22)
- Ensure database RDS security group allows inbound traffic on port 3306

 ### Docker compose installation 

 
 sudo curl -L "https://github.com/docker/compose/releases/download/v2.29.2/docker-compose-$(uname -s)-$(uname -m)" \
  -o /usr/local/bin/docker-compose
  
sudo chmod +x /usr/local/bin/docker-compose

docker-compose --version



