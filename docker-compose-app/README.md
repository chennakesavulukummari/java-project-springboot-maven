# Docker Compose Full Stack Application

This is a full-stack application using Docker Compose with:
- **Frontend**: Angular (served with Nginx)
- **Backend**: Python Flask API
- **Database**: PostgreSQL

## Architecture

```
┌─────────────┐
│   Angular   │ (Port 80)
│  (Nginx)    │
└──────┬──────┘
       │
       │ /api/* proxied to
       │
┌──────▼──────┐
│   Python    │ (Port 5000)
│   Flask     │
└──────┬──────┘
       │
       │
┌──────▼──────┐
│ PostgreSQL  │ (Port 5432)
└─────────────┘
```

## Prerequisites

- Docker
- Docker Compose
- Node.js and npm (for local Angular development)

## Quick Start

1. **Start all services**:
   ```bash
   cd docker-compose-app
   docker-compose up --build
   ```

2. **Access the application**:
   - Frontend: http://localhost
   - API: http://localhost:5000/api
   - Database: localhost:5432

3. **Stop all services**:
   ```bash
   docker-compose down
   ```

4. **Stop and remove volumes** (cleans database):
   ```bash
   docker-compose down -v
   ```

## API Endpoints

- `GET /api/health` - Health check
- `GET /api/users` - Get all users
- `GET /api/users/:id` - Get user by ID
- `POST /api/users` - Create a new user
- `PUT /api/users/:id` - Update a user
- `DELETE /api/users/:id` - Delete a user

## Directory Structure

```
docker-compose-app/
├── docker-compose.yml       # Main orchestration file
├── web/                     # Angular frontend
│   ├── Dockerfile
│   ├── nginx.conf
│   ├── package.json
│   ├── angular.json
│   ├── tsconfig.json
│   └── src/
│       ├── index.html
│       ├── main.ts
│       ├── styles.css
│       └── app/
│           ├── app.module.ts
│           ├── app.component.ts
│           ├── app.component.html
│           └── app.component.css
├── api/                     # Python Flask API
│   ├── Dockerfile
│   ├── requirements.txt
│   ├── app.py
│   └── .env.example
└── db/                      # PostgreSQL initialization
    └── init.sql
```

## Development

### Frontend Development

To develop the Angular app locally:

```bash
cd web
npm install
npm start
```

The app will be available at http://localhost:4200

### Backend Development

To develop the API locally:

```bash
cd api
pip install -r requirements.txt
python app.py
```

The API will be available at http://localhost:5000

### Database

The database is automatically initialized with the schema defined in `db/init.sql`.

**Connection details**:
- Host: localhost
- Port: 5432
- Database: appdb
- User: appuser
- Password: apppassword

## Environment Variables

### API Service
- `DB_HOST`: Database host (default: db)
- `DB_PORT`: Database port (default: 5432)
- `DB_NAME`: Database name (default: appdb)
- `DB_USER`: Database user (default: appuser)
- `DB_PASSWORD`: Database password (default: apppassword)
- `FLASK_ENV`: Flask environment (default: development)

### Database Service
- `POSTGRES_DB`: Database name
- `POSTGRES_USER`: Database user
- `POSTGRES_PASSWORD`: Database password

## Troubleshooting

### Database connection issues

If the API can't connect to the database, ensure:
1. The database service is healthy: `docker-compose ps`
2. Check API logs: `docker-compose logs api`
3. Check database logs: `docker-compose logs db`

### Angular build issues

If the Angular build fails:
1. Clear node_modules: `rm -rf web/node_modules`
2. Rebuild: `docker-compose build --no-cache web`

### Port conflicts

If ports are already in use:
- Change port mappings in `docker-compose.yml`
- Kill processes using the ports

## Production Considerations

For production deployment:

1. **Use environment variables** for sensitive data
2. **Update database credentials**
3. **Configure proper CORS** settings
4. **Enable HTTPS** with SSL certificates
5. **Set up proper logging**
6. **Use production build** for Angular (already configured in Dockerfile)
7. **Implement proper error handling**
8. **Set up health checks** and monitoring
9. **Use secrets management** (Docker Secrets, Kubernetes Secrets, etc.)
10. **Optimize Docker images** (multi-stage builds already implemented)

## License

MIT
