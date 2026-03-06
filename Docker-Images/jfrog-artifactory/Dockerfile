FROM docker.bintray.io/jfrog/artifactory-oss:latest

# Set environment variables
ENV ARTIFACTORY_HOME=/opt/jfrog/artifactory
ENV ARTIFACTORY_DATA=/var/opt/jfrog/artifactory

# Expose ports
EXPOSE 8081 8082

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:8082/artifactory/api/system/ping || exit 1

# Start Artifactory
CMD ["/entrypoint-artifactory.sh"]
