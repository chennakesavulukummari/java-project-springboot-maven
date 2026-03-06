FROM mysql:8.0

# Set environment variables
ENV MYSQL_ROOT_PASSWORD=rootpassword \
    MYSQL_DATABASE=appdb \
    MYSQL_USER=appuser \
    MYSQL_PASSWORD=apppassword

# Copy custom MySQL configuration if needed
# COPY ./my.cnf /etc/mysql/conf.d/custom.cnf

# Copy initialization scripts
# COPY ./init-scripts/ /docker-entrypoint-initdb.d/

# Expose port
EXPOSE 3306

# Volume for data persistence
VOLUME ["/var/lib/mysql"]

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD mysqladmin ping -h localhost -u root -p$MYSQL_ROOT_PASSWORD || exit 1
