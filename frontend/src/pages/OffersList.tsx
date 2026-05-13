import { useEffect, useMemo, useState } from "react";
import { useOffers } from "@/hooks/useOffers";
import { useDebounce } from "@/hooks/useDebounce";
import { useUrlFilters } from "@/hooks/useUrlFilters";
import { OfferCard } from "@/components/OfferCard";
import { FiltersPanel } from "@/components/FiltersPanel";
import { Pagination } from "@/components/Pagination";
import { EmptyState } from "@/components/EmptyState";
import { CardSkeletonGrid } from "@/components/CardSkeleton";
import { Modal } from "@/components/Modal";
import { OfferForm } from "@/components/OfferForm";
import { KanbanBoard } from "@/components/KanbanBoard";
import { OfferDetail } from "@/components/OfferDetail";
import type { Offer, OfferFilters } from "@/types/offer";

const SORT_OPTIONS = [
  { value: "match_score:desc", label: "Match score (alto → baixo)" },
  { value: "match_score:asc", label: "Match score (baixo → alto)" },
  { value: "found_date:desc", label: "Adicionado recente" },
  { value: "found_date:asc", label: "Adicionado antigo" },
  { value: "company:asc", label: "Empresa A → Z" },
  { value: "title:asc", label: "Título A → Z" },
];

const KANBAN_LIMIT = 200;

const countActiveFilters = (f: OfferFilters) =>
  (f.status?.length ?? 0) +
  (f.modality ? 1 : 0) +
  (f.match_score_gte ? 1 : 0) +
  (f.match_score_lte ? 1 : 0) +
  (f.location ? 1 : 0) +
  (f.include_archived ? 1 : 0);

