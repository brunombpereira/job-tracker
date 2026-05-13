# Roadmap — JobTracker

> Milestones realistas para construir entre as candidaturas. Cada milestone deve ser shippable (PR mergeable, deploy possível).

---

## 🎯 M0 — Foundations (1 weekend)

**Objetivo:** repositório pronto, modelo de dados, primeira API funcional.

- [ ] Criar repo `brunombpereira/job-tracker` (público)
- [ ] Estrutura monorepo: `backend/` + `frontend/`
- [ ] `rails new backend --api -d postgresql -T` (-T = sem Minitest, usaremos RSpec)
- [ ] Adicionar gems: rspec-rails, factory_bot_rails, faker, rubocop-rails-omakase
- [ ] Setup CI: GitHub Actions a correr `rspec` e `npm test` em PRs
- [ ] Modelo `Offer` + migration (campos do TECH_DESIGN)
- [ ] Modelo `Source`, `Note`, `StatusChange`
- [ ] Seeds com 5-10 ofertas dummy
- [ ] `GET /api/v1/offers` retorna lista paginada
- [ ] `POST /api/v1/offers` cria nova
- [ ] Tests RSpec: model validations + 2 endpoints
- [ ] Frontend: `npm create vite@latest frontend -- --template react-ts`
- [ ] Tailwind + axios + react-query setup
- [ ] Página simples que lê `/offers` e mostra tabela

**Definition of done:** `git push` + posso correr `rails s` e `npm run dev` e ver lista de ofertas.

**Commits suggeridos:**
- `feat: bootstrap rails api + react frontend`
- `feat(offers): add Offer model with full data model`
- `feat(api): add GET/POST /api/v1/offers`
- `feat(ui): list offers in basic table`
- `ci: add github actions for rspec + npm test`

---

## 🎯 M1 — MVP UI (1 weekend)

**Objetivo:** UI utilizável para CRUD de ofertas com filtros.

- [ ] Form criar/editar oferta (modal ou rota dedicada)
- [ ] Componente `OfferCard` para vista de lista
- [ ] Filtros: status (multi), match_score (range), modalidade, localização
- [ ] Pesquisa por título/empresa (debounce 300ms)
- [ ] Ordenação (match_score, found_date)
- [ ] Paginação (25 por página)
- [ ] Estado de loading + empty state
- [ ] Estados visuais para cada status (cores)
- [ ] Tests RSpec para filtros server-side

**Definition of done:** consigo gerir as minhas ofertas reais nesta UI em vez de no JSON.

---

## 🎯 M2 — Kanban (1 weekend)

**Objetivo:** vista Kanban com drag-and-drop entre estados.

- [ ] Adicionar `@dnd-kit/core` + `@dnd-kit/sortable`
- [ ] Componente `KanbanBoard` com 6 colunas (estados)
- [ ] Drag-and-drop entre colunas → chama `PATCH /offers/:id/status`
- [ ] Animação fluida + optimistic UI
- [ ] State machine no backend para validar transições
- [ ] Modal de confirmação para movimentos sensíveis (ex: → rejected)
- [ ] Vista alterna entre Lista / Kanban via toggle

**Definition of done:** posso arrastar uma oferta de "Interested" para "Applied" e fica gravado.

---

## 🎯 M3 — Import / Export (1 day)

**Objetivo:** compatibilidade com a tarefa agendada do Cowork.

- [ ] `POST /api/v1/offers/import` aceita JSON com array de offers (formato igual ao do `job_offers.json`)
- [ ] Dedup por hash(company+title)
- [ ] Endpoint `/export.csv` e `/export.xlsx` (usar `caxlsx` gem)
- [ ] Botões "Import / Export" na UI
- [ ] Drag-and-drop de ficheiro para importar

**Definition of done:** posso importar o `job_offers.json` gerado todas as manhãs pela tarefa agendada.

---

## 🎯 M4 — Deploy (1 day)

**Objetivo:** app pública na internet.

- [ ] Criar conta Render (free tier)
- [ ] Connect GitHub repo, deploy automático no push para `main`
- [ ] Configurar Postgres no Render
- [ ] Configurar variáveis de ambiente (DATABASE_URL, RAILS_MASTER_KEY)
- [ ] Domain: `jobtracker.brunombpereira.dev` (opcional, custa ~10€/ano)
- [ ] Deploy frontend separadamente (Vercel ou mesmo Render static site)
- [ ] CORS configurado entre backend e frontend
- [ ] README com botão "Deploy to Render"
- [ ] Mencionar URL pública no LinkedIn / CV

**Definition of done:** alguém pode abrir o URL e usar a app (mesmo sem login ainda).

---

## 🎯 M5 — V2 features (2-3 weekends)

Por ordem de prioridade:

### M5.1 — Auth (1 weekend)
- Devise
- Email confirmation
- Multi-user (cada utilizador vê só as suas ofertas)
- Migration: adicionar `user_id` a Offer

### M5.2 — Background scrapers (1 weekend)
- Sidekiq + Redis
- Job `IndeedScraperJob` (usa Indeed API oficial se Bruno tiver chave)
- Job `LinkedInScraperJob` (scraping público com cuidado)
- Schedule: corre diariamente via `sidekiq-cron`
- Cria offers com `source` apropriada

### M5.3 — Email notifications (1 day)
- ActionMailer + SendGrid (free tier)
- Email diário com resumo (top 5 novas ofertas)
- Lembrete semanal de ofertas "interested" sem candidatura

### M5.4 — Analytics dashboard (1 day)
- Conversão por canal (quantas candidaturas viraram entrevistas, por fonte)
- Funnel: new → interested → applied → interview → offer
- Tempo médio em cada estado
- Vencedor: rejection rate por empresa

---

## 🔮 Pós-V2 (ideias)

- Versões de CV/cartas anexadas por candidatura
- Notas de preparação para entrevista por empresa (incluir info do Glassdoor)
- Reminders / calendário integrado
- Multi-language (PT/EN)
- API pública para criar offer via webhook (ex: do Cowork)
- Browser extension: "Save this job offer" em qualquer página
- Sincronização bidirecional com Notion / Linear

---

## 📋 Como medir progresso

Considera cada milestone concluído quando:
1. Tem testes (RSpec ou React Testing Library)
2. Tem documentação (README atualizado, screenshot na PR)
3. Está merged para `main`
4. Foi deployed (a partir do M4)

Pin do `job-tracker` no perfil GitHub depois de M0 — começa a ganhar tração.
