# Spring Boot MySQL Web Application

A RESTful web application built with **Spring Boot**, **Java 17**, **MySQL**, and **Maven**.

## Project Structure

```
src/main/java/com/example/
├── Application.java                  # Main entry point
├── controller/
│   ├── HealthController.java         # Root endpoint
│   └── UserController.java           # User CRUD REST API
├── dto/
│   └── UserDto.java                  # Data Transfer Object
├── exception/
│   ├── DuplicateResourceException.java
│   ├── GlobalExceptionHandler.java   # Centralized error handling
│   └── ResourceNotFoundException.java
├── model/
│   └── User.java                     # JPA Entity
├── repository/
│   └── UserRepository.java           # Spring Data JPA Repository
└── service/
    └── UserService.java              # Business logic
```

## Prerequisites

- **Java 17** or later
- **Maven 3.8+**
- **MySQL 8.0+**

## Database Setup

1. Start MySQL and create the database:

```sql
CREATE DATABASE springboot_db;
```

2. Update credentials in `src/main/resources/application.properties` if needed:

```properties
spring.datasource.url=jdbc:mysql://localhost:3306/springboot_db
spring.datasource.username=root
spring.datasource.password=root
```

## Build & Run

```bash
# Build the project
mvn clean install

# Run the application
mvn spring-boot:run
```

The application starts at **http://localhost:8080**.

## API Endpoints

| Method   | Endpoint          | Description         |
|----------|-------------------|---------------------|
| `GET`    | `/`               | App status          |
| `GET`    | `/api/users`      | Get all users       |
| `GET`    | `/api/users/{id}` | Get user by ID      |
| `POST`   | `/api/users`      | Create a new user   |
| `PUT`    | `/api/users/{id}` | Update a user       |
| `DELETE` | `/api/users/{id}` | Delete a user       |

### Sample Request — Create User

```bash
curl -X POST http://localhost:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{
    "firstName": "John",
    "lastName": "Doe",
    "email": "john.doe@example.com",
    "phone": "+1234567890"
  }'
```

### Sample Request — Get All Users

```bash
curl http://localhost:8080/api/users
```

## Running Tests

```bash
mvn test
```

Tests use an **H2 in-memory database** so MySQL is not required for testing.

## Actuator Endpoints

| Endpoint                         | Description        |
|----------------------------------|--------------------|
| `GET /actuator/health`           | Health check       |
| `GET /actuator/info`             | App info           |
| `GET /actuator/metrics`          | Metrics            |

## Tech Stack

| Component   | Technology              |
|-------------|-------------------------|
| Framework   | Spring Boot 3.2.5       |
| Language    | Java 17                 |
| Database    | MySQL 8                 |
| ORM         | Spring Data JPA         |
| Build Tool  | Maven                   |
| Testing     | JUnit 5, MockMvc, H2   |



# Major Container Runtimes:

Docker Engine – The most popular runtime for developers, supports OCI images.

Podman – Rootless, daemonless runtime from Red Hat, focused on security.

containerd – Industry-standard runtime, originally from Docker, now part of CNCF.

CRI-O – Lightweight runtime designed specifically for Kubernetes.

rkt (Rocket) – Developed by CoreOS (now deprecated, but historically important).

LXC/LXD – Linux Containers project, closer to lightweight VMs than app containers.
