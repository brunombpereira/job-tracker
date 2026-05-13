export const CardSkeleton = () => (
  <div className="animate-pulse rounded-lg border border-edge bg-surface-raised p-4">
    <div className="mb-2 h-4 w-3/4 rounded bg-edge" />
    <div className="mb-3 h-3 w-1/2 rounded bg-surface-sunken" />
    <div className="mb-3 flex gap-1">
      <span className="h-4 w-12 rounded bg-surface-sunken" />
      <span className="h-4 w-12 rounded bg-surface-sunken" />
      <span className="h-4 w-12 rounded bg-surface-sunken" />
    </div>
    <div className="flex justify-between">
      <span className="h-3 w-16 rounded bg-surface-sunken" />
      <span className="h-3 w-20 rounded bg-surface-sunken" />
    </div>
  </div>
);

export const CardSkeletonGrid = ({ count = 6 }: { count?: number }) => (
  <div className="grid gap-3 md:grid-cols-2 lg:grid-cols-3">
    {Array.from({ length: count }, (_, i) => (
      <CardSkeleton key={i} />
    ))}
  </div>
);
