FROM tomcat:9-jdk11-openjdk-slim

# Remove default webapps
RUN rm -rf /usr/local/tomcat/webapps/*

# Copy application WAR file to Tomcat webapps directory
# COPY your-app.war /usr/local/tomcat/webapps/ROOT.war

# Expose port
EXPOSE 8080

# Start Tomcat
CMD ["catalina.sh", "run"]
