# Notes & Task Management App

A production-style, offline-first Notes & Task management application:
a Node.js/Express/MySQL REST backend and a Flutter (Riverpod, Clean
Architecture) client.

## Architecture

```
Flutter Client (Riverpod, Clean Architecture, SQLite offline-first)
        |  Dio (REST, JWT bearer)
        v
Node.js / Express API (JWT auth, RBAC, express-validator, helmet, rate limiting)
        |  mysql2 (parameterized queries, transactions)
        v
MySQL 8 (normalized schema, FKs, indexes, soft deletes, optimistic concurrency via `version`)
```

Every mutation on the client is applied to the local SQLite database first
(source of truth for the UI) and queued in a `sync_queue` table. A
`SyncManager` listens for connectivity changes and drains the queue with
exponential backoff (`min(2^attempt * 1000ms, 30000ms)`, capped at 5
retries before marking an item `FAILED`). If the server rejects a mutation
with `409 Conflict` (stale `version`), the client overwrites its local
record with the authoritative server copy.

## Repository layout

```
backend/        Node.js + Express + MySQL REST API (MVC + repository pattern)
flutter_app/    Flutter client (Clean Architecture: domain / data / presentation)
database/       schema.sql — full normalized MySQL DDL
docker-compose.yml
```

## Backend setup

```bash
cd backend
cp .env.example .env   # edit DB credentials and JWT secrets
npm install
mysql -u root -p < ../database/schema.sql
npm run dev             # nodemon, http://localhost:5000
npm test                # jest + supertest
```

## Flutter setup

```bash
cd flutter_app
flutter pub get
flutter run              # defaults to http://10.0.2.2:5000/api/v1 (Android emulator loopback)
flutter test
```

For a physical device or iOS simulator, update `ApiEndpoints.baseUrl` in
`lib/core/constants/api_endpoints.dart` to your machine's LAN IP.

## Docker (backend + MySQL)

```bash
docker compose up --build
```

## REST API summary (all under `/api/v1`, JWT bearer unless noted)

| Method | Endpoint                | Auth | Description                     |
|--------|-------------------------|------|----------------------------------|
| POST   | /auth/register          | No   | Register a new user              |
| POST   | /auth/login             | No   | Authenticate, returns JWT pair   |
| POST   | /auth/refresh           | No   | Rotate access token              |
| POST   | /auth/logout            | Yes  | Revoke refresh token             |
| GET    | /users/profile          | Yes  | Get current user                 |
| PUT    | /users/profile          | Yes  | Update profile                   |
| GET    | /notes                  | Yes  | List notes (paginated, filtered) |
| POST   | /notes                  | Yes  | Create note                      |
| PUT    | /notes/:id              | Yes  | Update note (optimistic concurrency via `version`) |
| DELETE | /notes/:id              | Yes  | Soft delete note                 |
| PATCH  | /notes/:id/archive      | Yes  | Toggle archive                   |
| PATCH  | /notes/:id/pin          | Yes  | Toggle pin                       |
| GET    | /tasks                  | Yes  | List tasks (filtered)            |
| POST   | /tasks                  | Yes  | Create task (with subtasks)      |
| PUT    | /tasks/:id              | Yes  | Update task                      |
| DELETE | /tasks/:id              | Yes  | Soft delete task                 |
| PATCH  | /tasks/:id/status       | Yes  | Update status (TODO/IN_PROGRESS/COMPLETED) |
| GET    | /dashboard              | Yes  | Aggregate stats                  |

## Security

JWT access + refresh tokens, bcrypt password hashing (12 salt rounds),
role-based authorization middleware, express-validator input validation,
parameterized queries throughout (no string-concatenated SQL), helmet,
CORS, and separate stricter rate limits on auth endpoints.
