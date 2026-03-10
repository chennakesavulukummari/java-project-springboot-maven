# Docker Compose Application Architecture

## System Architecture Diagram

```mermaid
graph TB
    subgraph "Docker Compose Network: app-network"
        subgraph "Web Layer - Port 80"
            WEB[Angular Frontend<br/>+ Nginx<br/>Container: angular_web]
        end
        
        subgraph "API Layer - Port 5000"
            API[Python Flask API<br/>Container: python_api]
        end
        
        subgraph "Data Layer - Port 5432"
            DB[(PostgreSQL 15<br/>Container: postgres_db)]
            VOL[Volume: postgres_data]
        end
    end
    
    USER[User Browser] -->|HTTP :80| WEB
    WEB -->|Proxy /api/*| API
    API -->|psycopg2| DB
    DB -.->|Persists to| VOL
    
    style WEB fill:#61dafb,stroke:#333,stroke-width:2px,color:#000
    style API fill:#3776ab,stroke:#333,stroke-width:2px,color:#fff
    style DB fill:#336791,stroke:#333,stroke-width:2px,color:#fff
    style VOL fill:#ffd700,stroke:#333,stroke-width:2px,color:#000
    style USER fill:#90EE90,stroke:#333,stroke-width:2px,color:#000
```

## Container Dependency Flow

```mermaid
flowchart LR
    START([Docker Compose Up]) --> DB_START[Start PostgreSQL]
    DB_START --> DB_HEALTH{Database<br/>Health Check}
    DB_HEALTH -->|Ready| API_START[Start Flask API]
    API_START --> API_INIT[Initialize DB Schema]
    API_INIT --> WEB_START[Start Angular/Nginx]
    WEB_START --> READY([Application Ready])
    DB_HEALTH -->|Retry| DB_HEALTH
    
    style START fill:#90EE90,stroke:#333,stroke-width:2px
    style READY fill:#90EE90,stroke:#333,stroke-width:2px
    style DB_HEALTH fill:#FFD700,stroke:#333,stroke-width:2px
```

## Request Flow - User Creates a New User

```mermaid
sequenceDiagram
    participant U as User Browser
    participant N as Nginx
    participant A as Angular App
    participant F as Flask API
    participant P as PostgreSQL
    
    U->>N: GET http://localhost/
    N->>U: Return index.html + Angular bundle
    
    U->>A: Load Angular Application
    A->>N: GET /api/users
    N->>F: Proxy to http://api:5000/api/users
    F->>P: SELECT * FROM users
    P->>F: Return user rows
    F->>N: JSON response
    N->>A: User list
    A->>U: Display users
    
    U->>A: Fill form & click "Add User"
    A->>N: POST /api/users {name, email}
    N->>F: Proxy to http://api:5000/api/users
    F->>P: INSERT INTO users (name, email) VALUES (...)
    P->>F: Return new user with ID
    F->>N: JSON response (201 Created)
    N->>A: New user data
    A->>U: Update UI with new user
```

## Data Flow Architecture

```mermaid
graph LR
    subgraph "Frontend - Angular"
        UI[User Interface]
        HTTP[HTTP Client]
        COMP[Components]
    end
    
    subgraph "Backend - Flask"
        ROUTES[API Routes]
        LOGIC[Business Logic]
        CONN[DB Connection Pool]
    end
    
    subgraph "Database - PostgreSQL"
        SCHEMA[users Table]
        DATA[(Data Storage)]
    end
    
    UI --> COMP
    COMP --> HTTP
    HTTP -->|REST API| ROUTES
    ROUTES --> LOGIC
    LOGIC --> CONN
    CONN -->|SQL Queries| SCHEMA
    SCHEMA --> DATA
    
    style UI fill:#61dafb,stroke:#333,stroke-width:2px
    style ROUTES fill:#3776ab,stroke:#333,stroke-width:2px,color:#fff
    style SCHEMA fill:#336791,stroke:#333,stroke-width:2px,color:#fff
```

## Docker Compose Services Overview

```mermaid
graph TB
    subgraph "docker-compose.yml"
        DC[Docker Compose]
    end
    
    subgraph "Services"
        WEB_SVC[web service<br/>build: ./web]
        API_SVC[api service<br/>build: ./api]
        DB_SVC[db service<br/>image: postgres:15-alpine]
    end
    
    subgraph "Networks"
        NET[app-network<br/>driver: bridge]
    end
    
    subgraph "Volumes"
        VOL[postgres_data<br/>driver: local]
    end
    
    DC --> WEB_SVC
    DC --> API_SVC
    DC --> DB_SVC
    DC --> NET
    DC --> VOL
    
    WEB_SVC -.->|uses| NET
    API_SVC -.->|uses| NET
    DB_SVC -.->|uses| NET
    DB_SVC -.->|mounts| VOL
    
    style DC fill:#2496ed,stroke:#333,stroke-width:3px,color:#fff
    style NET fill:#ff9900,stroke:#333,stroke-width:2px
    style VOL fill:#ffd700,stroke:#333,stroke-width:2px
```

