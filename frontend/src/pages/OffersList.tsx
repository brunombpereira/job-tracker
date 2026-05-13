import { useEffect, useMemo, useState } from "react";
import { useOffers } from "@/hooks/useOffers";
import { useDebounce } from "@/hooks/useDebounce";
import { OfferCard } from "@/components/OfferCard";
import { FiltersPanel } from "@/components/FiltersPanel";
import { Pagination } from "@/components/Pagination";
import { EmptyState } from "@/components/EmptyState";
import { CardSkeletonGrid } from "@/components/CardSkeleton";
import { Modal } from "@/components/Modal";
import { OfferForm } from "@/components/OfferForm";
import { KanbanBoard } from "@/components/KanbanBoard";
import type { Offer, OfferFilters } from "@/types/offer";

type ViewMode = "list" | "kanban";

const SORT_OPTIONS = [
  { value: "match_score:desc", label: "Match score (alto → baixo)" },
  { value: "match_score:asc", label: "Match score (baixo → alto)" },
  { value: "found_date:desc", label: "Adicionado recente" },
  { value: "found_date:asc", label: "Adicionado antigo" },
  { value: "company:asc", label: "Empresa A → Z" },
  { value: "title:asc", label: "Título A → Z" },
];

export const OffersList = () => {
  const [view, setView] = useState<ViewMode>("list");
  const [filters, setFilters] = useState<OfferFilters>({
    sort: "match_score:desc",
    per_page: 25,
    page: 1,
  });
  const [searchInput, setSearchInput] = useState("");
  const debouncedSearch = useDebounce(searchInput, 300);

  // Wire the debounced search into the filters
  useEffect(() => {
    setFilters((prev) =>
      debouncedSearch === (prev.search ?? "")
        ? prev
        : { ...prev, search: debouncedSearch || undefined, page: 1 },
    );
  }, [debouncedSearch]);

  // Kanban fetches all matching offers up to KANBAN_LIMIT — pagination doesn't
  // fit a board view since the user is meant to see all columns at once.
  const KANBAN_LIMIT = 200;
  const effectiveFilters: OfferFilters =
    view === "kanban" ? { ...filters, per_page: KANBAN_LIMIT, page: 1 } : filters;
  const { data, isLoading, isFetching, error } = useOffers(effectiveFilters);
  const kanbanTruncated = view === "kanban" && (data?.total ?? 0) > KANBAN_LIMIT;

  const [formOpen, setFormOpen] = useState(false);
  const [editing, setEditing] = useState<Offer | undefined>();

  const openCreate = () => {
    setEditing(undefined);
    setFormOpen(true);
  };
  const openEdit = (offer: Offer) => {
    setEditing(offer);
    setFormOpen(true);
  };
  const closeForm = () => setFormOpen(false);

  const offers = data?.offers ?? [];
  const total = data?.total ?? 0;
  const page = data?.page ?? 1;
  const perPage = data?.perPage ?? 25;

  const hasActiveFilters = useMemo(
    () =>
      Boolean(
        (filters.status?.length ?? 0) ||
          filters.modality ||
          filters.match_score_gte ||
          filters.match_score_lte ||
          filters.location ||
          filters.search,
      ),
    [filters],
  );

  return (
    <div className="min-h-screen bg-slate-50">
      <header className="border-b border-slate-200 bg-white">
        <div className="container mx-auto flex max-w-7xl items-center justify-between gap-3 px-4 py-4">
          <div>
            <h1 className="text-xl font-bold text-brand">JobTracker</h1>
            <p className="text-xs text-slate-500">
              Gerir candidaturas a empregos · brunombpereira/job-tracker
            </p>
          </div>
          <div className="flex items-center gap-2">
            <div className="inline-flex rounded border border-slate-300 bg-slate-50 p-0.5 text-xs font-medium">
              <button
                type="button"
                onClick={() => setView("list")}
                className={`rounded px-3 py-1 transition ${
                  view === "list" ? "bg-white text-brand shadow-sm" : "text-slate-500 hover:text-slate-800"
                }`}
              >
                Lista
              </button>
              <button
                type="button"
                onClick={() => setView("kanban")}
                className={`rounded px-3 py-1 transition ${
                  view === "kanban" ? "bg-white text-brand shadow-sm" : "text-slate-500 hover:text-slate-800"
                }`}
              >
                Kanban
              </button>
            </div>
            <button
              type="button"
              onClick={openCreate}
              className="rounded bg-brand-accent px-3 py-1.5 text-sm font-medium text-white shadow-sm transition hover:bg-brand"
            >
              + Nova oferta
            </button>
          </div>
        </div>
      </header>

      <main className="container mx-auto max-w-7xl px-4 py-6">
        <div className="mb-4 flex flex-col gap-3 md:flex-row md:items-center">
          <input
            type="search"
            placeholder="Pesquisar título, empresa ou descrição..."
            value={searchInput}
            onChange={(e) => setSearchInput(e.target.value)}
            className="flex-1 rounded border border-slate-300 bg-white px-3 py-2 text-sm focus:border-brand-accent focus:outline-none"
          />
          <select
            value={filters.sort ?? "match_score:desc"}
            onChange={(e) => setFilters((prev) => ({ ...prev, sort: e.target.value, page: 1 }))}
            className="rounded border border-slate-300 bg-white px-3 py-2 text-sm focus:border-brand-accent focus:outline-none"
          >
            {SORT_OPTIONS.map((opt) => (
              <option key={opt.value} value={opt.value}>
                {opt.label}
              </option>
            ))}
          </select>
        </div>

        <div className="grid gap-6 md:grid-cols-[16rem,1fr]">
          <FiltersPanel filters={filters} onChange={setFilters} />

          <section>
            <div className="mb-3 flex items-center justify-between text-sm text-slate-600">
              <span>
                <strong className="text-slate-900">{total}</strong>{" "}
                {total === 1 ? "oferta" : "ofertas"}
                {isFetching && !isLoading && <span className="ml-2 text-xs text-slate-400">a atualizar…</span>}
              </span>
            </div>

            {error && (
              <div className="rounded border border-rose-200 bg-rose-50 px-3 py-2 text-sm text-rose-700">
                Erro a carregar ofertas. Verifica que o backend está a correr em http://localhost:3000.
              </div>
            )}

            {isLoading && <CardSkeletonGrid />}

            {!isLoading && !error && offers.length === 0 && (
              <EmptyState
                title={hasActiveFilters ? "Nenhuma oferta com estes filtros" : "Ainda não há ofertas"}
                body={
                  hasActiveFilters
                    ? "Ajusta os filtros à esquerda ou limpa para ver tudo."
                    : "Adiciona a primeira candidatura ao tracker."
                }
                actionLabel={hasActiveFilters ? undefined : "Criar primeira oferta"}
                onAction={hasActiveFilters ? undefined : openCreate}
              />
            )}

            {!isLoading && offers.length > 0 && view === "list" && (
              <>
                <div className="grid gap-3 md:grid-cols-2 xl:grid-cols-3">
                  {offers.map((offer) => (
                    <OfferCard key={offer.id} offer={offer} onEdit={openEdit} />
                  ))}
                </div>
                <Pagination
                  page={page}
                  perPage={perPage}
                  total={total}
                  onPageChange={(p) => setFilters((prev) => ({ ...prev, page: p }))}
                />
              </>
            )}

            {!isLoading && offers.length > 0 && view === "kanban" && (
              <>
                {kanbanTruncated && (
                  <div className="mb-3 rounded border border-amber-200 bg-amber-50 px-3 py-2 text-xs text-amber-800">
                    A mostrar apenas {KANBAN_LIMIT} de {total} ofertas — usa filtros ou a vista
                    Lista para veres o resto.
                  </div>
                )}
                <KanbanBoard offers={offers} onCardClick={openEdit} />
              </>
            )}
          </section>
        </div>
      </main>

      <Modal
        open={formOpen}
        onClose={closeForm}
        title={editing ? "Editar oferta" : "Nova oferta"}
        maxWidth="max-w-2xl"
      >
        <OfferForm offer={editing} onSaved={closeForm} onCancel={closeForm} />
      </Modal>
    </div>
  );
};
