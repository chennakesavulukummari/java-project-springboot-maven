FROM sonarqube:latest

# Set environment variables
ENV SONAR_JDBC_URL="" \
    SONAR_JDBC_USERNAME="" \
    SONAR_JDBC_PASSWORD=""

# Expose port
EXPOSE 9000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
  CMD curl -f http://localhost:9000/api/system/status || exit 1

# Volume for data persistence
VOLUME ["/opt/sonarqube/data", "/opt/sonarqube/extensions", "/opt/sonarqube/logs"]
