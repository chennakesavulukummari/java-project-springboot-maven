# Sample Tomcat App

A simple Spring Boot 3.2.0 web application configured for deployment on Apache Tomcat 10.x with Java 17.

## Project Details

- **Java Version**: 17 (LTS)
- **Spring Boot Version**: 3.2.0
- **Packaging**: WAR (Web Archive)
- **Target Tomcat Version**: 10.1.x

## Build

```bash
cd sample-tomcat-app
mvn clean package
```

This will generate `target/sample-app.war`

## Deployment to Tomcat

### Step 1: Copy WAR file to Tomcat
```bash
cp target/sample-app.war /path/to/tomcat/webapps/
```

### Step 2: Restart Tomcat
```bash
# Stop Tomcat
/path/to/tomcat/bin/catalina.sh stop

# Remove old deployment (optional but recommended)
rm -rf /path/to/tomcat/webapps/sample-app*

# Copy WAR file again
cp target/sample-app.war /path/to/tomcat/webapps/

# Start Tomcat
/path/to/tomcat/bin/catalina.sh start
```

### Step 3: Wait for deployment
Wait 10-15 seconds for Tomcat to extract and start the application.

### Step 4: Verify deployment
```bash
# Check Tomcat logs
tail -f /path/to/tomcat/logs/catalina.out

# Access the application
curl http://localhost:8080/sample-app/
curl http://localhost:8080/sample-app/health
curl http://localhost:8080/sample-app/api/message
```

## API Endpoints

- `GET /sample-app/` - Home page
- `GET /sample-app/health` - Health check
- `GET /sample-app/api/message` - JSON message

## Troubleshooting

### 404 Error
- Check that WAR file is in `webapps/` folder
- Verify Tomcat logs for startup errors
- Make sure Tomcat is using Java 17 or higher

### Check Java version on Tomcat
```bash
echo $JAVA_HOME
java -version
```

### View Tomcat logs
```bash
tail -100f /path/to/tomcat/logs/catalina.out
tail -100f /path/to/tomcat/logs/catalina.YYYY-MM-DD.log
```

### Force redeploy
```bash
rm -rf /path/to/tomcat/webapps/sample-app*
cp target/sample-app.war /path/to/tomcat/webapps/
```

## Directory Structure

```
sample-tomcat-app/
├── pom.xml
├── README.md
└── src/
    └── main/
        ├── java/
        │   └── com/example/
        │       └── Application.java
        ├── resources/
        │   └── application.properties
        └── webapp/
            └── WEB-INF/
                └── web.xml
```

## Notes

- The context path is `/sample-app` (configurable in `application.properties`)
- Requires Java 17 or higher on Tomcat
- Compatible with Tomcat 10.x and later
- Spring Boot is configured to run as WAR (not embedded Tomcat)
