"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { useAuth } from "@/lib/auth-context";
import { adminApi, type Business } from "@/lib/api";
import { Store, MapPin, Check, X, Eye, Loader2, ChevronLeft, ChevronRight } from "lucide-react";

function formatPrice(n?: number) {
  if (n == null) return "—";
  return new Intl.NumberFormat("en-US", { style: "currency", currency: "USD", maximumFractionDigits: 0 }).format(n);
}

function formatCategory(c?: string) {
  if (!c) return "—";
  return c.replace(/-/g, " ").replace(/\b\w/g, (ch) => ch.toUpperCase());
}

type Tab = "all" | "pending";

export default function AdminBusinessesPage() {
  const { user, ready } = useAuth();
  const isAdmin = user?.role === "admin";
  const [tab, setTab] = useState<Tab>("all");
  const [page, setPage] = useState(1);
  const limit = 10;
  const [businesses, setBusinesses] = useState<Business[]>([]);
  const [pagination, setPagination] = useState({ page: 1, limit: 10, total: 0, pages: 0 });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [actionId, setActionId] = useState<string | null>(null);

  const fetchAll = () => {
    setLoading(true);
    setError("");
    const promise =
      tab === "pending"
        ? adminApi.listPendingBusinesses({ page, limit })
        : adminApi.listBusinesses({ page, limit });
    promise
      .then((res) => {
        setBusinesses(res.data);
        setPagination(res.pagination);
      })
      .catch((e) => setError(e instanceof Error ? e.message : "Failed to load businesses"))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    setPage(1);
  }, [tab]);

  useEffect(() => {
    fetchAll();
  }, [tab, page]);

  const handleApprove = (id: string) => {
    setActionId(id);
    adminApi
      .approveBusiness(id)
      .then(() => fetchAll())
      .catch((e) => setError(e instanceof Error ? e.message : "Approve failed"))
      .finally(() => setActionId(null));
  };

  const handleReject = (id: string) => {
    setActionId(id);
    adminApi
      .rejectBusiness(id)
      .then(() => fetchAll())
      .catch((e) => setError(e instanceof Error ? e.message : "Reject failed"))
      .finally(() => setActionId(null));
  };

  if (ready && !isAdmin) {
    return (
      <div className="rounded-xl border border-amber-200 bg-amber-50 px-4 py-6 text-amber-800">
        <p className="font-medium">Access denied.</p>
        <p className="mt-1 text-sm">This page is for administrators only.</p>
      </div>
    );
  }

  return (
    <div>
      <h1 className="mb-2 text-2xl font-semibold text-slate-800">Businesses</h1>
      <p className="mb-6 text-slate-600">
        View all listings and approve or reject pending submissions.
      </p>

      {error && (
        <div className="mb-6 rounded-lg bg-amber-50 px-4 py-3 text-sm text-amber-800">
          {error}
        </div>
      )}

      <div className="mb-4 flex gap-2">
        <button
          type="button"
          onClick={() => setTab("all")}
          className={`rounded-lg px-4 py-2 text-sm font-medium ${
            tab === "all" ? "bg-blue-600 text-white" : "bg-slate-100 text-slate-600 hover:bg-slate-200"
          }`}
        >
          All
        </button>
        <button
          type="button"
          onClick={() => setTab("pending")}
          className={`rounded-lg px-4 py-2 text-sm font-medium ${
            tab === "pending" ? "bg-blue-600 text-white" : "bg-slate-100 text-slate-600 hover:bg-slate-200"
          }`}
        >
          Pending
        </button>
      </div>

      {loading ? (
        <div className="flex items-center gap-2 py-12 text-slate-500">
          <Loader2 className="h-6 w-6 animate-spin" aria-hidden />
          Loading…
        </div>
      ) : businesses.length === 0 ? (
        <div className="rounded-xl border border-slate-200 bg-white py-16 text-center">
          <Store className="mx-auto h-12 w-12 text-slate-300" aria-hidden />
          <p className="mt-4 text-slate-600">No businesses found.</p>
        </div>
      ) : (
        <>
          <div className="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm">
            <table className="min-w-full divide-y divide-slate-200">
              <thead className="bg-slate-50">
                <tr>
                  <th className="px-4 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">
                    Listing
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">
                    Owner
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">
                    Status
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">
                    Price
                  </th>
                  <th className="px-4 py-3 text-right text-xs font-medium text-slate-500 uppercase tracking-wider">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 bg-white">
                {businesses.map((b) => (
                  <tr key={b._id} className="hover:bg-slate-50/50">
                    <td className="px-4 py-3">
                      <div>
                        <p className="font-medium text-slate-800">{b.name}</p>
                        {b.category && (
                          <p className="text-sm text-slate-500">{formatCategory(b.category)}</p>
                        )}
                        {b.location && (
                          <p className="flex items-center gap-1 text-sm text-slate-500">
                            <MapPin className="h-3.5 w-3.5 shrink-0" aria-hidden />
                            {b.location}
                          </p>
                        )}
                      </div>
                    </td>
                    <td className="px-4 py-3 text-sm text-slate-600">
                      {typeof b.owner === "object" && b.owner
                        ? b.owner.name
                        : "—"}
                      {typeof b.owner === "object" && b.owner?.email && (
                        <span className="block text-slate-500">{b.owner.email}</span>
                      )}
                    </td>
                    <td className="px-4 py-3">
                      <span
                        className={`inline-flex rounded-full px-2 py-0.5 text-xs font-medium ${
                          b.status === "approved"
                            ? "bg-emerald-100 text-emerald-800"
                            : b.status === "rejected"
                              ? "bg-red-100 text-red-800"
                              : "bg-amber-100 text-amber-800"
                        }`}
                      >
                        {b.status ?? "pending"}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-sm text-slate-700">
                      {formatPrice(b.askingPrice)}
                    </td>
                    <td className="px-4 py-3 text-right">
                      <div className="flex items-center justify-end gap-2">
                        <Link
                          href={`/business/${b._id}`}
                          className="inline-flex items-center gap-1 rounded-lg border border-slate-200 bg-white px-2 py-1.5 text-sm text-slate-600 hover:bg-slate-50"
                        >
                          <Eye className="h-4 w-4" aria-hidden />
                          View
                        </Link>
                        {b.status === "pending" && (
                          <>
                            <button
                              type="button"
                              onClick={() => handleApprove(b._id)}
                              disabled={actionId === b._id}
                              className="inline-flex items-center gap-1 rounded-lg bg-emerald-600 px-2 py-1.5 text-sm text-white hover:bg-emerald-700 disabled:opacity-50"
                            >
                              {actionId === b._id ? (
                                <Loader2 className="h-4 w-4 animate-spin" aria-hidden />
                              ) : (
                                <Check className="h-4 w-4" aria-hidden />
                              )}
                              Approve
                            </button>
                            <button
                              type="button"
                              onClick={() => handleReject(b._id)}
                              disabled={actionId === b._id}
                              className="inline-flex items-center gap-1 rounded-lg bg-red-600 px-2 py-1.5 text-sm text-white hover:bg-red-700 disabled:opacity-50"
                            >
                              {actionId === b._id ? (
                                <Loader2 className="h-4 w-4 animate-spin" aria-hidden />
                              ) : (
                                <X className="h-4 w-4" aria-hidden />
                              )}
                              Reject
                            </button>
                          </>
                        )}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {pagination.pages > 1 && (
            <div className="mt-4 flex items-center justify-between">
              <p className="text-sm text-slate-500">
                Page {page} of {pagination.pages} ({pagination.total} total)
              </p>
              <div className="flex gap-2">
                <button
                  type="button"
                  onClick={() => setPage((p) => Math.max(1, p - 1))}
                  disabled={page <= 1}
                  className="inline-flex items-center rounded-lg border border-slate-200 bg-white px-3 py-1.5 text-sm text-slate-600 hover:bg-slate-50 disabled:opacity-50"
                >
                  <ChevronLeft className="h-4 w-4" aria-hidden />
                  Previous
                </button>
                <button
                  type="button"
                  onClick={() => setPage((p) => Math.min(pagination.pages, p + 1))}
                  disabled={page >= pagination.pages}
                  className="inline-flex items-center rounded-lg border border-slate-200 bg-white px-3 py-1.5 text-sm text-slate-600 hover:bg-slate-50 disabled:opacity-50"
                >
                  Next
                  <ChevronRight className="h-4 w-4" aria-hidden />
                </button>
              </div>
            </div>
          )}
        </>
      )}
    </div>
  );
}
