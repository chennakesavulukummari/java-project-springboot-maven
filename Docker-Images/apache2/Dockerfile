FROM ubuntu:22.04

# Install Apache2
RUN apt-get update && \
    apt-get install -y apache2 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Enable Apache modules
RUN a2enmod rewrite ssl headers

# Copy custom configuration if needed
# COPY ./apache2.conf /etc/apache2/apache2.conf
# COPY ./sites-available/ /etc/apache2/sites-available/

# Copy website files from dist directory
COPY dist/ /var/www/html/

# Expose ports
EXPOSE 80 443

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -f http://localhost/ || exit 1

# Start Apache2 in foreground
CMD ["apachectl", "-D", "FOREGROUND"]

# docker build -t kesavkummari/apache2:20260404 \
# --build-context dist=/Users/ck/gitrepo/cloud-mastery-nexus/dist \
# -f /Users/ck/github-repos/java-project-springboot-maven/Docker-Images/apache2/Dockerfile \
# /Users/ck/github-repos/java-project-springboot-maven/Docker-Images/apache2

# cp -r /Users/ck/gitrepo/cloud-mastery-nexus/dist /Users/ck/github-repos/java-project-springboot-maven/Docker-Images/apache2/dist

# docker build -t kesavkummari/cloudbinarywebsite:20260404 /Users/ck/github-repos/java-project-springboot-maven/Docker-Images/apache2

# cd /Users/ck/github-repos/java-project-springboot-maven/Docker-Images/apache2/
# docker build -t kesavkummari/cloudbinarywebsite:20260404-x86 --platform linux/amd64 .
# docker push kesavkummari/cloudbinarywebsite:20260404-x86

# # Then update deployment
# kubectl set image deployment/cloudbinary-website cloudbinary-website=kesavkummari/cloudbinarywebsite:20260404-x86 -n cloudbinary-website