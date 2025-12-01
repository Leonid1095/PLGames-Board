# PLGames Board - Open Source CRM & Project Management System

**PLGames Board** is a powerful, self-hosted CRM and project management information system. Perfect for teams in Russia and worldwide.

## ✨ Features

### 🎯 Core Features
- **Project Management**: Create and manage projects with team leads
- **Issue Tracking**: Full-featured issue tracking system (Jira-like)
- **Sprint Planning**: Agile sprint management with backlogs
- **Time Tracking**: Log time spent on tasks
- **Comments & Collaboration**: Real-time team collaboration
- **GraphQL API**: Modern API for integrations

### 🚀 Advanced Features
- **Real-time Collaboration**: Work together in real-time
- **Rich Text Editor**: Powerful document editing
- **AI Assistant**: AI-powered content generation via OpenRouter (GPT-4, Claude, Llama)
- **OAuth Authentication**: Yandex OAuth support for Russia
- **Self-hosted**: Full control of your data
- **Notifications**: In-app notification system
- **Cron Jobs**: Scheduled tasks and automation

## 🇷🇺 Russia-Friendly

This project is optimized for deployment in Russia:
- ✅ Auto-detects region and uses mirrors
- ✅ Alternative Docker registries configured
- ✅ NPM/Yarn mirror support
- ✅ Yandex OAuth integration
- ✅ Russian documentation included

## 📦 Quick Start

### Prerequisites
- Ubuntu 20.04+ / Debian 11+ server
- 4GB RAM minimum (8GB recommended)
- 20GB disk space
- External IP address
- Domain name (optional but recommended)

### One-Click Installation

```bash
# Clone repository
git clone https://github.com/your-username/boards_plane.git
cd boards_plane

# Update submodules
git submodule update --init --recursive

# Set your domain (optional)
export DOMAIN=your-domain.com

# Run deployment script
sudo ./deploy_production.sh
```

**Installation time**: 15-30 minutes

For detailed instructions in Russian, see [INSTALL_RU.md](INSTALL_RU.md)

## 🔧 Configuration

After installation, edit the `.env` file to configure:

```bash
nano .env
```

### Enable AI Features

```env
AFFINE_COPILOT_ENABLED=true
AFFINE_COPILOT_OPENROUTER_API_KEY=your_api_key
```

Get API key from [OpenRouter](https://openrouter.ai/)

### Enable Yandex OAuth

```env
OIDC_CLIENT_ID=your_client_id
OIDC_CLIENT_SECRET=your_client_secret
```

Create OAuth app at [Yandex OAuth](https://oauth.yandex.ru/client/new)

## 📊 Access

After successful deployment:

- **Frontend**: http://your-server-ip:8080 or https://your-domain.com
- **Backend API**: http://your-server-ip:3010/api
- **GraphQL**: http://your-server-ip:3010/graphql

## 🛠️ Management Commands

```bash
# View logs
docker compose -f docker-compose.prod.yml logs -f

# Restart services
docker compose -f docker-compose.prod.yml restart

# Stop services
docker compose -f docker-compose.prod.yml down

# Update system
./deploy_production.sh

# Backup database
docker compose -f docker-compose.prod.yml exec postgres pg_dump -U plgames plgames > backup.sql
```

## 🏗️ Architecture

```
┌─────────────────┐
│   Frontend      │  Port 8080 (React + Caddy)
│   (Web UI)      │
└────────┬────────┘
         │
┌────────▼────────┐
│   Backend       │  Port 3010 (NestJS + GraphQL)
│   (API Server)  │
└────────┬────────┘
         │
    ┌────┴─────┬──────────┐
    │          │          │
┌───▼───┐  ┌───▼────┐  ┌──▼────┐
│Postgres│  │ Redis  │  │Storage│
│  DB    │  │ Cache  │  │       │
└────────┘  └────────┘  └───────┘
```

## 📁 Project Structure

```
.
├── plgames/                    # Main application (submodule)
│   ├── packages/
│   │   ├── backend/server/     # NestJS backend
│   │   │   └── src/
│   │   │       └── core/crm/   # ✨ CRM Module
│   │   └── frontend/apps/web/  # React frontend
│   └── Dockerfile.plgames      # Backend Docker build
├── docker-compose.prod.yml     # Production deployment
├── deploy_production.sh        # One-click deployment script
├── .env.example                # Environment variables template
└── INSTALL_RU.md              # Russian installation guide
```

## 🎯 CRM Features

### Projects
- Create and manage projects
- Assign project leads
- Track project progress
- View project statistics

### Issues
- Create issues with type (Task, Bug, Story, Epic)
- Set priority (Lowest to Highest)
- Assign to team members
- Track status (Backlog → Done)
- Set due dates and story points
- Create subtasks

### Sprints
- Create sprints with goals
- Assign issues to sprints
- Track sprint progress
- Manage active/completed sprints

### Time Tracking
- Log time spent on issues
- View total time per issue
- Track team productivity

### GraphQL API Example

```graphql
# Create a project
mutation {
  createCrmProject(input: {
    name: "My Project"
    key: "PROJ"
    workspaceId: "workspace-id"
  }) {
    id
    name
    key
  }
}

# Get project issues
query {
  crmIssuesByProject(
    projectId: "project-id"
    status: IN_PROGRESS
  ) {
    id
    title
    status
    assignee {
      name
      email
    }
  }
}
```

## 🔒 Security

- Environment-based configuration
- Secure password generation
- OAuth 2.0 authentication support
- Regular security updates
- Database backups recommended

## 📈 Performance

- Docker-based deployment
- Redis caching
- PostgreSQL with pgvector
- Optimized build process
- Production-ready configuration

## 🌍 Russia Deployment Notes

The deployment script automatically detects if you're in Russia and:
- Uses mirror registries for Docker images
- Configures NPM mirrors for faster package downloads
- Applies network timeout optimizations
- Uses Russia-friendly CDNs

## 🤝 Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

## 📄 License

MIT License - Free for commercial and personal use.

## 🆘 Support

- **Documentation**: See [INSTALL_RU.md](INSTALL_RU.md) for Russian guide
- **Issues**: [GitHub Issues](https://github.com/your-username/boards_plane/issues)
- **Email**: support@your-domain.com

## 🏗️ Technology Stack

**PLGames Board** is built with modern technologies:
- [NestJS](https://nestjs.com/) - Progressive Node.js framework
- [Prisma](https://www.prisma.io/) - Next-generation ORM
- [GraphQL](https://graphql.org/) - Query language for APIs
- [PostgreSQL](https://www.postgresql.org/) - Reliable database
- [Redis](https://redis.io/) - High-performance caching
- [Docker](https://www.docker.com/) - Containerization

---

**Made with ❤️ for teams in Russia and worldwide**

*PLGames Board - Your complete project management solution!*