## Technology Stack

```mermaid
mindmap
  root((Docker Compose<br/>Full Stack App))
    Frontend
      Angular 17
      TypeScript
      RxJS
      HTTP Client
      Nginx Alpine
    Backend
      Python 3.11
      Flask 3.0
      Flask-CORS
      psycopg2
    Database
      PostgreSQL 15
      Alpine Linux
      Persistent Volume
    DevOps
      Docker
      Docker Compose
      Multi-stage Builds
      Health Checks
```

## Deployment Lifecycle

```mermaid
stateDiagram-v2
    [*] --> Building: docker-compose up --build
    
    Building --> ImageCreation: Build Dockerfiles
    ImageCreation --> NetworkSetup: Create app-network
    NetworkSetup --> VolumeSetup: Create postgres_data volume
    
    VolumeSetup --> StartDB: Start PostgreSQL container
    StartDB --> DBHealthCheck: Run health checks
    DBHealthCheck --> DBReady: pg_isready success
    DBHealthCheck --> DBHealthCheck: Retry (5 attempts)
    
    DBReady --> StartAPI: Start Flask API container
    StartAPI --> InitSchema: Create users table
    InitSchema --> APIReady: API listening on :5000
    
    APIReady --> StartWeb: Start Angular/Nginx container
    StartWeb --> WebReady: Nginx listening on :80
    
    WebReady --> Running: All services healthy
    Running --> [*]: docker-compose down
```

## Port Mappings & Service Communication

```mermaid
graph LR
    subgraph "Host Machine"
        P80[Port 80]
        P5000[Port 5000]
        P5432[Port 5432]
    end
    
    subgraph "Docker Network: app-network"
        WEB[Web Container<br/>Internal: 80]
        API[API Container<br/>Internal: 5000]
        DB[DB Container<br/>Internal: 5432]
    end
    
    P80 -->|Maps to| WEB
    P5000 -->|Maps to| API
    P5432 -->|Maps to| DB
    
    WEB -->|http://api:5000| API
    API -->|postgresql://db:5432| DB
    
    style P80 fill:#90EE90,stroke:#333,stroke-width:2px
    style P5000 fill:#FFD700,stroke:#333,stroke-width:2px
    style P5432 fill:#87CEEB,stroke:#333,stroke-width:2px
```

## API Endpoints Overview

```mermaid
graph TB
    API[Flask API Server<br/>http://localhost:5000]
    
    API --> HEALTH[GET /api/health<br/>Health check endpoint]
    API --> GET_USERS[GET /api/users<br/>List all users]
    API --> GET_USER[GET /api/users/:id<br/>Get specific user]
    API --> CREATE[POST /api/users<br/>Create new user]
    API --> UPDATE[PUT /api/users/:id<br/>Update user]
    API --> DELETE[DELETE /api/users/:id<br/>Delete user]
    
    style API fill:#3776ab,stroke:#333,stroke-width:3px,color:#fff
    style HEALTH fill:#90EE90,stroke:#333,stroke-width:2px
    style GET_USERS fill:#61dafb,stroke:#333,stroke-width:2px
    style GET_USER fill:#61dafb,stroke:#333,stroke-width:2px
    style CREATE fill:#FFD700,stroke:#333,stroke-width:2px
    style UPDATE fill:#FFA500,stroke:#333,stroke-width:2px
    style DELETE fill:#FF6347,stroke:#333,stroke-width:2px
```

## Database Schema

```mermaid
erDiagram
    USERS {
        serial id PK "Primary Key, Auto-increment"
        varchar name "User full name (100 chars)"
        varchar email UK "Unique email address (100 chars)"
        timestamp created_at "Record creation timestamp"
    }
```

## Error Handling Flow

```mermaid
flowchart TD
    START[Request Received] --> VALIDATE{Valid<br/>Input?}
    VALIDATE -->|No| ERR400[Return 400<br/>Bad Request]
    VALIDATE -->|Yes| PROCESS[Process Request]
    
    PROCESS --> DB_CONN{DB<br/>Connected?}
    DB_CONN -->|No| ERR503[Return 503<br/>Service Unavailable]
    DB_CONN -->|Yes| EXECUTE[Execute Query]
    
    EXECUTE --> CHECK{Success?}
    CHECK -->|Duplicate Email| ERR409[Return 409<br/>Conflict]
    CHECK -->|Not Found| ERR404[Return 404<br/>Not Found]
    CHECK -->|Error| ERR500[Return 500<br/>Internal Error]
    CHECK -->|Success| SUCCESS[Return 200/201<br/>With Data]
    
    style ERR400 fill:#FF6347,stroke:#333,stroke-width:2px
    style ERR404 fill:#FF8C00,stroke:#333,stroke-width:2px
    style ERR409 fill:#FFD700,stroke:#333,stroke-width:2px
    style ERR500 fill:#DC143C,stroke:#333,stroke-width:2px
    style ERR503 fill:#8B0000,stroke:#333,stroke-width:2px,color:#fff
    style SUCCESS fill:#90EE90,stroke:#333,stroke-width:2px
```
