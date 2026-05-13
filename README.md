# 🎯 JobTracker

> Aplicação full-stack para gerir candidaturas a empregos, com integração de fontes externas e dashboard de progresso.

[![Ruby on Rails](https://img.shields.io/badge/Rails-CC0000?style=flat-square&logo=rubyonrails&logoColor=white)](https://rubyonrails.org)
[![React](https://img.shields.io/badge/React-20232A?style=flat-square&logo=react&logoColor=61DAFB)](https://react.dev)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=flat-square&logo=postgresql&logoColor=white)](https://postgresql.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

## 🌟 Porque é que isto existe

Construído enquanto procurava a minha próxima posição como Junior Full-Stack Developer (Maio-Junho 2026). Em vez de gerir candidaturas num Excel ou Notion, achei mais útil construir a ferramenta que precisava — e usá-la como projeto de portfólio.

A app integra fontes públicas de ofertas (Indeed, LinkedIn jobs, páginas de carreiras de empresas-alvo) e organiza tudo num único pipeline tipo Kanban: **Nova → Interessante → Candidatada → Entrevista → Oferta / Rejeitada**.

## ✨ Funcionalidades

### MVP (em desenvolvimento)

- [x] Modelo de dados normalizado (Offers, Notes, Status changes, Sources)
- [ ] CRUD de ofertas via API REST (Rails)
- [ ] UI de listagem com filtros (status, match score, localização, modalidade)
- [ ] Pipeline Kanban (drag-and-drop entre estados)
- [ ] Notas por oferta (markdown)
- [ ] Importação JSON (compatível com a tarefa agendada `daily-job-search-bruno` do Cowork)
- [ ] Exportação CSV / XLSX

### V2 (planeado)

- [ ] Autenticação (Devise) — preparar para hosting público multi-utilizador
- [ ] Scrapers integrados como Rails jobs (Sidekiq + Redis)
   - Indeed (API oficial)
   - LinkedIn Jobs (via fetch público)
   - Landing.jobs (API)
   - ITJobs.pt (RSS / scraping)
- [ ] Notificações por email (Mailer + ActionMailer)
- [ ] Dashboard analítico (taxa de resposta, conversão por canal)
- [ ] Versões de CV / cartas anexadas por candidatura
- [ ] Notas de preparação para entrevista por empresa

## 🛠 Stack técnica

**Backend**
- Ruby 3.3+
- Rails 8 (API mode)
- PostgreSQL 16
- Sidekiq (V2)

**Frontend**
- React 18 + TypeScript
- Vite
- TanStack Query (data fetching)
- Tailwind CSS
- @dnd-kit (drag-and-drop)

**Infrastructure**
- Deploy: Render.com (free tier) ou Fly.io
- DB: Render Postgres (free tier)
- CI: GitHub Actions

## 🚀 Como correr localmente

```bash
# 1. Clonar
git clone https://github.com/brunombpereira/job-tracker.git
cd job-tracker

# 2. Backend (Rails API)
cd backend
bundle install
bin/rails db:create db:migrate db:seed
bin/rails server  # http://localhost:3000

# 3. Frontend (React)
cd ../frontend
npm install
npm run dev  # http://localhost:5173
```

## 📐 Arquitetura

Ver [`docs/TECH_DESIGN.md`](docs/TECH_DESIGN.md) para detalhe completo.

```
┌─────────────┐         ┌──────────────┐
│   React     │ ◄─────► │  Rails API   │
│  (Vite)     │  REST   │              │
└─────────────┘         └──────┬───────┘
                               │
                       ┌───────▼────────┐
                       │  PostgreSQL    │
                       └────────────────┘
                               ▲
                               │
                       ┌───────┴────────┐
                       │  Sidekiq (V2)  │
                       │  scrapers      │
                       └────────────────┘
```

## 📅 Roadmap

Ver [`docs/ROADMAP.md`](docs/ROADMAP.md) para milestones detalhados.

| Milestone | Descrição | Estimativa |
|---|---|---|
| **M0** — Foundations | Setup Rails + React, modelo de dados, primeira API | 1 weekend |
| **M1** — MVP UI | Listagem, filtros, CRUD via UI | 1 weekend |
| **M2** — Kanban | Pipeline com drag-and-drop | 1 weekend |
| **M3** — Import/Export | JSON import, CSV/XLSX export | 1 day |
| **M4** — Deploy | Live em URL pública | 1 day |
| **M5** — V2 features | Auth, scrapers, dashboard analítico | 2-3 weekends |

## 🤝 Contribuir

Projeto pessoal mas open para issues, sugestões e PRs. Issues abertas em [GitHub Issues](https://github.com/brunombpereira/job-tracker/issues).

## 📄 Licença

MIT © Bruno Borlido Pereira
