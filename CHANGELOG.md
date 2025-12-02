# Changelog

All notable changes to PLGames Board project.

## [Unreleased]

### Added - One-Command Installation 🚀
- **install.sh** - Умный установщик с автоматической настройкой (1 команда!)
  - Автоматическая установка Docker
  - Определение региона (зеркала для России)
  - Интерактивная настройка (домен, AI, OAuth)
  - Автоматическая сборка и запуск
  - Выполнение миграций
  - Проверка работоспособности
  - Генерация безопасных паролей
- **docker-compose.yml** - Универсальный compose файл (вместо 3 разных)
  - Работает и для dev и для prod
  - Все переменные с default значениями
  - Healthcheck для всех сервисов
  - Оптимизированная конфигурация
- Упрощен README - теперь установка за 1 команду через curl/wget

### Fixed - Docker Compose improvements
- Fixed docker-compose.prod.yml: added default values for optional env vars (:-syntax)
- Fixed docker-compose.prod.yml: added networks to backend and frontend services
- Added DEPLOYMENT_FIX.md with comprehensive troubleshooting guide
- Added docker-compose.simple.yml for backend-only deployment option
- Updated AI_DEPLOYMENT_GUIDE.md with Problem 7: Frontend build issues

### Changed - Rebranding to PLGames Board
- Renamed from "PLGames" to "PLGames Board"
- Updated all documentation to reflect independent information system status
- Removed references to being "built on AFFiNE" - now standalone system
- Created comprehensive roadmap (ROADMAP.md) for future development
- Updated README.md with structured documentation section
- Updated README.md, INSTALL_RU.md, PROJECT_SUMMARY.md, AI_DEPLOYMENT_GUIDE.md

### Added - Enhanced documentation
- Added QUICK_START_GUIDE.md for new users (5-minute start guide)
- Added FEATURES_ANALYSIS.md with detailed capabilities breakdown (AI, CRM, notifications)
- Added ROADMAP.md with development plan v1.0 → v4.0.0 (through 2026)
- Added PROJECT_QUALITY_REPORT.md - comprehensive project quality analysis and error prevention guide
- Added DEPLOYMENT_TROUBLESHOOTING.md - step-by-step guide for fixing deployment issues (502 errors, backend not starting, migration failures)
- Added QUICK_FIX_FOR_AI.md - rapid troubleshooting guide for AI assistants on production servers (10-minute fix)

## [1.0.0] - 2024-12-01

### 🎉 Initial Production Release

#### ✨ Added - CRM Module

**Complete CRM System Implementation:**
- ✅ **Projects Management**
  - Create and manage projects
  - Assign project leads
  - Track project statistics
  - Link to workspaces

- ✅ **Issue Tracking System**
  - Full issue lifecycle (Backlog → Done)
  - Issue types: Task, Bug, Story, Epic, Subtask
  - Priority levels: Lowest, Low, Medium, High, Highest
  - Status tracking: Backlog, TODO, In Progress, In Review, Done, Cancelled
  - Assignee and reporter tracking
  - Due dates and story points
  - Parent-child relationships (subtasks)

- ✅ **Sprint Management**
  - Create and manage sprints
  - Set sprint goals and timelines
  - Assign issues to sprints
  - Track active sprints
  - Sprint statistics

- ✅ **Collaboration Features**
  - Comment on issues
  - Real-time updates
  - User mentions
  - Activity tracking

- ✅ **Time Tracking**
  - Log time spent on issues
  - Track total time per issue
  - Time logs per user
  - Productivity insights

#### 🔧 Backend Implementation

**File Structure:**
```
plgames/packages/backend/server/src/core/crm/
├── crm.module.ts       # NestJS module configuration
├── crm.service.ts      # Business logic service
├── crm.resolver.ts     # GraphQL resolvers
├── types.ts            # TypeScript type definitions
└── index.ts            # Module exports
```

**Database Models:**
- `CrmProject` - Project management
- `CrmIssue` - Issue tracking
- `CrmSprint` - Sprint planning
- `CrmComment` - Issue comments
- `CrmTimeLog` - Time tracking

**GraphQL API:**
- Queries: Projects, Issues, Sprints
- Mutations: Create, Update, Delete operations
- Subscriptions: Real-time updates (future)
- Permissions: Workspace-based access control

**Integration:**
- ✅ Added to `app.module.ts`
- ✅ Integrated with Permission system
- ✅ Connected to Prisma ORM
- ✅ Models exported in models index

#### 🚀 Deployment & DevOps

