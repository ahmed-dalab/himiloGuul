"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { useAuth } from "@/lib/auth-context";
import { contactsApi, type Contact } from "@/lib/api";
import { MessageSquare, Loader2, Eye, ChevronLeft, ChevronRight } from "lucide-react";

function formatDate(s?: string) {
  if (!s) return "—";
  try {
    return new Date(s).toLocaleString(undefined, {
      dateStyle: "short",
      timeStyle: "short",
    });
  } catch {
    return s;
  }
}

function statusBadge(status?: string) {
  const s = status ?? "pending";
  const styles =
    s === "closed"
      ? "bg-slate-100 text-slate-700"
      : s === "responded"
        ? "bg-blue-100 text-blue-800"
        : "bg-amber-100 text-amber-800";
  return (
    <span className={`inline-flex rounded-full px-2 py-0.5 text-xs font-medium ${styles}`}>
      {s}
    </span>
  );
}

export default function MyInquiriesPage() {
  const { user, ready } = useAuth();
  const isBuyer = user?.role === "buyer";
  const [contacts, setContacts] = useState<Contact[]>([]);
  const [pagination, setPagination] = useState({
    page: 1,
    limit: 10,
    total: 0,
    pages: 0,
  });
  const [page, setPage] = useState(1);
  const limit = 10;
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const fetchContacts = () => {
    setLoading(true);
    setError("");
    contactsApi
      .myList({ page, limit, role: "buyer" })
      .then((res) => {
        setContacts(res.data);
        setPagination(res.pagination);
      })
      .catch((e) =>
        setError(e instanceof Error ? e.message : "Failed to load inquiries")
      )
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    if (!isBuyer) return;
    fetchContacts();
  }, [isBuyer, page]);

  if (ready && !isBuyer) {
    return (
      <div className="rounded-xl border border-amber-200 bg-amber-50 px-4 py-6 text-amber-800">
        <p className="font-medium">Access denied.</p>
        <p className="mt-1 text-sm">This page is for buyers only.</p>
      </div>
    );
  }

  return (
    <div>
      <h1 className="mb-2 text-2xl font-semibold text-slate-800">My inquiries</h1>
      <p className="mb-6 text-slate-600">
        Inquiries you’ve sent to sellers about businesses. Track status and view details.
      </p>

      {error && (
        <div className="mb-6 rounded-lg bg-amber-50 px-4 py-3 text-sm text-amber-800">
          {error}
        </div>
      )}

      {loading ? (
        <div className="flex items-center gap-2 py-12 text-slate-500">
          <Loader2 className="h-6 w-6 animate-spin" aria-hidden />
          Loading…
        </div>
      ) : contacts.length === 0 ? (
        <div className="rounded-xl border border-slate-200 bg-white py-16 text-center">
          <MessageSquare className="mx-auto h-12 w-12 text-slate-300" aria-hidden />
          <p className="mt-4 text-slate-600">No inquiries yet.</p>
          <p className="mt-1 text-sm text-slate-500">
            When you contact a seller from a business listing, it will appear here.
          </p>
          <Link
            href="/"
            className="mt-4 inline-flex items-center gap-2 rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700"
          >
            Browse businesses
          </Link>
        </div>
      ) : (
        <>
          <div className="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm">
            <table className="min-w-full divide-y divide-slate-200">
              <thead className="bg-slate-50">
                <tr>
                  <th className="px-4 py-3 text-left text-xs font-medium uppercase tracking-wider text-slate-500">
                    Business / Seller
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-medium uppercase tracking-wider text-slate-500">
                    Message
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-medium uppercase tracking-wider text-slate-500">
                    Status
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-medium uppercase tracking-wider text-slate-500">
                    Date
                  </th>
                  <th className="px-4 py-3 text-right text-xs font-medium uppercase tracking-wider text-slate-500">
                    Action
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 bg-white">
                {contacts.map((c) => (
                  <tr key={c._id} className="hover:bg-slate-50/50">
                    <td className="px-4 py-3">
                      <div>
                        {c.businessRef && typeof c.businessRef === "object" && (
                          <p className="font-medium text-slate-800">{c.businessRef.name}</p>
                        )}
                        {c.sellerRef && typeof c.sellerRef === "object" && (
                          <p className="text-sm text-slate-500">{c.sellerRef.name}</p>
                        )}
                      </div>
                    </td>
                    <td className="max-w-xs px-4 py-3">
                      <p className="truncate text-sm text-slate-600" title={c.message}>
                        {c.message}
                      </p>
                      {c.reply && (
                        <div className="mt-2 rounded-lg border border-blue-200 bg-blue-50 px-2 py-2">
                          <p className="text-xs font-medium text-blue-800">Seller reply</p>
                          <p className="mt-0.5 text-sm text-slate-700 line-clamp-3" title={c.reply}>
                            {c.reply}
                          </p>
                        </div>
                      )}
                    </td>
                    <td className="px-4 py-3">{statusBadge(c.status)}</td>
                    <td className="px-4 py-3 text-sm text-slate-500">
                      {formatDate(c.createdAt)}
                    </td>
                    <td className="px-4 py-3 text-right">
                      {c.businessRef &&
                        typeof c.businessRef === "object" &&
                        c.businessRef._id && (
                          <Link
                            href={`/business/${c.businessRef._id}`}
                            className="inline-flex items-center gap-1 rounded-lg border border-slate-200 bg-white px-2 py-1.5 text-sm text-slate-600 hover:bg-slate-50"
                          >
                            <Eye className="h-4 w-4" aria-hidden />
                            View listing
                          </Link>
                        )}
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
