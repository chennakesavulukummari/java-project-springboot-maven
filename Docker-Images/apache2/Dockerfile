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

# Copy website files
# COPY ./public-html/ /var/www/html/

# Expose ports
EXPOSE 80 443

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -f http://localhost/ || exit 1

# Start Apache2 in foreground
CMD ["apachectl", "-D", "FOREGROUND"]