**Russia-Friendly Deployment:**
- ✅ Auto-detection of Russia region
- ✅ Docker mirror configuration
- ✅ NPM/Yarn mirror support
- ✅ Network timeout optimizations
- ✅ Alternative registries configured

**Deployment Scripts:**
- `deploy_production.sh` - One-click production deployment
  - Docker installation with region detection
  - Automatic mirror configuration for Russia
  - Database migration automation
  - Health checks and verification
  - Comprehensive error reporting

- `quick-start.sh` - Interactive setup wizard
  - Domain configuration
  - AI features setup (OpenRouter)
  - OAuth setup (Yandex)
  - Automatic .env generation
  - Guided deployment process

**Docker Configuration:**
- ✅ Fixed Dockerfile duplications
- ✅ Added Prisma schema to production image
- ✅ Multi-stage builds for optimization
- ✅ Health checks for all services

**Docker Compose:**
- Backend service (NestJS)
- Frontend service (React + Caddy)
- PostgreSQL with pgvector
- Redis for caching
- Proper networking and volumes
- Environment variable support

#### 📚 Documentation

**Created Documentation Files:**
- `README.md` - Project overview and quick start (English)
- `INSTALL_RU.md` - Complete installation guide (Russian)
- `DEPLOYMENT_CHECKLIST.md` - Pre-deployment verification
- `.env.example` - Environment variables template
- `CHANGELOG.md` - This file

**Documentation Includes:**
- Installation instructions for Russia
- HTTPS setup guides (Nginx & Caddy)
- OAuth configuration (Yandex)
- AI features setup (OpenRouter)
- Backup and restore procedures
- Troubleshooting guide
- Security best practices

#### 🔒 Security Enhancements

- ✅ Secure password generation (16-32 chars)
- ✅ Environment file permissions (600)
- ✅ Session and JWT secrets
- ✅ Workspace-based permissions
- ✅ OAuth 2.0 support (Yandex)
- ✅ Rate limiting configured
- ✅ CORS configuration

#### 🌍 Internationalization

- ✅ Russian deployment guide
- ✅ Russia-specific optimizations
- ✅ Yandex OAuth integration
- ✅ Yandex Cloud storage support (ready)
- ✅ Mirror registries for blocked services

#### 🐛 Bug Fixes

- Fixed: Dockerfile duplication (ENV and CMD repeated)
- Fixed: Deploy script using wrong branch (master → main)
- Fixed: Missing Prisma schema in production build
- Fixed: Missing CLS_REQUEST_HOST global declaration

#### ⚡ Performance Optimizations

- Multi-stage Docker builds
- Redis caching layer
- Database indexing for CRM tables
- Optimized Prisma queries
- Compressed Docker layers

### 🔄 Migration Notes

**Database Migrations:**
```bash
# CRM tables will be created automatically on first deployment
docker compose -f docker-compose.prod.yml exec backend sh -c "npx prisma migrate deploy"
```

**Required Actions:**
1. Update `.env` with your domain
2. Configure OAuth if needed (optional)
3. Add OpenRouter API key for AI (optional)
4. Set up HTTPS with Nginx or Caddy (recommended)

### 📦 Dependencies

**Major Dependencies:**
- Node.js 22
- PostgreSQL 16 with pgvector
- Redis Alpine
- Prisma 6.6.0
- NestJS 11.0.12
- GraphQL 16.9.0
- React 19.1.0

### 🎯 What's Next

**Planned for v1.1.0:**
- [ ] Frontend CRM UI components
- [ ] Dashboard with statistics
- [ ] Kanban board view
- [ ] Sprint planning interface
- [ ] Time tracking UI
- [ ] Advanced search and filters
- [ ] Export/Import functionality
- [ ] Email notifications
- [ ] Webhooks for integrations

**Future Enhancements:**
- [ ] Mobile app (React Native)
- [ ] Desktop app (Electron)
- [ ] Advanced analytics
- [ ] Custom fields
- [ ] Workflow automation
- [ ] API rate limiting per user
- [ ] Multi-language support
- [ ] Dark mode

### 🙏 Credits

- Based on [AFFiNE](https://affine.pro/) open-source workspace
- Built with [NestJS](https://nestjs.com/) framework
- Uses [Prisma](https://www.prisma.io/) ORM
- Powered by [GraphQL](https://graphql.org/)

### 📄 License

MIT License - Free for commercial and personal use.

---

**Full Release Notes:** https://github.com/your-username/boards_plane/releases/tag/v1.0.0
