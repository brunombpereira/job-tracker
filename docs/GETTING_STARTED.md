# Getting Started — JobTracker

> Como passar do plano à primeira commit.

---

## 1. Setup local (~ 30 min)

### Pré-requisitos
- Ruby 3.3+ (`rbenv install 3.3.0`)
- Node 20+ (`nvm install 20`)
- PostgreSQL 16 (`brew install postgresql@16` ou Docker)
- Git
- IDE: VS Code (que já usas)

### Passos

```bash
# 1. Criar o repo no GitHub
# Vai a https://github.com/new
# Nome: job-tracker
# Público
# Add README, .gitignore Ruby, MIT License

# 2. Clonar e copiar a documentação
git clone https://github.com/brunombpereira/job-tracker.git
cd job-tracker

# Copia para o repo a documentação que está em
# `Job Hunt/JobTracker_App/`:
#   - README.md (substitui o gerado)
#   - docs/TECH_DESIGN.md
#   - docs/ROADMAP.md
#   - docs/GETTING_STARTED.md (este ficheiro)

cp "/path/to/Job Hunt/JobTracker_App/README.md" .
mkdir -p docs
cp "/path/to/Job Hunt/JobTracker_App/docs/"*.md docs/

git add .
git commit -m "docs: add project plan and tech design"
git push

# 3. Criar a primeira issue
# No GitHub: "Issues" tab → "New issue"
# Title: "M0: Bootstrap Rails API + React frontend"
# Cola checklist do ROADMAP.md M0
# Assign yourself
```

A partir daqui, segue o ROADMAP.

---

## 2. Primeiro commit técnico

```bash
# Criar branch para M0
git checkout -b m0-foundations

# Criar Rails API
rails new backend --api -d postgresql -T
cd backend

# Adicionar gems essenciais
echo "
group :development, :test do
  gem 'rspec-rails'
  gem 'factory_bot_rails'
  gem 'faker'
end

group :development do
  gem 'rubocop-rails-omakase', require: false
end
" >> Gemfile

bundle install
rails generate rspec:install

# Voltar à raiz e criar frontend
cd ..
npm create vite@latest frontend -- --template react-ts
cd frontend
npm install
npm install axios @tanstack/react-query tailwindcss

# Setup tailwind
npx tailwindcss init -p

git add .
git commit -m "feat: bootstrap rails api + react+vite frontend"
git push -u origin m0-foundations
```

Abre PR para `main`. Approve e merge tu mesmo. Pronto.

---

## 3. Workflow ao longo do tempo

1. **Issue por milestone** (não issue por commit) — cola checklist do ROADMAP
2. **Branch por milestone** (ex: `m1-mvp-ui`, `m2-kanban`)
3. **Commits semânticos**:
   - `feat:` nova funcionalidade
   - `fix:` correção
   - `refactor:` mudança sem alterar comportamento
   - `docs:` só documentação
   - `test:` adicionar/melhorar testes
   - `chore:` build, deps, config
4. **Pull Request com screenshot ou GIF** quando há UI
5. **Merge para `main`** só com CI verde

---

## 4. Dicas de execução

- **Não tentes ser perfecionista em M0** — bota a coisa de pé, deploy em M4. Refinas depois.
- **Trabalha 1-2h de manhã antes do trabalho** ou ao fim de semana. Não procures slots longos.
- **Mostra o trabalho** — depois de M0 mergeado, mete o link do repo no LinkedIn (post curto: "Iniciei um projeto pessoal para gerir candidaturas. Stack: Rails + React. Repo aqui: ..."). É visibilidade barata.
- **Documenta decisões** — sempre que tomas decisão arquitetural, atualiza TECH_DESIGN.md. Recrutadores adoram ver evidência de design thinking.
- **Pede review** — quando tiveres M1 ou M2 mergeado, partilha o repo num grupo de devs (Reddit r/rails, Discord da UA) e pede feedback. Aprendes muito.

---

## 5. Talking points para entrevistas

Quando estiveres a contar este projeto numa entrevista, foca em:

**Why:**
> "Tinha um problema real — estava a gerir 30+ candidaturas a empregos numa folha de Excel que rapidamente se tornou caótica. Em vez de viver com a frustração, construí a ferramenta que precisava."

**Como mostrar value:**
> "Decidi usar a stack do meu emprego atual (Rails + React + PostgreSQL) — não foi para aprender tech nova, foi para aprofundar essa stack e poder mostrar código real para além de exercícios académicos."

**Design choices:**
> "Optei por Rails API + React separados em vez de Rails full-stack porque queria flexibilidade futura — eventualmente vou querer deploy do frontend em CDN, e o backend pode escalar separadamente. Para um projeto desta escala podia ser overkill, mas quis simular as decisões que tomaria num projeto profissional."

**Honest limitations:**
> "A V1 não tem auth ainda — é single-user. Para deploy público vou precisar de adicionar Devise. Mas decidi shipar a V1 sem auth para validar a UX primeiro."

---

## 6. Pin no GitHub depois de M0

Quando tiveres M0 merged, vai ao perfil GitHub e pin o `job-tracker` — substitui o pin atual do `coworking-db` ou junta os dois. Repo ativo > repo académico parado.
