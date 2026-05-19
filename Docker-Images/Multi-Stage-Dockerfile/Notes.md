The Dockerfile has two stages:

Builder Stage – Compiles the source code and creates the JAR file.
Runtime Stage – Contains only the JAR and a minimal Java runtime.

This approach reduces image size, improves security, and speeds up deployments.