export const OffersList = () => {
  const { filters, setFilters, view, setView, searchInput, setSearchInput } =
    useUrlFilters();

  const debouncedSearch = useDebounce(searchInput, 300);

  // Wire debounced search into filters (one direction: input → filters)
  useEffect(() => {
    if (debouncedSearch === (filters.search ?? "")) return;
    setFilters({
      ...filters,
      search: debouncedSearch || undefined,
      page: 1,
    });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [debouncedSearch]);

  const effectiveFilters: OfferFilters =
    view === "kanban" ? { ...filters, per_page: KANBAN_LIMIT, page: 1 } : filters;
  const { data, isLoading, isFetching, error } = useOffers(effectiveFilters);
  const kanbanTruncated = view === "kanban" && (data?.total ?? 0) > KANBAN_LIMIT;

  const [formOpen, setFormOpen] = useState(false);
  const [editing, setEditing] = useState<Offer | undefined>();
  const [detailOf, setDetailOf] = useState<Offer | undefined>();
  const [mobileFiltersOpen, setMobileFiltersOpen] = useState(false);

  const openCreate = () => {
    setEditing(undefined);
    setFormOpen(true);
  };
  const openEdit = (offer: Offer) => {
    setEditing(offer);
    setFormOpen(true);
    setDetailOf(undefined);
  };
  const openDetail = (offer: Offer) => setDetailOf(offer);
  const closeForm = () => setFormOpen(false);
  const closeDetail = () => setDetailOf(undefined);

  const offers = data?.offers ?? [];
  const total = data?.total ?? 0;
  const page = data?.page ?? 1;
  const perPage = data?.perPage ?? 25;

  const activeFilterCount = useMemo(() => countActiveFilters(filters), [filters]);
  const hasActiveFilters = activeFilterCount > 0 || Boolean(filters.search);

  return (
    <div className="min-h-screen bg-slate-50">
      <header className="border-b border-slate-200 bg-white">
        <div className="container mx-auto flex max-w-7xl flex-wrap items-center justify-between gap-3 px-4 py-4">
          <div>
            <h1 className="text-xl font-bold text-brand">JobTracker</h1>
            <p className="hidden text-xs text-slate-500 sm:block">
              Gerir candidaturas a empregos · brunombpereira/job-tracker
            </p>
          </div>
          <div className="flex items-center gap-2">
            <div className="inline-flex rounded border border-slate-300 bg-slate-50 p-0.5 text-xs font-medium">
              <button
                type="button"
                onClick={() => setView("list")}
                className={`rounded px-3 py-1 transition ${
                  view === "list"
                    ? "bg-white text-brand shadow-sm"
                    : "text-slate-500 hover:text-slate-800"
                }`}
              >
                Lista
              </button>
              <button
                type="button"
                onClick={() => setView("kanban")}
                className={`rounded px-3 py-1 transition ${
                  view === "kanban"
                    ? "bg-white text-brand shadow-sm"
                    : "text-slate-500 hover:text-slate-800"
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
        <div className="mb-4 flex flex-col gap-2 sm:flex-row sm:items-center">
          <input
            type="search"
            placeholder="Pesquisar título, empresa ou descrição..."
            value={searchInput}
            onChange={(e) => setSearchInput(e.target.value)}
            className="flex-1 rounded border border-slate-300 bg-white px-3 py-2 text-sm focus:border-brand-accent focus:outline-none"
          />
          <div className="flex gap-2">
            {/* Mobile filters toggle */}
            <button
              type="button"
              onClick={() => setMobileFiltersOpen(true)}
              className="md:hidden rounded border border-slate-300 bg-white px-3 py-2 text-sm font-medium text-slate-700 transition hover:bg-slate-50"
            >
              Filtros{activeFilterCount > 0 && ` · ${activeFilterCount}`}
            </button>
            <select
              value={filters.sort ?? "match_score:desc"}
              onChange={(e) => setFilters({ ...filters, sort: e.target.value, page: 1 })}
              className="rounded border border-slate-300 bg-white px-3 py-2 text-sm focus:border-brand-accent focus:outline-none"
            >
              {SORT_OPTIONS.map((opt) => (
                <option key={opt.value} value={opt.value}>
                  {opt.label}
                </option>
              ))}
            </select>
          </div>
        </div>

        <div className="grid gap-6 md:grid-cols-[16rem,1fr]">
          {/* FiltersPanel — visible only on md+ as a sidebar */}
          <div className="hidden md:block">
            <FiltersPanel filters={filters} onChange={setFilters} />
          </div>

          <section>
            <div className="mb-3 flex items-center justify-between text-sm text-slate-600">
              <span>
                <strong className="text-slate-900">{total}</strong>{" "}
                {total === 1 ? "oferta" : "ofertas"}
                {isFetching && !isLoading && (
                  <span className="ml-2 text-xs text-slate-400">a atualizar…</span>
                )}
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
                title={
                  hasActiveFilters ? "Nenhuma oferta com estes filtros" : "Ainda não há ofertas"
                }
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
                    <OfferCard
                      key={offer.id}
                      offer={offer}
                      onEdit={openEdit}
                      onOpen={openDetail}
                    />
                  ))}
                </div>
                <Pagination
                  page={page}
                  perPage={perPage}
                  total={total}
                  onPageChange={(p) => setFilters({ ...filters, page: p })}
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
                <KanbanBoard offers={offers} onCardClick={openDetail} />
              </>
            )}
          </section>
        </div>
      </main>

      {/* Mobile filters drawer */}
      {mobileFiltersOpen && (
        <div
          className="fixed inset-0 z-40 md:hidden"
          role="dialog"
          aria-modal="true"
          aria-label="Filtros"
        >
          <div
            className="absolute inset-0 bg-slate-900/50"
            onClick={() => setMobileFiltersOpen(false)}
            role="presentation"
          />
          <div className="absolute inset-y-0 right-0 w-[85%] max-w-sm overflow-y-auto bg-slate-50 p-4 shadow-xl">
            <div className="mb-3 flex items-center justify-between">
              <h2 className="text-base font-semibold text-slate-900">Filtros</h2>
              <button
                type="button"
                onClick={() => setMobileFiltersOpen(false)}
                aria-label="Fechar filtros"
                className="rounded p-1 text-slate-500 transition hover:bg-slate-200 hover:text-slate-700"
              >
                <svg width="20" height="20" viewBox="0 0 20 20" fill="currentColor">
                  <path d="M6.28 5.22a.75.75 0 00-1.06 1.06L8.94 10l-3.72 3.72a.75.75 0 101.06 1.06L10 11.06l3.72 3.72a.75.75 0 101.06-1.06L11.06 10l3.72-3.72a.75.75 0 00-1.06-1.06L10 8.94 6.28 5.22z" />
                </svg>
              </button>
            </div>
            <FiltersPanel filters={filters} onChange={setFilters} />
            <button
              type="button"
              onClick={() => setMobileFiltersOpen(false)}
              className="mt-4 w-full rounded bg-brand-accent px-3 py-2 text-sm font-medium text-white"
            >
              Ver {total} ofertas
            </button>
          </div>
        </div>
      )}

      <Modal
        open={formOpen}
        onClose={closeForm}
        title={editing ? "Editar oferta" : "Nova oferta"}
        maxWidth="max-w-2xl"
      >
        <OfferForm offer={editing} onSaved={closeForm} onCancel={closeForm} />
      </Modal>

      <Modal
        open={Boolean(detailOf)}
        onClose={closeDetail}
        title={detailOf ? `${detailOf.company} · ${detailOf.title}` : ""}
        maxWidth="max-w-2xl"
      >
        {detailOf && (
          <OfferDetail
            offer={detailOf}
            onEdit={() => {
              const o = detailOf;
              closeDetail();
              openEdit(o);
            }}
          />
        )}
      </Modal>
    </div>
  );
};
