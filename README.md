# 🎯 JobTracker

> Aplicação full-stack para gerir candidaturas a empregos — pipeline tipo Kanban, scrapers de fontes públicas e match score automático.

[![Ruby on Rails](https://img.shields.io/badge/Rails-CC0000?style=flat-square&logo=rubyonrails&logoColor=white)](https://rubyonrails.org)
[![React](https://img.shields.io/badge/React-20232A?style=flat-square&logo=react&logoColor=61DAFB)](https://react.dev)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=flat-square&logo=postgresql&logoColor=white)](https://postgresql.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

## 🌟 Porque é que isto existe

Construído enquanto procurava a minha próxima posição como Junior Full-Stack Developer. Em vez de gerir candidaturas num Excel ou Notion, achei mais útil construir a ferramenta que precisava — e usá-la como projeto de portfólio.

É **self-hostable**: cada pessoa corre a sua própria instância e personaliza tudo pela app (sem editar código). As fontes de ofertas são sobretudo de Portugal.

## ✨ Funcionalidades

- **Pipeline Kanban** — Nova → Interessante → Candidatada → Entrevista → Oferta / Rejeitada, com drag-and-drop
- **Lista com filtros** — status, match score, localização, modalidade, follow-up pendente
- **Match score automático (1–5)** — calculado a partir do teu perfil (stack, sinais de título, localização)
- **Scrapers integrados** — Remotive, Landing.jobs, We Work Remotely, Net-Empregos, Teamlyzer, LinkedIn (guest) — diários via Sidekiq + cron, ou a pedido
- **Importação por URL** — cola o link de uma oferta (LinkedIn, Indeed, ATSes…) e extrai os dados
- **Monitorização dos scrapers** — deteta fontes que falharam ou deixaram de devolver ofertas
- **Lembretes de follow-up** — candidaturas paradas há demasiado tempo
- **Cartas de apresentação** — geradas por oferta a partir dos teus modelos
- **Notas por oferta** + histórico de mudanças de estado
- **Exportação** CSV / XLSX
- **Perfil editável na app** — dados pessoais, keywords de scoring, pesquisas, CVs e modelos de carta
- **Gate de acesso** — toda a API protegida por um token partilhado (ver [DEPLOY.md](DEPLOY.md))

## 🛠 Stack técnica

**Backend** — Ruby 3.3, Rails 7.1 (API mode), PostgreSQL 16, Sidekiq + Redis
**Frontend** — React 18 + TypeScript, Vite, TanStack Query, Tailwind CSS, @dnd-kit
**Infra** — Render.com (backend) + Vercel (frontend), GitHub Actions CI

## 🚀 Correr a tua própria instância

**Pré-requisitos:** Ruby 3.3, Node 22, PostgreSQL 16, Redis.

```bash
# 1. Clonar o teu fork
git clone <o-teu-fork>.git
cd job-tracker

# 2. Configurar o backend
cd backend
cp .env.example .env          # edita se o teu Postgres não for postgres/postgres
bin/setup --skip-server       # bundle install + cria/migra a base de dados + seeds

# 3. Instalar deps do frontend
cd ../frontend && npm install && cd ..

# 4. Arrancar tudo (Rails + Sidekiq + Vite) num comando
bin/dev
```

Abre **http://localhost:5173**. Localmente não há ecrã de login (o gate de acesso só liga quando `API_ACCESS_TOKEN` está definido).

A app arranca com um perfil em branco e algumas ofertas de exemplo. **Personaliza-te no separador "Perfil"** — dados pessoais, keywords do match score, pesquisas do LinkedIn, e upload de CVs / modelos de carta. Nada disto é editado em ficheiros.

## ☁️ Deploy

Ver [DEPLOY.md](DEPLOY.md) — backend no Render (blueprint `render.yaml`), frontend no Vercel. **Define `API_ACCESS_TOKEN`** antes de expor a instância, ou a API serve os teus dados a qualquer pessoa.

## 📐 Arquitetura

Ver [`docs/TECH_DESIGN.md`](docs/TECH_DESIGN.md) para detalhe.

```
┌─────────────┐         ┌──────────────┐
│   React     │ ◄─────► │  Rails API   │
│  (Vite)     │  REST   │              │
└─────────────┘         └──────┬───────┘
                               │
                       ┌───────▼────────┐      ┌──────────────┐
                       │  PostgreSQL    │      │   Sidekiq    │
                       └────────────────┘ ◄──► │  + Redis     │
                                                │  (scrapers)  │
                                                └──────────────┘
```

## 🤝 Contribuir

Projeto pessoal mas aberto a issues, sugestões e PRs.

## 📄 Licença

MIT — ver [LICENSE](LICENSE).
