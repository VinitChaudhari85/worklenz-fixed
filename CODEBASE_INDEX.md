# Worklenz — Codebase Index

> A complete reference map of the Worklenz codebase for developers.
> Use `Ctrl+F` to quickly find what you need.

---

## Quick Navigation

- [Architecture](#architecture)
- [Backend](#backend)
- [Frontend](#frontend)
- [Database](#database)
- [Real-Time (Socket.IO)](#real-time-socketio)
- [Infrastructure](#infrastructure)
- [Key Data Flows](#key-data-flows)

---

## Architecture

```
Browser → Nginx (:80) → Backend (:3000) → PostgreSQL (:5432)
                      → Frontend (:4200)         → Redis (:6379)
                                                  → MinIO (:9000)
```

| Layer | Tech | Entry Point |
|-------|------|-------------|
| Frontend | React 18 + TypeScript + Vite | `worklenz-frontend/src/index.tsx` → `App.tsx` |
| Backend | Node.js + Express + TypeScript | `worklenz-backend/src/app.ts` |
| Database | PostgreSQL 15 | `worklenz-backend/database/sql/` |
| Cache/Sessions | Redis 7 | `worklenz-backend/src/redis/` |
| File Storage | MinIO (S3-compatible) | `worklenz-backend/src/controllers/attachment-controller.ts` |
| Real-time | Socket.IO | `worklenz-backend/src/socket.io/index.ts` |
| Reverse Proxy | Nginx | `nginx/` |

---

## Backend

**Root:** `worklenz-backend/src/`

### Entry & Config

| File | Purpose |
|------|---------|
| `app.ts` | Express app setup, middleware chain, route mounting |
| `config/db.ts` | PostgreSQL connection pool |
| `routes/index.ts` | Top-level route registration |
| `routes/apis/index.ts` | All `/api/*` route mounting |

### Controllers (Business Logic)

All in `controllers/`. Each controller handles one domain:

#### Core Features
| Controller | What It Does |
|------------|-------------|
| `auth-controller.ts` | Login, signup, sessions, Google OAuth |
| `projects-controller.ts` | CRUD projects, project settings, members |
| `tasks-controller-v2.ts` | Task CRUD, bulk operations, grouping (main task controller) |
| `tasks-controller.ts` | Legacy task operations |
| `task-comments-controller.ts` | Task comments with @mentions |
| `attachment-controller.ts` | File upload/download via MinIO/S3 |
| `team-members-controller.ts` | Team member management, invitations, roles |
| `home-page-controller.ts` | Dashboard data, recent tasks, assigned items |

#### Project Features
| Controller | What It Does |
|------------|-------------|
| `project-members-controller.ts` | Add/remove project members, roles |
| `project-comments-controller.ts` | Project-level comments and updates |
| `project-categories-controller.ts` | Project categorization |
| `project-insights-controller.ts` | Project analytics & charts |
| `labels-controller.ts` | Task labels/tags management |
| `task-statuses-controller.ts` | Custom workflow statuses per project |
| `task-phases-controller.ts` | Phase/milestone management |
| `task-work-log-controller.ts` | Time tracking / work logs |
| `sub-tasks-controller.ts` | Sub-task hierarchy |
| `task-dependencies-controller.ts` | Task dependency links |
| `gantt-controller.ts` | Gantt chart data |

#### Reporting
| Controller | What It Does |
|------------|-------------|
| `reporting-controller.ts` | Legacy reporting (members, overview, allocation) |
| `reporting/projects/reporting-projects-controller.ts` | Project reports with filters |
| `reporting/reporting-members-controller.ts` | Member reports |
| `reporting/reporting-allocation-controller.ts` | Time allocation reports |
| `reporting/overview/reporting-overview-controller.ts` | Reporting dashboard overview |
| `reporting/reporting-controller-base.ts` | Shared reporting utilities, SQL queries |

#### Administration
| Controller | What It Does |
|------------|-------------|
| `admin-center-controller.ts` | Organization settings, billing, user management |
| `profile-settings-controller.ts` | User profile updates |
| `notification-controller.ts` | In-app notifications |
| `teams-controller.ts` | Team switching & creation |

### API Routes

All in `routes/apis/`. Each router maps URLs to controller methods:

| Router | Base Path | Key Endpoints |
|--------|-----------|---------------|
| `projects-api-router.ts` | `/api/projects` | GET, POST, PUT, DELETE projects |
| `tasks-api-router.ts` | `/api/tasks` | Task CRUD, bulk updates |
| `team-members-api-router.ts` | `/api/team-members` | Member CRUD, invitations |
| `reporting-api-router.ts` | `/api/reporting` | All reporting endpoints |
| `attachments-api-router.ts` | `/api/attachments` | File upload/download |
| `task-comments-api-router.ts` | `/api/task-comments` | Comment CRUD |
| `statuses-api-router.ts` | `/api/statuses` | Status management |
| `labels-api-router.ts` | `/api/labels` | Label management |

### Middleware

| File | Purpose |
|------|---------|
| `middlewares/validators/` | Request validation (ID params, body schemas) |
| `passport/` | Authentication strategies (local, Google OAuth) |
| `shared/safe-controller-function.ts` | Error handler wrapper for all routes |

### Utilities

| File | Purpose |
|------|---------|
| `shared/constants.ts` | App-wide constants (page sizes, date ranges) |
| `shared/utils.ts` | Helper functions (color generation, formatting) |
| `shared/sql-helpers.ts` | Secure SQL query builders (parameterized queries) |

---

## Frontend

**Root:** `worklenz-frontend/src/`

### Entry & Routing

| File | Purpose |
|------|---------|
| `index.tsx` | React DOM render, Redux Provider setup |
| `App.tsx` | Route definitions, layout switching, auth guards |
| `i18n.ts` | Internationalization setup |

### Pages (Route Components)

All in `pages/`. Each maps to a URL route:

| Page | URL | What It Shows |
|------|-----|---------------|
| `auth/` | `/auth/login`, `/auth/signup` | Login & registration forms |
| `account-setup/` | `/worklenz/setup` | Onboarding wizard |
| `home/` | `/worklenz/home` | Dashboard with tasks & projects |
| `projects/project-list.tsx` | `/worklenz/projects` | Project listing table |
| `projects/projectView/` | `/worklenz/projects/:id` | Single project view (tasks, board, gantt) |
| `reporting/overview-reports/` | `/worklenz/reporting` | Reporting overview |
| `reporting/projects-reports/` | `/worklenz/reporting/projects` | Project reports with filters |
| `reporting/members-reports/` | `/worklenz/reporting/members` | Member reports |
| `reporting/time-reports/` | `/worklenz/reporting/time-reports` | Time tracking reports |
| `admin-center/` | `/worklenz/admin-center` | Organization admin panel |
| `settings/` | `/worklenz/settings` | User settings |
| `schedule/` | `/worklenz/schedule` | Resource scheduling |

### State Management (Redux)

All in `features/`. Each feature has a Redux Toolkit slice:

| Feature Slice | Store Key | What It Manages |
|---------------|-----------|-----------------|
| `auth/` | `authReducer` | User session, login state |
| `project/` | `projectReducer` | Active project data |
| `projects/` | `projectsReducer` | Project list, lookups (statuses, healths, categories) |
| `tasks/` | `tasksReducer` | Task list, task drawer state |
| `task-drawer/` | `taskDrawerReducer` | Task detail panel state |
| `reporting/projectReports/` | `projectReportsReducer` | Project reporting filters & data |
| `reporting/` | Various | Member reports, time reports |
| `home-page/` | `homePageReducer` | Dashboard widgets |
| `team-members/` | `teamMembersReducer` | Team member list |
| `theme/` | `themeReducer` | Dark/light mode |
| `navbar/` | `navbarReducer` | Navigation state |

### API Layer

All in `api/`. Each module wraps `axios` calls to backend endpoints:

| API Service | Backend Endpoint | Purpose |
|-------------|-----------------|---------|
| `api-client.ts` | — | Axios instance with auth interceptors |
| `projects/` | `/api/projects` | Project CRUD |
| `tasks/` | `/api/tasks` | Task operations |
| `team-members/` | `/api/team-members` | Team member operations |
| `attachments/` | `/api/attachments` | File upload/download |
| `reporting/` | `/api/reporting` | All reporting data |
| `auth/` | `/api/auth` | Login, signup, session |
| `settings/` | `/api/settings` | User/team settings |

### Key Components

All in `components/`. Reusable UI pieces:

| Component | What It Does |
|-----------|-------------|
| `task-drawer/` | Slide-out panel showing task details |
| `task-list-v2/` | Main task list table with grouping |
| `board/` | Kanban board view |
| `enhanced-kanban/` | Improved kanban board |
| `project-list/` | Project listing table |
| `navbar/` | Top navigation bar |
| `charts/` | Reporting charts (progress, burndown) |
| `advanced-gantt/` | Gantt chart component |
| `add-members-dropdown/` | Member assignment UI |
| `project-task-filters/` | Task filtering dropdowns |
| `reporting/` | Reporting-specific components |

---

## Database

**Root:** `worklenz-backend/database/sql/`

### Schema Files (run in order)

| File | Contents |
|------|----------|
| `0_extensions.sql` | PostgreSQL extensions (uuid-ossp) |
| `1_tables.sql` | All table definitions (~95KB, 50+ tables) |
| `2_dml.sql` | Seed data (statuses, priorities, healths, roles) |
| `3_views.sql` | Database views |
| `4_functions.sql` | Stored procedures & functions (~270KB, 100+ functions) |
| `5_database_user.sql` | Database user permissions |
| `indexes.sql` | Performance indexes |
| `triggers.sql` | Database triggers |
| `migrations/` | Schema migration scripts |

### Key Tables

| Table | Purpose |
|-------|---------|
| `users` | User accounts |
| `teams` | Workspaces/organizations |
| `team_members` | User ↔ Team membership |
| `projects` | Projects |
| `project_members` | User ↔ Project membership with roles |
| `tasks` | Tasks (core entity) |
| `task_statuses` | Custom statuses per project |
| `task_priorities` | Priority levels |
| `task_activity_logs` | Audit trail for task changes |
| `task_work_log` | Time tracking entries |
| `task_comments` | Task comments |
| `task_attachments` | File attachments linked to tasks |
| `team_labels` | Labels/tags per team |
| `project_categories` | Project categories |
| `sys_project_healths` | Project health options (Not Set, Good, At Risk, etc.) |
| `sys_project_statuses` | Project status options (Proposed, In Progress, etc.) |
| `notifications` | In-app notifications |

### Key Database Functions

| Function | What It Does |
|----------|-------------|
| `create_task()` | Insert task with proper defaults and activity log |
| `handle_task_status_change()` | Update status with cascading effects |
| `handle_task_list_sort_order_change()` | Manage task ordering in lists |
| `in_organization()` | Check if team belongs to same org |
| `is_completed()` / `is_doing()` / `is_todo()` | Status category checkers |
| `register_user()` | Full user registration flow |

---

## Real-Time (Socket.IO)

**Root:** `worklenz-backend/src/socket.io/`

| File | Purpose |
|------|---------|
| `index.ts` | Socket.IO server setup, event registration |
| `events.ts` | Event name constants |

### Socket Commands

All in `commands/`. Each handles one real-time event:

| Command | Event | What It Does |
|---------|-------|-------------|
| `on-quick-task.ts` | Task creation | Create task and broadcast to project room |
| `on-task-status-change.ts` | Status update | Change status, update progress, notify |
| `on-task-assignees-change.ts` | Assignment | Assign/unassign members, notify |
| `on-task-name-change.ts` | Name edit | Rename task, broadcast |
| `on-task-priority-change.ts` | Priority | Change priority, broadcast |
| `on-task-sort-order-change.ts` | Drag & drop | Reorder tasks within/between groups |
| `on-task-start-date-change.ts` | Date edit | Update start date |
| `on-task-end-date-change.ts` | Date edit | Update end date |
| `on-task-labels-change.ts` | Labels | Add/remove labels |
| `on-task-phase-change.ts` | Phase | Change task phase/milestone |
| `on-task-timer-start.ts` | Timer | Start time tracking |
| `on-task-timer-stop.ts` | Timer | Stop timer, create work log |
| `on-time-estimation-change.ts` | Estimation | Update time estimate |
| `on-project-health-change.ts` | Project | Change project health |
| `on-project-status-change.ts` | Project | Change project status |

---

## Infrastructure

| File/Dir | Purpose |
|----------|---------|
| `docker-compose.yaml` | All service definitions |
| `.env` | Environment configuration |
| `nginx/` | Reverse proxy config (routes /api → backend, / → frontend) |
| `scripts/db-init-wrapper.sh` | Database initialization on first run |
| `worklenz-backend/Dockerfile` | Backend container build |
| `worklenz-frontend/Dockerfile` | Frontend container build |

---

## Key Data Flows

### Creating a Task
```
Frontend                    Backend                     Database
────────                    ───────                     ────────
TaskList → Socket.IO     →  on-quick-task.ts         →  create_task()
  emit("QUICK_TASK")        validates & inserts          returns task + triggers
                         ←  broadcasts to room       ←  activity_log created
TaskList updates         ←  all clients in project
```

### Changing Task Status
```
StatusDropdown → Socket   → on-task-status-change.ts → UPDATE tasks SET status_id
                          → logs activity             → task_activity_logs INSERT
                          → broadcasts to room        → all project members updated
```

### Filtering Reports
```
FilterDropdown              Redux Slice               API Service              Controller
──────────────              ───────────               ───────────              ──────────
onChange()               →  setSelectedHealths()   →  GET /api/reporting    →  ReportingProjectsController.get()
dispatch(fetchData())       updates state              /projects?healths=     builds SQL with parameterized IN clause
                         ←  projectList updated     ←  ServerResponse       ← db.query() returns filtered results
```

### File Upload
```
AttachmentUpload → POST /api/attachments → attachment-controller.ts → MinIO S3 PutObject
                                                                    → task_attachments INSERT
Browser displays ← URL: http://minio:9000/worklenz-bucket/...     ← returns signed URL
```

---

## Where to Start Editing

| If you want to... | Start here |
|-------------------|------------|
| Change the dashboard | `pages/home/` + `features/home-page/` |
| Modify task behavior | `socket.io/commands/on-*.ts` + `features/tasks/` |
| Add a new API endpoint | `routes/apis/` → `controllers/` |
| Change project views | `pages/projects/projectView/` |
| Edit reporting | `pages/reporting/` + `controllers/reporting/` |
| Modify the database schema | `database/sql/1_tables.sql` + create migration in `migrations/` |
| Change auth flow | `controllers/auth-controller.ts` + `passport/` |
| Modify file uploads | `controllers/attachment-controller.ts` |
| Add real-time features | `socket.io/commands/` + `socket/` (frontend) |
| Change styling/theme | `styles/` + `features/theme/` |
