# ------------------------------------------------------------------------------
# Enterprise Multi-Stage Dockerfile for Java Spring Boot Application
# ------------------------------------------------------------------------------
# Features:
# - Multi-stage build (builder + runtime)
# - Maven dependency caching
# - Non-root execution
# - Minimal runtime image
# - Health check
# - Metadata labels
# - JVM tuning options
# - Production-ready security practices
# ------------------------------------------------------------------------------

# =========================
# Stage 1: Build Stage
# =========================
FROM maven:3.9.9-eclipse-temurin-17 AS builder

# Build arguments
ARG APP_NAME=my-enterprise-app
ARG APP_VERSION=1.0.0

# Working directory
WORKDIR /build

# Copy only pom.xml first to leverage Docker layer caching
COPY pom.xml .

# Download dependencies (cached unless pom.xml changes)
RUN mvn -B dependency:go-offline

# Copy source code
COPY src ./src

# Build application
RUN mvn -B clean package -DskipTests

# =========================
# Stage 2: Runtime Stage
# =========================
FROM eclipse-temurin:17-jre-jammy AS runtime

# OCI Labels
LABEL org.opencontainers.image.title="Enterprise Spring Boot Application" \
      org.opencontainers.image.description="Production-ready Docker image for Spring Boot" \
      org.opencontainers.image.vendor="c3ops technologies private limited" \
      org.opencontainers.image.version="${APP_VERSION}"

# Build arguments (redeclare in this stage if used here)
ARG APP_NAME=my-enterprise-app
ARG APP_VERSION=1.0.0

# Environment variables
ENV APP_HOME=/opt/${APP_NAME} \
    JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -Djava.security.egd=file:/dev/./urandom" \
    TZ=Asia/Kolkata

# Create non-root user and group
RUN groupadd --system appgroup && \
    useradd --system --gid appgroup --create-home --home-dir ${APP_HOME} appuser

# Set working directory
WORKDIR ${APP_HOME}

# Copy application artifact from builder stage
COPY --from=builder /build/target/*.jar app.jar

# Adjust ownership
RUN chown -R appuser:appgroup ${APP_HOME}

# Expose application port
EXPOSE 8080

# Optional health check (works if Spring Boot Actuator is enabled)
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/actuator/health || exit 1

# Switch to non-root user
USER appuser

# Graceful shutdown support
STOPSIGNAL SIGTERM

# Entry point
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]